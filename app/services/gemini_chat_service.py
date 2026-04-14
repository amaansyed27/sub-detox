from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
import json
import re
from typing import Any


class GeminiChatError(RuntimeError):
    """Raised when the Gemini chat request cannot be completed."""


class GeminiChatService:
    def __init__(
        self,
        api_key: str,
        model: str,
        timeout_seconds: float,
        grounding_enabled: bool,
    ) -> None:
        if not api_key.strip():
            raise ValueError("Gemini API key is required.")
        self._api_key = api_key.strip()
        self._model = model.strip()
        self._timeout_seconds = timeout_seconds
        self._grounding_enabled = grounding_enabled

    def ask(
        self,
        *,
        prompt: str,
    ) -> dict[str, Any]:
        response = self._call_gemini(prompt)
        response_text = getattr(response, "text", "")
        if not isinstance(response_text, str) or not response_text.strip():
            raise GeminiChatError("Gemini returned an empty response.")

        parsed = self._parse_json_payload(response_text)
        grounded, sources = self._extract_grounding_metadata(response)
        parsed["grounded"] = grounded
        parsed["sources"] = sources
        return parsed

    def _call_gemini(self, prompt: str) -> Any:
        try:
            from google import genai
        except ImportError as exc:
            raise GeminiChatError(
                "google-genai SDK not installed. Install dependency or disable Gemini chat."
            ) from exc

        client = genai.Client(api_key=self._api_key)

        base_config: dict[str, Any] = {
            "temperature": 0.35,
            "max_output_tokens": 900,
        }

        with ThreadPoolExecutor(max_workers=1) as executor:
            if self._grounding_enabled:
                grounding_config = {
                    **base_config,
                    "tools": [{"google_search": {}}],
                }
                grounded_future = executor.submit(
                    client.models.generate_content,
                    model=self._model,
                    contents=prompt,
                    config=grounding_config,
                )
                try:
                    return grounded_future.result(timeout=self._timeout_seconds)
                except FutureTimeoutError as exc:
                    raise GeminiChatError("Gemini chat request timed out.") from exc
                except Exception:
                    fallback_future = executor.submit(
                        client.models.generate_content,
                        model=self._model,
                        contents=prompt,
                        config=base_config,
                    )
                    try:
                        return fallback_future.result(timeout=self._timeout_seconds)
                    except FutureTimeoutError as exc:
                        raise GeminiChatError("Gemini chat request timed out.") from exc
                    except Exception as exc:  # noqa: BLE001
                        raise GeminiChatError(f"Gemini chat request failed: {exc}") from exc

            plain_future = executor.submit(
                client.models.generate_content,
                model=self._model,
                contents=prompt,
                config=base_config,
            )
            try:
                return plain_future.result(timeout=self._timeout_seconds)
            except FutureTimeoutError as exc:
                raise GeminiChatError("Gemini chat request timed out.") from exc
            except Exception as exc:  # noqa: BLE001
                raise GeminiChatError(f"Gemini chat request failed: {exc}") from exc

    @staticmethod
    def _parse_json_payload(response_text: str) -> dict[str, Any]:
        cleaned = response_text.strip()
        fenced_match = re.search(r"```(?:json)?\s*(\{[\s\S]*\})\s*```", cleaned)
        if fenced_match:
            cleaned = fenced_match.group(1).strip()

        try:
            payload = json.loads(cleaned)
        except json.JSONDecodeError:
            return {
                "reply": cleaned,
                "suggestedActions": [
                    "CREATE_SUPPORT_TICKET",
                    "RAISE_BANK_REQUEST",
                ],
            }

        reply = payload.get("reply")
        if not isinstance(reply, str) or not reply.strip():
            reply = "I could not generate a detailed response. Please try rephrasing your question."

        suggested_actions = payload.get("suggestedActions", [])
        if not isinstance(suggested_actions, list):
            suggested_actions = []

        normalized_actions = [
            action
            for action in suggested_actions
            if isinstance(action, str) and action.strip()
        ]

        return {
            "reply": " ".join(reply.split()),
            "suggestedActions": normalized_actions,
        }

    @staticmethod
    def _extract_grounding_metadata(response: Any) -> tuple[bool, list[dict[str, str]]]:
        sources: list[dict[str, str]] = []

        try:
            candidates = getattr(response, "candidates", None) or []
            if not candidates:
                return False, sources

            grounding_metadata = getattr(candidates[0], "grounding_metadata", None)
            if grounding_metadata is None:
                return False, sources

            chunks = getattr(grounding_metadata, "grounding_chunks", None) or []
            for chunk in chunks:
                web = getattr(chunk, "web", None)
                if web is None:
                    continue
                title = getattr(web, "title", None)
                uri = getattr(web, "uri", None)
                if not isinstance(uri, str) or not uri.strip():
                    continue
                sources.append(
                    {
                        "title": title.strip() if isinstance(title, str) and title.strip() else "Source",
                        "url": uri.strip(),
                    }
                )

            deduped: list[dict[str, str]] = []
            seen: set[str] = set()
            for item in sources:
                key = item["url"].lower()
                if key in seen:
                    continue
                seen.add(key)
                deduped.append(item)

            return len(deduped) > 0, deduped[:6]
        except Exception:  # noqa: BLE001
            return False, []

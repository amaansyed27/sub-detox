# SubDetox Web Landing

Vite + React landing site for SubDetox — deployed at **[subdetox.vercel.app](https://subdetox.vercel.app/)**.

## Features

- Animated, cursor-interactive hero SVG with parallax layers
- Problem statement & scale statistics (RBI UPI data)
- Solution overview with Expose → Decide → Revoke flow
- Rules-First / AI-Enhanced / Action-Driven pillars
- Step-by-step "How It Works" (5 stages)
- Impact metrics (₹3K, 5s, ₹150Cr) and target audience
- Tech stack pyramid visualization
- Team Redline member cards
- Demo walkthrough YouTube embed
- APK download (hosted on GitHub) + PDF pitch deck download

## Local Development

```bash
cd web-landing
npm install
npm run dev
```

## Build

```bash
npm run build
```

## Important Link Configuration

All dynamic links are centralized in `src/content.js`:

| Key | Purpose |
|---|---|
| `LINKS.apkDownload` | Android APK (GitHub raw URL — works on Vercel) |
| `LINKS.pptDownload` | Pitch deck PDF (served from `/public/downloads/`) |
| `LINKS.githubRepo` | Repository URL |
| `LINKS.architectureDoc` | Rules engine design doc |
| `LINKS.youtubeEmbed` | Demo walkthrough video |

## Static Assets

All public assets served by Vite/Vercel from `public/`:

- `public/assets/` — SubDetox logo, Redline logo, favicons
- `public/downloads/` — Pitch deck PDF, legacy deck PPTX

> **Note on APK downloads:** The APK is hosted on GitHub (`android-apk/subdetox-android.apk`) via raw.githubusercontent.com, so it downloads correctly from any deployment environment including Vercel.

## Deployment (Vercel)

1. Import the `web-landing` directory as a Vercel project
2. Framework preset: **Vite**
3. Root directory: `web-landing`
4. Build command: `npm run build`
5. Output directory: `dist`
6. Deploy — all static assets in `public/` (including the PDF deck) are automatically served

See [VERCEL-DEPLOY.md](VERCEL-DEPLOY.md) for the full step-by-step guide.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_assist_models.dart';
import '../providers/auth_provider.dart';
import '../services/analysis_api_service.dart';

class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen> {
  final _service = const AnalysisApiService();
  final _messageController = TextEditingController();
  final List<_ChatBubbleModel> _messages = <_ChatBubbleModel>[];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatBubbleModel(
        role: 'assistant',
        text:
            'Hi, I am your SubDetox banking assistant. Ask about mandates, recurring debits, disputes, RBI rules, or how-to steps.',
        grounded: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final raw = (preset ?? _messageController.text).trim();
    if (raw.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _messages.add(_ChatBubbleModel(role: 'user', text: raw, grounded: false));
      _messageController.clear();
    });

    try {
      final token = await context.read<AuthProvider>().getIdToken();
      if (token == null) {
        throw AnalysisApiException('Session expired. Please sign in again.');
      }

      final history = _messages
          .take(_messages.length - 1)
          .where((item) => item.role == 'user' || item.role == 'assistant')
          .map(
            (item) => {
              'role': item.role,
              'content': item.text,
            },
          )
          .toList(growable: false);

      final response = await _service.askGeminiAssistant(
        idToken: token,
        message: raw,
        history: history,
      );

      setState(() {
        _messages.add(
          _ChatBubbleModel(
            role: 'assistant',
            text: response.reply,
            grounded: response.grounded,
            sources: response.sources,
            suggestedActions: response.suggestedActions,
          ),
        );
      });
    } on AnalysisApiException catch (error) {
      setState(() {
        _messages.add(
          _ChatBubbleModel(
            role: 'assistant',
            text: error.message,
            grounded: false,
          ),
        );
      });
    } catch (_) {
      setState(() {
        _messages.add(
          const _ChatBubbleModel(
            role: 'assistant',
            text:
                'I could not process that request right now. Please try again.',
            grounded: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _executeAction(String action, _ChatBubbleModel source) async {
    final token = await context.read<AuthProvider>().getIdToken();
    if (token == null) {
      return;
    }

    try {
      if (action == 'CREATE_SUPPORT_TICKET') {
        final ticket = await _service.createSupportTicket(
          idToken: token,
          title: 'Chat-assisted support request',
          description: source.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Support ticket created: ${ticket.ticketId}')),
          );
        }
        return;
      }

      if (action == 'RAISE_BANK_REQUEST') {
        final request = await _service.createServiceRequest(
          idToken: token,
          requestType: 'MANDATE_REVIEW',
          details: source.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Bank request submitted: ${request.requestId}')),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Open the Upload tab to submit statement data.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not complete action.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gemini Banking Chat',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Grounded web search is enabled when available for latest banking updates and practical how-to support.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickPromptChip(
                      label: 'Latest RBI autopay rules',
                      onTap: () => _send(
                          'What are the latest RBI autopay and e-mandate rules in India?'),
                    ),
                    _QuickPromptChip(
                      label: 'How to dispute wrong debit',
                      onTap: () => _send(
                          'How do I dispute an unauthorized recurring debit with my bank?'),
                    ),
                    _QuickPromptChip(
                      label: 'Subscription cleanup plan',
                      onTap: () => _send(
                          'Give me a step-by-step subscription cleanup plan using my linked accounts.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final fromUser = message.role == 'user';
                return Align(
                  alignment:
                      fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 360),
                    decoration: BoxDecoration(
                      color: fromUser
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD6E0EC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.text),
                        if (!fromUser) ...[
                          if (message.grounded)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Grounded with Google Search',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF166534),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          if (message.sources.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: message.sources
                                    .map(
                                      (source) => Chip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(source.title),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          if (message.suggestedActions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: message.suggestedActions
                                    .map(
                                      (action) => ActionChip(
                                        label: Text(_actionLabel(action)),
                                        onPressed: () => _executeAction(
                                          action,
                                          message,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Ask Gemini about banking tips, disputes, mandates...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _actionLabel(String action) {
    switch (action) {
      case 'CREATE_SUPPORT_TICKET':
        return 'Create Ticket';
      case 'RAISE_BANK_REQUEST':
        return 'Raise Request';
      case 'OPEN_MANUAL_UPLOAD':
        return 'Open Upload';
      default:
        return action;
    }
  }
}

class _QuickPromptChip extends StatelessWidget {
  const _QuickPromptChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _ChatBubbleModel {
  const _ChatBubbleModel({
    required this.role,
    required this.text,
    required this.grounded,
    this.sources = const [],
    this.suggestedActions = const [],
  });

  final String role;
  final String text;
  final bool grounded;
  final List<ChatGroundingSource> sources;
  final List<String> suggestedActions;
}

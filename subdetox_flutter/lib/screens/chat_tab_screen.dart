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
        text: 'Ask about mandates, disputes, or recurring debits.',
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
      final displayMessage = error.statusCode == 404
          ? 'Chat service is unavailable right now.'
          : 'Could not get a reply. Please try again.';
      setState(() {
        _messages.add(
          _ChatBubbleModel(
            role: 'assistant',
            text: displayMessage,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Grounded',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _QuickPromptChip(
                  label: 'RBI e-mandate rules',
                  onTap: () => _send(
                      'What are the latest RBI autopay and e-mandate rules in India?'),
                ),
                const SizedBox(width: 8),
                _QuickPromptChip(
                  label: 'Dispute wrong debit',
                  onTap: () => _send(
                      'How do I dispute an unauthorized recurring debit with my bank?'),
                ),
                const SizedBox(width: 8),
                _QuickPromptChip(
                  label: 'Cleanup plan',
                  onTap: () => _send(
                      'Give me a step-by-step subscription cleanup plan using my linked accounts.'),
                ),
                const SizedBox(width: 8),
                _QuickPromptChip(
                  label: 'Show subscriptions',
                  onTap: () => _send('Show all my active subscriptions.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final fromUser = message.role == 'user';
                return Align(
                  alignment:
                      fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: fromUser
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(fromUser ? 20 : 4),
                        bottomRight: Radius.circular(fromUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: fromUser ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        if (!fromUser) ...[
                          if (message.grounded)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.public,
                                      size: 14, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Google Search verification',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (message.sources.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: message.sources
                                    .map(
                                      (source) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          source.title,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          if (message.suggestedActions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: message.suggestedActions
                                    .map(
                                      (action) => ActionChip(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.4),
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        label: Text(
                                          _actionLabel(action),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _executeAction(action, message),
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : () => _send(),
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
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

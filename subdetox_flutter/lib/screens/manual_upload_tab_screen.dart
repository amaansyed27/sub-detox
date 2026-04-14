import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/manual_upload_models.dart';
import '../providers/auth_provider.dart';
import '../services/analysis_api_service.dart';

class ManualUploadTabScreen extends StatefulWidget {
  const ManualUploadTabScreen({super.key});

  @override
  State<ManualUploadTabScreen> createState() => _ManualUploadTabScreenState();
}

class _ManualUploadTabScreenState extends State<ManualUploadTabScreen> {
  final _service = const AnalysisApiService();
  final _fileNameController = TextEditingController(text: 'manual-entry.txt');
  final _contentController = TextEditingController();

  bool _isSubmitting = false;
  ManualUploadResponse? _lastResponse;
  String? _error;

  @override
  void dispose() {
    _fileNameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitUpload() async {
    if (_contentController.text.trim().isEmpty) {
      setState(() => _error = 'Paste transaction content before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = await authProvider.getIdToken();
      if (token == null) {
        setState(() => _error = 'Session expired. Please sign in again.');
        return;
      }

      final response = await _service.submitManualUpload(
        idToken: token,
        fileName: _fileNameController.text.trim(),
        content: _contentController.text,
        uploadMethod: 'paste',
      );

      setState(() {
        _lastResponse = response;
      });
    } on AnalysisApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Unable to submit upload right now.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _createTicketFromUpload() async {
    final upload = _lastResponse;
    if (upload == null) {
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = await authProvider.getIdToken();
      if (token == null) {
        return;
      }

      final ticket = await _service.createSupportTicket(
        idToken: token,
        title: 'Manual upload review request',
        description:
            'Please review upload ${upload.uploadId}. Parsed ${upload.recordsParsed} records with ${upload.estimatedSubscriptions} recurring hints.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket created: ${ticket.ticketId}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create support ticket.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Upload',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Paste statement rows, SMS exports, or transaction snippets for quick recurring-debit detection.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'File name',
                hintText: 'manual-entry.txt',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 8,
              maxLines: 16,
              decoration: const InputDecoration(
                labelText: 'Statement content',
                hintText:
                    '2026-04-01 NETFLIX.COM 649\n2026-04-02 UPI GROCERY 420\n...',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB91C1C),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitUpload,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isSubmitting ? 'Uploading...' : 'Submit Manual Upload',
                ),
              ),
            ),
            if (_lastResponse != null) ...[
              const SizedBox(height: 16),
              _UploadResultCard(
                upload: _lastResponse!,
                onCreateTicket: _createTicketFromUpload,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadResultCard extends StatelessWidget {
  const _UploadResultCard({
    required this.upload,
    required this.onCreateTicket,
  });

  final ManualUploadResponse upload;
  final Future<void> Function() onCreateTicket;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E3F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload ${upload.uploadId} (${upload.status})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Records parsed: ${upload.recordsParsed}'),
          Text('Estimated recurring hints: ${upload.estimatedSubscriptions}'),
          const SizedBox(height: 10),
          ...upload.nextSteps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(step)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onCreateTicket,
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Text('Create Support Ticket from Upload'),
          ),
        ],
      ),
    );
  }
}

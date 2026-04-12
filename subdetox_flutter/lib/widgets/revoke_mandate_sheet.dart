import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum _FlowStepStatus { pending, active, completed }

class RevokeMandateSheet extends StatefulWidget {
  const RevokeMandateSheet({
    super.key,
    required this.displayName,
    required this.monthlyAmount,
    required this.onRevoke,
  });

  final String displayName;
  final double monthlyAmount;
  final Future<void> Function() onRevoke;

  @override
  State<RevokeMandateSheet> createState() => _RevokeMandateSheetState();
}

class _RevokeMandateSheetState extends State<RevokeMandateSheet> {
  final List<_FlowStepStatus> _statuses = [
    _FlowStepStatus.pending,
    _FlowStepStatus.pending,
    _FlowStepStatus.pending,
  ];
  String? _errorMessage;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlow());
  }

  Future<void> _runFlow() async {
    if (_isRunning) {
      return;
    }

    _isRunning = true;
    if (mounted) {
      setState(() {
        _errorMessage = null;
        for (var index = 0; index < _statuses.length; index++) {
          _statuses[index] = _FlowStepStatus.pending;
        }
      });
    }

    await _activateStep(0, const Duration(milliseconds: 1500));
    if (!mounted) {
      _isRunning = false;
      return;
    }

    await _setStepStatus(1, _FlowStepStatus.active);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) {
      _isRunning = false;
      return;
    }

    try {
      await widget.onRevoke();
      await _setStepStatus(1, _FlowStepStatus.completed);
      await _activateStep(2, const Duration(milliseconds: 900));
    } catch (error) {
      if (mounted) {
        setState(() {
          _statuses[1] = _FlowStepStatus.pending;
          _statuses[2] = _FlowStepStatus.pending;
          _errorMessage = _normalizeError(error);
        });
      }
      _isRunning = false;
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) {
      _isRunning = false;
      return;
    }
    _isRunning = false;
    Navigator.of(context).pop(true);
  }

  Future<void> _activateStep(int index, Duration delay) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _statuses[index] = _FlowStepStatus.active;
    });

    await Future<void>.delayed(delay);

    if (!mounted) {
      return;
    }

    setState(() {
      _statuses[index] = _FlowStepStatus.completed;
    });
  }

  Future<void> _setStepStatus(int index, _FlowStepStatus status) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _statuses[index] = status;
    });
  }

  String _normalizeError(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final annualSavings = widget.monthlyAmount * 12;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              width: 48,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Text(
              'Revoke Mandate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _FlowRow(
              icon: LucideIcons.lock,
              title: 'Authenticating via Account Aggregator...',
              status: _statuses[0],
            ),
            const SizedBox(height: 12),
            _FlowRow(
              icon: LucideIcons.search,
              title: 'Intercepting e-NACH mandate ID...',
              status: _statuses[1],
            ),
            const SizedBox(height: 12),
            _FlowRow(
              icon: LucideIcons.checkCircle2,
              title:
                  'Mandate Revoked. ${_formatInr(annualSavings)} saved annually!',
              status: _statuses[2],
              doneColor: const Color(0xFF16A34A),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isRunning ? null : _runFlow,
                  icon: const Icon(LucideIcons.refreshCcw, size: 16),
                  label: const Text('Retry revocation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatInr(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.icon,
    required this.title,
    required this.status,
    this.doneColor = const Color(0xFF0F172A),
  });

  final IconData icon;
  final String title;
  final _FlowStepStatus status;
  final Color doneColor;

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == _FlowStepStatus.active;
    final bool isDone = status == _FlowStepStatus.completed;

    final Color borderColor = isDone
        ? doneColor.withValues(alpha: 0.35)
        : isActive
            ? const Color(0xFF60A5FA)
            : const Color(0xFFE2E8F0);

    final Color iconColor = isDone
        ? doneColor
        : isActive
            ? const Color(0xFF2563EB)
            : const Color(0xFF94A3B8);

    final Color tileColor = isDone
        ? doneColor.withValues(alpha: 0.08)
        : isActive
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF8FAFC);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDone ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    fontWeight: isDone ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

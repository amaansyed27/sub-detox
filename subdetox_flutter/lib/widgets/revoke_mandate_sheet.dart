import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum _FlowStepStatus { pending, active, completed }

class RevokeMandateSheet extends StatefulWidget {
  const RevokeMandateSheet({
    super.key,
    required this.displayName,
    required this.monthlyAmount,
  });

  final String displayName;
  final double monthlyAmount;

  @override
  State<RevokeMandateSheet> createState() => _RevokeMandateSheetState();
}

class _RevokeMandateSheetState extends State<RevokeMandateSheet> {
  final List<_FlowStepStatus> _statuses = [
    _FlowStepStatus.pending,
    _FlowStepStatus.pending,
    _FlowStepStatus.pending,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlow());
  }

  Future<void> _runFlow() async {
    await _activateStep(0, const Duration(milliseconds: 1500));
    await _activateStep(1, const Duration(milliseconds: 1500));
    await _activateStep(2, const Duration(milliseconds: 1500));

    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) {
      return;
    }
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

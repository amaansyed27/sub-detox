import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ActionHeroCard extends StatelessWidget {
  const ActionHeroCard({
    super.key,
    required this.monthlyLeakage,
    required this.scannedCount,
    required this.activeDetectedCount,
    required this.resolvedCount,
    required this.currency,
  });

  final double monthlyLeakage;
  final int scannedCount;
  final int activeDetectedCount;
  final int resolvedCount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final annualLeakage = monthlyLeakage * 12;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D1E3A8A),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.shield, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Potential Monthly Leakage',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: monthlyLeakage),
            builder: (context, animatedValue, _) {
              return Text(
                _formatCurrency(animatedValue, currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatCurrency(annualLeakage, currency)} annual impact if untouched',
            style: const TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: 'Scanned', value: '$scannedCount txns'),
              _InfoPill(label: 'Active Risks', value: '$activeDetectedCount'),
              _InfoPill(label: 'Resolved', value: '$resolvedCount'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currencyCode) {
    if (currencyCode.toUpperCase() == 'INR') {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      ).format(amount);
    }

    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '$currencyCode ',
      decimalDigits: 0,
    ).format(amount);
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

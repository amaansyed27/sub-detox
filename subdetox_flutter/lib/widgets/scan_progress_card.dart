import 'package:flutter/material.dart';

class ScanProgressCard extends StatelessWidget {
  const ScanProgressCard({
    super.key,
    required this.scannedCount,
    required this.flaggedCount,
    required this.resolvedCount,
  });

  final int scannedCount;
  final int flaggedCount;
  final int resolvedCount;

  @override
  Widget build(BuildContext context) {
    final safeScanned = scannedCount <= 0 ? 1 : scannedCount;
    final flaggedRatio = (flaggedCount / safeScanned).clamp(0.0, 1.0);
    final resolvedRatio = (resolvedCount / safeScanned).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Scan Confidence',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Proof that SubDetox analyzed raw transaction history before flagging risks.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _MetricRow(
            label: 'Transactions scanned',
            value: '$scannedCount',
            color: const Color(0xFF1D4ED8),
            progress: 1,
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: 'Subscriptions flagged',
            value: '$flaggedCount',
            color: const Color(0xFFF97316),
            progress: flaggedRatio,
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: 'Already resolved',
            value: '$resolvedCount',
            color: const Color(0xFF16A34A),
            progress: resolvedRatio,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  final String label;
  final String value;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

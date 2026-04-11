import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/detected_subscription.dart';
import '../models/threat_level.dart';

class SubscriptionCard extends StatefulWidget {
  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.resolved,
    required this.onRevoke,
  });

  final DetectedSubscription subscription;
  final bool resolved;
  final VoidCallback onRevoke;

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final threat = widget.subscription.threatLevel;
    final colors = _threatColors(threat);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: widget.resolved ? 0.7 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.resolved ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: widget.resolved ? const Color(0xFFCBD5E1) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subscription.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subscription.sampleNarration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatInr(widget.subscription.estimatedMonthlyAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        threat.label,
                        style: TextStyle(
                          color: colors.foreground,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MetaPill(
                  icon: LucideIcons.history,
                  label: '${widget.subscription.occurrenceCount} cycles',
                ),
                const SizedBox(width: 8),
                _MetaPill(
                  icon: LucideIcons.sparkles,
                  label: 'Confidence ${(widget.subscription.confidenceScore * 100).toStringAsFixed(0)}%',
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(LucideIcons.chevronDown, size: 18),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why did we flag this?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subscription.reasoning,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: widget.resolved
                  ? Container(
                      key: const ValueKey('resolved'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.badgeCheck, size: 16, color: Color(0xFF334155)),
                          SizedBox(width: 8),
                          Text(
                            'Resolved',
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('revoke'),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onRevoke,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(LucideIcons.shield, size: 16),
                        label: const Text('Revoke Mandate'),
                      ),
                    ),
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

  _ThreatPalette _threatColors(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.high:
        return const _ThreatPalette(
          background: Color(0xFFFEE2E2),
          foreground: Color(0xFFB91C1C),
        );
      case ThreatLevel.medium:
        return const _ThreatPalette(
          background: Color(0xFFFEF3C7),
          foreground: Color(0xFFB45309),
        );
      case ThreatLevel.low:
        return const _ThreatPalette(
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF166534),
        );
      case ThreatLevel.unknown:
        return const _ThreatPalette(
          background: Color(0xFFE2E8F0),
          foreground: Color(0xFF334155),
        );
    }
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatPalette {
  const _ThreatPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

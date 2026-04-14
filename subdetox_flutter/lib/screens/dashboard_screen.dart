import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/detected_subscription.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/action_hero_card.dart';
import '../widgets/revoke_mandate_sheet.dart';
import '../widgets/scan_progress_card.dart';
import '../widgets/section_header.dart';
import '../widgets/subscription_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Consumer2<AuthProvider, AnalysisProvider>(
            builder: (context, authProvider, provider, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _TopBar(
                      state: provider.state,
                      onRescan: provider.analyze,
                      onLogout: authProvider.signOut,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: switch (provider.state) {
                          DashboardState.initial => _InitialView(
                              onStartAnalysis: provider.analyze,
                            ),
                          DashboardState.analyzing => const _AnalyzingView(),
                          DashboardState.error => _ErrorView(
                              message: provider.errorMessage ??
                                  'Unable to complete analysis.',
                              onRetry: provider.analyze,
                            ),
                          DashboardState.results =>
                            _ResultsView(provider: provider),
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.state,
    required this.onRescan,
    required this.onLogout,
  });

  final DashboardState state;
  final Future<void> Function() onRescan;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            ),
          ),
          child: const Icon(LucideIcons.wallet2, size: 19, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SubDetox',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 24),
              ),
              Text(
                'Silent wealth leakage auditor',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (state == DashboardState.results)
          TextButton.icon(
            onPressed: onRescan,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Re-scan'),
          ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onLogout,
          icon: const Icon(LucideIcons.logOut, size: 18),
        ),
      ],
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView({required this.onStartAnalysis});

  final Future<void> Function() onStartAnalysis;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x170F172A),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(LucideIcons.scanFace,
                  color: Color(0xFF1D4ED8), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Ready for AI Audit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze 90 days of bank transactions to detect hidden subscriptions, auto-debits, and telecom VAS leakage.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(LucideIcons.sparkles, size: 16),
                label: const Text('Start AI Analysis'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x170F172A),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzing transaction intelligence...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'SubDetox is isolating recurring mandates and suspicious debits.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertTriangle,
                color: Color(0xFFDC2626), size: 28),
            const SizedBox(height: 10),
            Text(
              'Analysis failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCcw, size: 16),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.provider});

  final AnalysisProvider provider;

  @override
  Widget build(BuildContext context) {
    final analysis = provider.analysis;
    if (analysis == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: provider.analyze,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _AnalysisSourceBanner(
            analysisSource: analysis.analysisSource,
            geminiError: analysis.geminiError,
          ),
          const SizedBox(height: 12),
          ActionHeroCard(
            key: ValueKey('hero-${analysis.generatedAt.toIso8601String()}'),
            monthlyLeakage: provider.activeMonthlyLeakage,
            scannedCount: analysis.scannedTransactionCount,
            activeDetectedCount: provider.activeDetectedCount,
            resolvedCount: provider.resolvedCount,
            currency: analysis.currency,
          ),
          const SizedBox(height: 14),
          ScanProgressCard(
            scannedCount: analysis.scannedTransactionCount,
            flaggedCount: analysis.detectedSubscriptions.length,
            resolvedCount: provider.resolvedCount,
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Immediate Action Required',
            subtitle:
                'High-risk recurring debits likely draining money silently.',
            icon: LucideIcons.siren,
          ),
          const SizedBox(height: 12),
          ..._buildSubscriptionCards(
            context,
            _sortWithResolvedLast(provider.immediateActionRequired, provider),
            provider,
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Monitor Closely',
            subtitle: 'Medium-risk mandates worth reviewing this week.',
            icon: LucideIcons.shieldAlert,
          ),
          const SizedBox(height: 12),
          ..._buildSubscriptionCards(
            context,
            _sortWithResolvedLast(provider.monitorClosely, provider),
            provider,
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Known Subscriptions',
            subtitle:
                'Mainstream low-risk subscriptions detected by the engine.',
            icon: LucideIcons.checkCircle2,
          ),
          const SizedBox(height: 12),
          ..._buildSubscriptionCards(
            context,
            _sortWithResolvedLast(provider.knownSubscriptions, provider),
            provider,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSubscriptionCards(
    BuildContext context,
    List<DetectedSubscription> subscriptions,
    AnalysisProvider provider,
  ) {
    if (subscriptions.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'No items in this category.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ];
    }

    return subscriptions
        .map(
          (subscription) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SubscriptionCard(
              subscription: subscription,
              resolved: provider.isResolved(subscription.merchantCode),
              onRevoke: () => _handleRevoke(context, provider, subscription),
            ),
          ),
        )
        .toList();
  }

  List<DetectedSubscription> _sortWithResolvedLast(
    List<DetectedSubscription> subscriptions,
    AnalysisProvider provider,
  ) {
    final sorted = [...subscriptions];
    sorted.sort((a, b) {
      final aResolved = provider.isResolved(a.merchantCode);
      final bResolved = provider.isResolved(b.merchantCode);

      if (aResolved != bResolved) {
        return aResolved ? 1 : -1;
      }
      return b.estimatedMonthlyAmount.compareTo(a.estimatedMonthlyAmount);
    });
    return sorted;
  }

  Future<void> _handleRevoke(
    BuildContext context,
    AnalysisProvider provider,
    DetectedSubscription subscription,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => RevokeMandateSheet(
        displayName: subscription.displayName,
        monthlyAmount: subscription.estimatedMonthlyAmount,
        onRevoke: () => provider.revokeMandate(subscription),
      ),
    );
  }
}

class _AnalysisSourceBanner extends StatelessWidget {
  const _AnalysisSourceBanner({
    required this.analysisSource,
    required this.geminiError,
  });

  final String analysisSource;
  final String? geminiError;

  @override
  Widget build(BuildContext context) {
    final normalized = analysisSource.toUpperCase();
    final isGemini = normalized == 'RULES_PLUS_GEMINI';
    final isFallback = normalized == 'RULES_FALLBACK';

    final toneColor = isGemini
        ? const Color(0xFF166534)
        : isFallback
            ? const Color(0xFF92400E)
            : const Color(0xFF1E3A8A);
    final bgColor = isGemini
        ? const Color(0xFFDCFCE7)
        : isFallback
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFE0E7FF);

    final label = switch (normalized) {
      'RULES_PLUS_GEMINI' => 'Rules + Gemini 2.5 Flash',
      'RULES_FALLBACK' => 'Rules engine (Gemini fallback)',
      _ => 'Rules engine only',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: toneColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGemini ? LucideIcons.sparkles : LucideIcons.brain,
                size: 16,
                color: toneColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analysis engine: $label',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: toneColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (isFallback && (geminiError ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Gemini fallback reason: ${geminiError!}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF78350F),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

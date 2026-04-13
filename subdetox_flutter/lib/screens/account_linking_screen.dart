import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/linked_bank_models.dart';
import '../providers/account_linking_provider.dart';
import '../providers/auth_provider.dart';

class AccountLinkingScreen extends StatelessWidget {
  const AccountLinkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountLinkingProvider, AuthProvider>(
      builder: (context, linkingProvider, authProvider, _) {
        final isLoading =
            linkingProvider.state == AccountLinkingState.loading ||
                linkingProvider.state == AccountLinkingState.idle;
        final isSaving = linkingProvider.state == AccountLinkingState.saving;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF071225),
                  Color(0xFF0D2A4A),
                  Color(0xFF124E66),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.landmark,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Link your bank accounts',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 21,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Pick accounts to run SubDetox recurring debit analysis.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: const Color(0xFFD7E6F8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sign out',
                          onPressed: authProvider.isBusy
                              ? null
                              : () => authProvider.signOut(),
                          icon: const Icon(
                            LucideIcons.logOut,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6F8FC),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: isLoading
                            ? const _LoadingState()
                            : linkingProvider.state == AccountLinkingState.error
                                ? _ErrorState(
                                    message: linkingProvider.errorMessage ??
                                        'Unable to load linked accounts.',
                                    onRetry: linkingProvider.retry,
                                  )
                                : _SelectionState(
                                    mobileNumber: linkingProvider.mobileNumber,
                                    linkedBanks: linkingProvider.linkedBanks,
                                    selectedCount:
                                        linkingProvider.selectedCount,
                                    isSaving: isSaving,
                                    canSubmit: linkingProvider.canSubmit,
                                    onToggle: linkingProvider.toggleSelection,
                                    isSelected: linkingProvider.isSelected,
                                    onContinue: linkingProvider.saveSelection,
                                  ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 14),
            Text(
              'Fetching linked bank accounts...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: Color(0xFFB91C1C),
                size: 24,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionState extends StatelessWidget {
  const _SelectionState({
    required this.mobileNumber,
    required this.linkedBanks,
    required this.selectedCount,
    required this.isSaving,
    required this.canSubmit,
    required this.onToggle,
    required this.isSelected,
    required this.onContinue,
  });

  final String? mobileNumber;
  final List<LinkedBankInstitution> linkedBanks;
  final int selectedCount;
  final bool isSaving;
  final bool canSubmit;
  final ValueChanged<String> onToggle;
  final bool Function(String linkRefNumber) isSelected;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final maskedMobile = _maskedMobile(mobileNumber);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC7DBFF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.shieldCheck,
                  size: 16,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verified mobile: $maskedMobile. Select at least one account to continue to dashboard.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: linkedBanks.length,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            itemBuilder: (context, bankIndex) {
              final bank = linkedBanks[bankIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD9E2EE)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.building2,
                              size: 17,
                              color: Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bank.bankName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _StatusPill(status: bank.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...bank.accounts.map((account) {
                          final selected = isSelected(account.linkRefNumber);
                          final suffix = account.maskedAccNumber.length >= 4
                              ? account.maskedAccNumber.substring(
                                  account.maskedAccNumber.length - 4,
                                )
                              : account.maskedAccNumber;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isSaving
                                  ? null
                                  : () => onToggle(account.linkRefNumber),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFEAF2FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFFD2DAE6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: selected,
                                      onChanged: isSaving
                                          ? null
                                          : (_) =>
                                              onToggle(account.linkRefNumber),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${account.accType} - $suffix',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color:
                                                      const Color(0xFF0F172A),
                                                ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${account.nickname} (${account.fiType})',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        LucideIcons.checkCircle2,
                                        size: 17,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: ElevatedButton.icon(
            onPressed: canSubmit && !isSaving ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B1B34),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.arrowRight, size: 16),
            label: Text(
              isSaving
                  ? 'Saving account selection...'
                  : 'Continue with $selectedCount selected account${selectedCount == 1 ? '' : 's'}',
            ),
          ),
        ),
      ],
    );
  }

  static String _maskedMobile(String? mobileNumber) {
    final value = (mobileNumber ?? '').trim();
    if (value.isEmpty) {
      return 'not available';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) {
      return value;
    }

    final visible = digits.substring(digits.length - 4);
    return 'xxxxxx$visible';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isActive = normalized == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFDE68A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  isActive ? const Color(0xFF166534) : const Color(0xFF92400E),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

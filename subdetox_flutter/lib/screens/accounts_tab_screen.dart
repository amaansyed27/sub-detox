import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/linked_bank_models.dart';
import '../providers/account_linking_provider.dart';

class AccountsTabScreen extends StatelessWidget {
  const AccountsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<AccountLinkingProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Linked Bank Accounts',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mobile: ${_maskedMobile(provider.mobileNumber)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: provider.isLoading ? null : provider.retry,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MessageCard(
                    text: provider.errorMessage!,
                    color: const Color(0xFFFEE2E2),
                    textColor: const Color(0xFF991B1B),
                  ),
                ),
              if (provider.state == AccountLinkingState.completed &&
                  provider.selectedCount > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _MessageCard(
                    text: 'Selection saved.',
                    color: Color(0xFFDCFCE7),
                    textColor: Color(0xFF166534),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.linkedBanks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFD6E0EC)),
                              ),
                              child: Text(
                                'No linked accounts found. Tap refresh to retry.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: provider.linkedBanks.length,
                            itemBuilder: (context, index) {
                              final bank = provider.linkedBanks[index];
                              return _BankCard(
                                bank: bank,
                                isSelected: provider.isSelected,
                                isSaving:
                                    provider.state == AccountLinkingState.saving,
                                onToggle: provider.toggleSelection,
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        provider.canSubmit ? provider.saveSelection : null,
                    icon: provider.state == AccountLinkingState.saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      provider.state == AccountLinkingState.saving
                          ? 'Saving...'
                          : provider.linkedBanks.isEmpty
                              ? 'No accounts available'
                              : 'Save ${provider.selectedCount} account${provider.selectedCount == 1 ? '' : 's'}',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _maskedMobile(String? mobile) {
    final value = (mobile ?? '').trim();
    if (value.isEmpty) {
      return 'not available';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) {
      return value;
    }

    return 'xxxxxx${digits.substring(digits.length - 4)}';
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({
    required this.bank,
    required this.isSelected,
    required this.isSaving,
    required this.onToggle,
  });

  final LinkedBankInstitution bank;
  final bool Function(String) isSelected;
  final bool isSaving;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bank.bankName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusPill(status: bank.status),
              ],
            ),
            const SizedBox(height: 8),
            ...bank.accounts.map((account) {
              final checked = isSelected(account.linkRefNumber);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: checked,
                onChanged:
                    isSaving ? null : (_) => onToggle(account.linkRefNumber),
                title: Text('${account.accType} - ${account.maskedAccNumber}'),
                subtitle: Text('${account.nickname} (${account.fiType})'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status.toUpperCase() == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? const Color(0xFF166534) : const Color(0xFF92400E),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

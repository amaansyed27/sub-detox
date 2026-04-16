import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/account_linking_provider.dart';
import '../providers/auth_provider.dart';

class SettingsTabScreen extends StatelessWidget {
  const SettingsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final accountProvider = context.watch<AccountLinkingProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _SettingsSection(
                  title: 'Account Information',
                  icon: Icons.person_outline,
                  children: [
                    _SettingsListTile(
                      title: 'Email',
                      subtitle: authProvider.activeEmail ?? 'Not available',
                      icon: Icons.email_outlined,
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsListTile(
                      title: 'Phone Number',
                      subtitle: (authProvider.activePhoneNumber?.isNotEmpty ==
                              true)
                          ? authProvider.activePhoneNumber!
                          : (accountProvider.mobileNumber?.isNotEmpty == true)
                              ? accountProvider.mobileNumber!
                              : 'Not available',
                      icon: Icons.phone_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsSection(
                  title: 'Data Sources',
                  icon: Icons.account_balance_outlined,
                  children: [
                    _SettingsListTile(
                      title: 'Bank Accounts',
                      subtitle: accountProvider.needsOnboarding
                          ? 'Action required - Link your accounts'
                          : 'Linked securely',
                      icon: Icons.food_bank_outlined,
                      trailing: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: accountProvider.needsOnboarding
                              ? Colors.orange.shade700
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: accountProvider.isLoading
                            ? null
                            : accountProvider.retry,
                        icon: accountProvider.isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.sync, size: 18),
                        label: const Text('Refresh'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: authProvider.isBusy ? null : authProvider.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  const _SettingsListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

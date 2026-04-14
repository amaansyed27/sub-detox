import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/account_linking_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';

class SettingsTabScreen extends StatelessWidget {
  const SettingsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final accountProvider = context.watch<AccountLinkingProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signed in account',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Email: ${authProvider.activeEmail ?? 'Not available'}'),
                  Text(
                      'Phone: ${authProvider.activePhoneNumber ?? 'Not available'}'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Runtime configuration',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Backend mode: ${ApiConfig.backendMode}'),
                  const Text('Project ID: ${ApiConfig.projectId}'),
                  const SizedBox(height: 4),
                  const Text('Gemini grounding: backend controlled'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Linked account setup',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    accountProvider.needsOnboarding
                        ? 'Selection pending. Complete it in Accounts.'
                        : 'Selection complete.',
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: accountProvider.isLoading
                        ? null
                        : accountProvider.retry,
                    icon: const Icon(Icons.sync),
                    label: const Text('Refresh Accounts'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F1D1D),
              foregroundColor: Colors.white,
            ),
            onPressed: authProvider.isBusy ? null : authProvider.signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

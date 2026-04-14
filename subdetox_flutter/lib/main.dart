import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/account_linking_provider.dart';
import 'providers/analysis_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell_screen.dart';
import 'screens/login_screen.dart';
import 'services/analysis_api_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_runtime_options.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initError;
  try {
    await Firebase.initializeApp(
      options: FirebaseRuntimeOptions.currentPlatform,
    );

    const useEmulator = bool.fromEnvironment(
      'FIREBASE_USE_EMULATOR',
      defaultValue: false,
    );

    if (useEmulator) {
      final emulatorHost =
          kIsWeb || defaultTargetPlatform != TargetPlatform.android
              ? '127.0.0.1'
              : '10.0.2.2';
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    }
  } catch (error) {
    initError = error;
  }

  runApp(SubDetoxApp(initError: initError));
}

class SubDetoxApp extends StatelessWidget {
  const SubDetoxApp({super.key, this.initError});

  final Object? initError;

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SubDetox',
        theme: AppTheme.lightTheme,
        home: _BootstrapErrorScreen(error: initError.toString()),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService: AuthService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AccountLinkingProvider>(
          create: (_) =>
              AccountLinkingProvider(apiService: const AnalysisApiService()),
          update: (_, authProvider, linkingProvider) {
            final provider = linkingProvider ??
                AccountLinkingProvider(apiService: const AnalysisApiService());
            provider.updateAuthProvider(authProvider);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, AccountLinkingProvider,
            AnalysisProvider>(
          create: (_) =>
              AnalysisProvider(apiService: const AnalysisApiService()),
          update: (_, authProvider, accountLinkingProvider, analysisProvider) {
            final provider = analysisProvider ??
                AnalysisProvider(apiService: const AnalysisApiService());
            provider.updateAuthProvider(
              authProvider,
              canLoadAnalysis: authProvider.isAuthenticated &&
                  accountLinkingProvider.state ==
                      AccountLinkingState.completed &&
                  !accountLinkingProvider.needsOnboarding,
            );
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SubDetox',
        theme: AppTheme.lightTheme,
        home: Consumer2<AuthProvider, AccountLinkingProvider>(
          builder: (context, authProvider, accountLinkingProvider, _) {
            switch (authProvider.status) {
              case AuthStatus.initializing:
                return const _AuthLoadingScreen();
              case AuthStatus.authenticated:
                final accountLinkingState = accountLinkingProvider.state;
                final waitingForLinkingState =
                    accountLinkingState == AccountLinkingState.idle ||
                        accountLinkingState == AccountLinkingState.loading;

                if (waitingForLinkingState) {
                  return const _AuthLoadingScreen();
                }

                final needsAccountLinking =
                    accountLinkingProvider.needsOnboarding ||
                        accountLinkingState == AccountLinkingState.ready ||
                        accountLinkingState == AccountLinkingState.saving ||
                        accountLinkingState == AccountLinkingState.error;

                return AppShellScreen(
                    initialIndex: needsAccountLinking ? 1 : 0);
              case AuthStatus.unauthenticated:
              case AuthStatus.error:
                return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFDC2626), size: 32),
              const SizedBox(height: 12),
              Text(
                'Firebase bootstrap failed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

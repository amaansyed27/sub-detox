import 'package:firebase_core/firebase_core.dart';

class FirebaseRuntimeOptions {
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'replace-with-your-project-id',
  );

  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: String.fromEnvironment(
          'FIREBASE_API_KEY',
          defaultValue: 'replace-with-api-key',
        ),
        appId: String.fromEnvironment(
          'FIREBASE_APP_ID',
          defaultValue: 'replace-with-app-id',
        ),
        messagingSenderId: String.fromEnvironment(
          'FIREBASE_MESSAGING_SENDER_ID',
          defaultValue: 'replace-with-sender-id',
        ),
        projectId: projectId,
        authDomain: String.fromEnvironment(
          'FIREBASE_AUTH_DOMAIN',
          defaultValue: 'replace-with-auth-domain',
        ),
        storageBucket: String.fromEnvironment(
          'FIREBASE_STORAGE_BUCKET',
          defaultValue: 'replace-with-storage-bucket',
        ),
      );
}

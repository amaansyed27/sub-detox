import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'subdetox-20260412-8514',
  );

  static const bool useEmulator = bool.fromEnvironment(
    'FIREBASE_USE_EMULATOR',
    defaultValue: true,
  );

  static String get _host {
    if (kIsWeb) {
      return '127.0.0.1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return '127.0.0.1';
    }
  }

  static Uri _emulatorUri(String path) {
    return Uri.parse('http://$_host:5001/$projectId/asia-south1/api$path');
  }

  static Uri _cloudUri(String path) {
    return Uri.parse('https://asia-south1-$projectId.cloudfunctions.net/api$path');
  }

  static Uri _uri(String path) => useEmulator ? _emulatorUri(path) : _cloudUri(path);

  static Uri get analyzeTransactionsUri => _uri('/analyze-transactions');

  static Uri get revokeMandateUri => _uri('/revoke-mandate');

  static Uri get mockAaDataUri => _uri('/mock-aa-data');

  static Uri get meUri => _uri('/me');

  static Map<String, String> authHeaders(String idToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }
}

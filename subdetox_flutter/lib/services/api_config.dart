import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String backendMode = String.fromEnvironment(
    'BACKEND_MODE',
    defaultValue: 'fastapi-cloud',
  );

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: '',
  );

  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'subdetox-20260412-8514',
  );

  static const int fastApiLocalPort = int.fromEnvironment(
    'FASTAPI_LOCAL_PORT',
    defaultValue: 8000,
  );

  static const String localApiHostOverride = String.fromEnvironment(
    'LOCAL_API_HOST',
    defaultValue: '',
  );

  static const String cloudRunUrl = String.fromEnvironment(
    'CLOUD_RUN_URL',
    defaultValue: 'https://subdetox-api-wiz4yigmpq-el.a.run.app',
  );

  static const bool useEmulator = bool.fromEnvironment(
    'FIREBASE_USE_EMULATOR',
    defaultValue: false,
  );

  static String get _host {
    if (kIsWeb) {
      return '127.0.0.1';
    }

    if (localApiHostOverride.isNotEmpty) {
      return localApiHostOverride;
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
    return Uri.parse(
        'https://asia-south1-$projectId.cloudfunctions.net/api$path');
  }

  static Uri _fastApiLocalUri(String path) {
    return Uri.parse('http://$_host:$fastApiLocalPort/api$path');
  }

  static Uri _fastApiCloudUri(String path) {
    if (cloudRunUrl.isNotEmpty) {
      return Uri.parse(
          '${cloudRunUrl.replaceAll(RegExp(r'/+$'), '')}/api$path');
    }
    if (backendBaseUrl.isNotEmpty) {
      return Uri.parse(
          '${backendBaseUrl.replaceAll(RegExp(r'/+$'), '')}/api$path');
    }
    return _cloudUri(path);
  }

  static Uri _uri(String path) {
    switch (backendMode) {
      case 'functions-emulator':
        return _emulatorUri(path);
      case 'functions-cloud':
        return _cloudUri(path);
      case 'fastapi-local':
        return _fastApiLocalUri(path);
      case 'fastapi-cloud':
        return _fastApiCloudUri(path);
      default:
        return useEmulator ? _emulatorUri(path) : _fastApiCloudUri(path);
    }
  }

  static Uri get analyzeTransactionsUri => _uri('/analyze-transactions');

  static Uri get latestAnalysisUri => _uri('/analysis/latest');

  static Uri get revokeMandateUri => _uri('/revoke-mandate');

  static Uri get mockAaDataUri => _uri('/mock-aa-data');

  static Uri get meUri => _uri('/me');

  static Uri get accountAvailabilityUri => _uri('/v2/account-availability');

  static Uri get accountSelectionUri => _uri('/v2/account-selection');

  static Uri get manualUploadUri => _uri('/manual-upload');

  static Uri get chatAssistUri => _uri('/chat/assist');

  static Uri get chatTicketsUri => _uri('/chat/tickets');

  static Uri get chatRequestsUri => _uri('/chat/requests');

  static Map<String, String> authHeaders(String idToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }
}

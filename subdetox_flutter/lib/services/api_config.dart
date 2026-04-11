import 'package:flutter/foundation.dart';

class ApiConfig {
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

  static Uri get analyzeTransactionsUri {
    return Uri.parse('http://$_host:8000/api/analyze-transactions/');
  }
}

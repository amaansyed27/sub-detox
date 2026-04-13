import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseRuntimeOptions {
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static String _requiredDefine(String key, String value) {
    if (value.isEmpty) {
      throw StateError(
        'Missing Firebase config: $key. Pass it with --dart-define=$key=<value>.',
      );
    }
    return value;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return _web;
    }
  }

  static FirebaseOptions get _web => FirebaseOptions(
        apiKey: _requiredDefine(
          'FIREBASE_API_KEY',
          const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
        ),
        appId: _requiredDefine(
          'FIREBASE_APP_ID',
          const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: ''),
        ),
        messagingSenderId: _requiredDefine(
          'FIREBASE_MESSAGING_SENDER_ID',
          const String.fromEnvironment(
            'FIREBASE_MESSAGING_SENDER_ID',
            defaultValue: '',
          ),
        ),
        projectId: _requiredDefine(
          'FIREBASE_PROJECT_ID',
          const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
        ),
        authDomain: _requiredDefine(
          'FIREBASE_AUTH_DOMAIN',
          const String.fromEnvironment(
            'FIREBASE_AUTH_DOMAIN',
            defaultValue: '',
          ),
        ),
        storageBucket: _requiredDefine(
          'FIREBASE_STORAGE_BUCKET',
          const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
            defaultValue: '',
          ),
        ),
      );

  static FirebaseOptions get _android => FirebaseOptions(
        apiKey: _requiredDefine(
          'FIREBASE_ANDROID_API_KEY',
          const String.fromEnvironment(
            'FIREBASE_ANDROID_API_KEY',
            defaultValue: '',
          ),
        ),
        appId: _requiredDefine(
          'FIREBASE_ANDROID_APP_ID',
          const String.fromEnvironment(
            'FIREBASE_ANDROID_APP_ID',
            defaultValue: '',
          ),
        ),
        messagingSenderId: _requiredDefine(
          'FIREBASE_MESSAGING_SENDER_ID',
          const String.fromEnvironment(
            'FIREBASE_MESSAGING_SENDER_ID',
            defaultValue: '',
          ),
        ),
        projectId: _requiredDefine(
          'FIREBASE_PROJECT_ID',
          const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
        ),
        storageBucket: _requiredDefine(
          'FIREBASE_STORAGE_BUCKET',
          const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
            defaultValue: '',
          ),
        ),
      );
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStatus { initializing, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService {
    _subscription = _authService.authStateChanges().listen(_onAuthStateChanged);
  }

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  AuthStatus _status = AuthStatus.initializing;
  String? _errorMessage;
  bool _isBusy = false;
  String? _verificationId;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get otpRequested => _verificationId != null;

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  void _onAuthStateChanged(User? user) {
    _status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      await _authService.signInWithEmailPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = error.message ?? 'Email sign-in failed.';
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      await _authService.registerWithEmailPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = error.message ?? 'Registration failed.';
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> requestPhoneOtp(String phoneNumber) async {
    _setBusy(true);
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    try {
      await _authService.requestPhoneOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete();
          }
          notifyListeners();
        },
        onVerificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _verificationId = null;
          if (!completer.isCompleted) {
            completer.complete();
          }
          notifyListeners();
        },
        onVerificationFailed: (error) {
          _status = AuthStatus.error;
          _errorMessage = error.message ?? 'OTP request failed.';
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          notifyListeners();
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete();
          }
          notifyListeners();
        },
      );

      await completer.future;
    } catch (error) {
      _status = AuthStatus.error;
      _errorMessage = 'Unable to request OTP.';
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> verifyPhoneOtp(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      _status = AuthStatus.error;
      _errorMessage = 'Request OTP before verification.';
      notifyListeners();
      return;
    }

    _setBusy(true);
    try {
      await _authService.verifyPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      _verificationId = null;
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = error.message ?? 'Invalid OTP code.';
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    _setBusy(true);
    try {
      _verificationId = null;
      await _authService.signOut();
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> getIdToken() {
    return _authService.getIdToken();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

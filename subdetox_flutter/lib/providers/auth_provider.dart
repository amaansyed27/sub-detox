import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStatus { initializing, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService})
      : _authService = authService {
    _subscription = _authService.authStateChanges().listen(_onAuthStateChanged);
  }

  static const int _otpRequestCooldownSeconds = 60;
  static const int _otpBlockedCooldownSeconds = 180;

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;
  Timer? _otpTimer;

  AuthStatus _status = AuthStatus.initializing;
  String? _errorMessage;
  bool _isBusy = false;
  String? _verificationId;
  int? _resendToken;
  String? _lastPhoneNumber;
  String? _verifiedPhoneNumber;
  int _otpCooldownSeconds = 0;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get otpRequested => _verificationId != null;
  bool get hasOtpCooldown => _otpCooldownSeconds > 0;
  int get otpCooldownSeconds => _otpCooldownSeconds;
  bool get canResendOtp => otpRequested && _otpCooldownSeconds == 0;
  String? get lastPhoneNumber => _lastPhoneNumber;
  String? get activePhoneNumber =>
      _verifiedPhoneNumber ?? _authService.currentPhoneNumber;
  String? get activeEmail => _authService.currentEmail;

  String get otpCooldownLabel {
    final minutes = (_otpCooldownSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_otpCooldownSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startOtpCooldown({int seconds = _otpRequestCooldownSeconds}) {
    _otpTimer?.cancel();
    _otpCooldownSeconds = seconds;
    notifyListeners();

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCooldownSeconds <= 0) {
        timer.cancel();
        return;
      }
      _otpCooldownSeconds -= 1;
      notifyListeners();
    });
  }

  bool _isDeviceBlockedOtpError(FirebaseAuthException error) {
    final code = error.code.toLowerCase();
    final rawMessage = (error.message ?? '').toLowerCase();
    return code == 'too-many-requests' ||
        rawMessage.contains('blocked all requests from this device');
  }

  String _messageFromAuthError(
    FirebaseAuthException error, {
    required String fallback,
  }) {
    final code = error.code.toLowerCase();
    final rawMessage = (error.message ?? '').toLowerCase();

    if (_isDeviceBlockedOtpError(error)) {
      return 'Too many OTP attempts were detected from this device. Please wait a while and try again. If it continues, switch network or try another device.';
    }

    if (code == 'operation-not-allowed') {
      if (rawMessage
          .contains('sms unable to be sent until this region enabled')) {
        return 'Phone OTP is not enabled for your region yet. Please use Email sign-in for now.';
      }
      if (rawMessage.contains('sign-in provider is disabled')) {
        return 'This sign-in method is disabled for this project. Please contact support or use Email sign-in.';
      }
      return 'This sign-in method is currently unavailable. Please try Email sign-in.';
    }

    if (code == 'invalid-phone-number') {
      return 'Enter a valid phone number with country code (for example +91XXXXXXXXXX).';
    }

    if (code == 'email-already-in-use') {
      return 'This email is already registered. Try Sign in instead.';
    }

    if (code == 'invalid-credential' ||
        code == 'wrong-password' ||
        code == 'user-not-found') {
      return 'Email or password is incorrect.';
    }

    if (code == 'invalid-email') {
      return 'Please enter a valid email address.';
    }

    if (code == 'weak-password') {
      return 'Password is too weak. Use at least 6 characters.';
    }

    if (code == 'sign_in_canceled') {
      return 'Google sign-in was canceled.';
    }

    if (code == 'network-request-failed') {
      return 'Network error. Check your connection and try again.';
    }

    return error.message ?? fallback;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  void _onAuthStateChanged(User? user) {
    _status =
        user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    if (user == null) {
      _verifiedPhoneNumber = null;
    } else if ((_verifiedPhoneNumber ?? '').isEmpty &&
        (user.phoneNumber ?? '').isNotEmpty) {
      _verifiedPhoneNumber = user.phoneNumber;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      await _authService.signInWithEmailPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage =
          _messageFromAuthError(error, fallback: 'Email sign-in failed.');
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
      await _authService.registerWithEmailPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage =
          _messageFromAuthError(error, fallback: 'Registration failed.');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> requestPhoneOtp(String phoneNumber) async {
    if (_otpCooldownSeconds > 0) {
      _status = AuthStatus.error;
      _errorMessage =
          'Please wait $otpCooldownLabel before requesting a new OTP.';
      notifyListeners();
      return;
    }

    await _requestPhoneOtp(phoneNumber);
  }

  Future<void> resendPhoneOtp() async {
    if (!canResendOtp || _lastPhoneNumber == null) {
      return;
    }
    await _requestPhoneOtp(_lastPhoneNumber!, isResend: true);
  }

  Future<void> _requestPhoneOtp(
    String phoneNumber, {
    bool isResend = false,
  }) async {
    final normalized = phoneNumber.trim();
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized)) {
      _status = AuthStatus.error;
      _errorMessage =
          'Enter phone in international format, for example +919272078963.';
      notifyListeners();
      return;
    }

    _setBusy(true);
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    try {
      await _authService.requestPhoneOtp(
        phoneNumber: normalized,
        forceResendingToken: isResend ? _resendToken : null,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _lastPhoneNumber = normalized;
          _startOtpCooldown();
          if (!completer.isCompleted) {
            completer.complete();
          }
          notifyListeners();
        },
        onVerificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _verifiedPhoneNumber = normalized;
          _verificationId = null;
          _resendToken = null;
          _lastPhoneNumber = null;
          _otpTimer?.cancel();
          _otpCooldownSeconds = 0;
          if (!completer.isCompleted) {
            completer.complete();
          }
          notifyListeners();
        },
        onVerificationFailed: (error) {
          _status = AuthStatus.error;
          if (_isDeviceBlockedOtpError(error)) {
            _startOtpCooldown(seconds: _otpBlockedCooldownSeconds);
          }
          _errorMessage =
              _messageFromAuthError(error, fallback: 'OTP request failed.');
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

  Future<void> signInWithGoogle() async {
    _setBusy(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage =
          _messageFromAuthError(error, fallback: 'Google sign-in failed.');
      notifyListeners();
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Google sign-in failed.';
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
      _verifiedPhoneNumber =
          _lastPhoneNumber ?? _authService.currentPhoneNumber;
      _verificationId = null;
      _resendToken = null;
      _lastPhoneNumber = null;
      _otpTimer?.cancel();
      _otpCooldownSeconds = 0;
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage =
          _messageFromAuthError(error, fallback: 'Invalid OTP code.');
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    _setBusy(true);
    try {
      _verificationId = null;
      _resendToken = null;
      _lastPhoneNumber = null;
      _verifiedPhoneNumber = null;
      _otpTimer?.cancel();
      _otpCooldownSeconds = 0;
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
    _otpTimer?.cancel();
    super.dispose();
  }
}

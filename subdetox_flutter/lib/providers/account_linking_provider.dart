import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/linked_bank_models.dart';
import '../services/analysis_api_service.dart';
import 'auth_provider.dart';

enum AccountLinkingState {
  idle,
  loading,
  ready,
  saving,
  completed,
  error,
}

class AccountLinkingProvider extends ChangeNotifier {
  AccountLinkingProvider({required AnalysisApiService apiService})
      : _apiService = apiService;

  final AnalysisApiService _apiService;

  AuthProvider? _authProvider;
  bool _wasAuthenticated = false;
  bool _isBootstrapping = false;
  bool _needsOnboarding = false;

  AccountLinkingState _state = AccountLinkingState.idle;
  String? _errorMessage;
  String? _mobileNumber;
  List<LinkedBankInstitution> _linkedBanks = const [];
  Set<String> _selectedLinkRefNumbers = <String>{};

  AccountLinkingState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get mobileNumber => _mobileNumber;
  List<LinkedBankInstitution> get linkedBanks => _linkedBanks;
  bool get needsOnboarding => _needsOnboarding;
  bool get requiresMobileNumber => (_mobileNumber ?? '').isEmpty;
  bool get isLoading =>
      _state == AccountLinkingState.loading ||
      _state == AccountLinkingState.saving;
  bool get canSubmit =>
      _state == AccountLinkingState.ready &&
      _selectedLinkRefNumbers.isNotEmpty &&
      (_mobileNumber ?? '').isNotEmpty;

  int get selectedCount => _selectedLinkRefNumbers.length;

  List<LinkedBankAccount> get selectedAccounts {
    return _linkedBanks
        .expand((bank) => bank.accounts)
        .where((account) =>
            _selectedLinkRefNumbers.contains(account.linkRefNumber))
        .toList(growable: false);
  }

  bool isSelected(String linkRefNumber) {
    return _selectedLinkRefNumbers.contains(linkRefNumber);
  }

  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;

    if (!authProvider.isAuthenticated) {
      _wasAuthenticated = false;
      _resetForSignedOutUser();
      return;
    }

    if (!_wasAuthenticated) {
      _wasAuthenticated = true;
      unawaited(bootstrap());
    }
  }

  Future<void> bootstrap() async {
    if (_isBootstrapping) {
      return;
    }

    final authProvider = _authProvider;
    if (authProvider == null || !authProvider.isAuthenticated) {
      return;
    }

    _isBootstrapping = true;
    _state = AccountLinkingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await authProvider.getIdToken();
      if (idToken == null) {
        throw AnalysisApiException(
          'Missing auth token. Please sign in again.',
          statusCode: 401,
        );
      }

      final profile = await _apiService.fetchUserSelectionProfile(idToken);

      final resolvedMobile =
          _resolveMobileNumber(authProvider.activePhoneNumber) ??
              _resolveMobileNumber(profile.selectionMobileNumber);
      _mobileNumber = resolvedMobile;

      if (resolvedMobile == null) {
        _needsOnboarding = true;
        _linkedBanks = const [];
        _selectedLinkRefNumbers = <String>{};
        _state = AccountLinkingState.ready;
        notifyListeners();
        return;
      }

      await _loadLinkedAccounts(
        idToken: idToken,
        profile: profile,
        mobileNumber: resolvedMobile,
      );
    } on AnalysisApiException catch (error) {
      if (error.statusCode == 401) {
        await authProvider.signOut();
        return;
      }
      _state = AccountLinkingState.error;
      _errorMessage = error.message;
      _needsOnboarding = true;
      notifyListeners();
    } catch (_) {
      _state = AccountLinkingState.error;
      _errorMessage = 'Unable to load linked accounts right now. Please retry.';
      _needsOnboarding = true;
      notifyListeners();
    } finally {
      _isBootstrapping = false;
    }
  }

  Future<void> discoverLinkedAccountsForMobile(String mobileInput) async {
    final authProvider = _authProvider;
    if (authProvider == null || !authProvider.isAuthenticated) {
      return;
    }

    final resolvedMobile = _resolveMobileNumber(mobileInput);
    if (resolvedMobile == null) {
      _state = AccountLinkingState.ready;
      _errorMessage = 'Enter a valid mobile number (for example +919272078963).';
      _needsOnboarding = true;
      notifyListeners();
      return;
    }

    _state = AccountLinkingState.loading;
    _errorMessage = null;
    _needsOnboarding = true;
    notifyListeners();

    try {
      final idToken = await authProvider.getIdToken();
      if (idToken == null) {
        throw AnalysisApiException(
          'Missing auth token. Please sign in again.',
          statusCode: 401,
        );
      }

      final profile = await _apiService.fetchUserSelectionProfile(idToken);
      _mobileNumber = resolvedMobile;
      await _loadLinkedAccounts(
        idToken: idToken,
        profile: profile,
        mobileNumber: resolvedMobile,
      );
    } on AnalysisApiException catch (error) {
      if (error.statusCode == 401) {
        await authProvider.signOut();
        return;
      }
      _state = AccountLinkingState.error;
      _errorMessage = error.message;
      _needsOnboarding = true;
      notifyListeners();
    } catch (_) {
      _state = AccountLinkingState.error;
      _errorMessage = 'Unable to load linked accounts right now. Please retry.';
      _needsOnboarding = true;
      notifyListeners();
    }
  }

  void toggleSelection(String linkRefNumber) {
    if (_state != AccountLinkingState.ready) {
      return;
    }

    if (_selectedLinkRefNumbers.contains(linkRefNumber)) {
      _selectedLinkRefNumbers.remove(linkRefNumber);
    } else {
      _selectedLinkRefNumbers.add(linkRefNumber);
    }
    notifyListeners();
  }

  Future<void> saveSelection() async {
    if (!canSubmit) {
      return;
    }

    final authProvider = _authProvider;
    final resolvedMobile = _mobileNumber;
    if (authProvider == null ||
        !authProvider.isAuthenticated ||
        resolvedMobile == null) {
      return;
    }

    _state = AccountLinkingState.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await authProvider.getIdToken();
      if (idToken == null) {
        throw AnalysisApiException(
          'Missing auth token. Please sign in again.',
          statusCode: 401,
        );
      }

      final response = await _apiService.saveAccountSelection(
        idToken: idToken,
        mobileNumber: resolvedMobile,
        selectedLinkRefNumbers: _selectedLinkRefNumbers.toList(growable: false),
      );

      _selectedLinkRefNumbers = response.selectedAccounts
          .map((account) => account.linkRefNumber)
          .where((ref) => ref.isNotEmpty)
          .toSet();
      _needsOnboarding = false;
      _state = AccountLinkingState.completed;
      notifyListeners();
    } on AnalysisApiException catch (error) {
      if (error.statusCode == 401) {
        await authProvider.signOut();
        return;
      }
      _state = AccountLinkingState.error;
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _state = AccountLinkingState.error;
      _errorMessage = 'Unable to save account selection. Please retry.';
      notifyListeners();
    }
  }

  Future<void> retry() async {
    await bootstrap();
  }

  Future<void> _loadLinkedAccounts({
    required String idToken,
    required UserSelectionProfile profile,
    required String mobileNumber,
  }) async {
    final existingSelection = profile.hasSelectedAccountsForMobile(mobileNumber)
        ? profile.selectedLinkRefNumbers.toSet()
        : <String>{};

    final availability = await _apiService.fetchAccountAvailability(
      idToken: idToken,
      mobileNumber: mobileNumber,
    );

    _linkedBanks = availability.linkedBanks;
    final availableLinkRefs = _linkedBanks
        .expand((bank) => bank.accounts)
        .map((account) => account.linkRefNumber)
        .where((ref) => ref.isNotEmpty)
        .toSet();
    final preselected = existingSelection.intersection(availableLinkRefs);

    _selectedLinkRefNumbers =
        preselected.isNotEmpty ? preselected : _defaultSelection(_linkedBanks);
    _errorMessage = null;

    if (_linkedBanks.isEmpty) {
      _needsOnboarding = true;
      _state = AccountLinkingState.ready;
      notifyListeners();
      return;
    }

    if (preselected.isNotEmpty) {
      _needsOnboarding = false;
      _state = AccountLinkingState.completed;
      notifyListeners();
      return;
    }

    _needsOnboarding = true;
    _state = AccountLinkingState.ready;
    notifyListeners();
  }

  void _resetForSignedOutUser() {
    final hasState = _state != AccountLinkingState.idle ||
        _errorMessage != null ||
        _mobileNumber != null ||
        _linkedBanks.isNotEmpty ||
        _selectedLinkRefNumbers.isNotEmpty ||
        _needsOnboarding;

    _state = AccountLinkingState.idle;
    _errorMessage = null;
    _mobileNumber = null;
    _linkedBanks = const [];
    _selectedLinkRefNumbers = <String>{};
    _needsOnboarding = false;

    if (hasState) {
      notifyListeners();
    }
  }

  static Set<String> _defaultSelection(
      List<LinkedBankInstitution> linkedBanks) {
    final selected = <String>{};
    for (final bank in linkedBanks) {
      if (bank.accounts.isNotEmpty) {
        final linkRefNumber = bank.accounts.first.linkRefNumber;
        if (linkRefNumber.isNotEmpty) {
          selected.add(linkRefNumber);
        }
      }
    }
    return selected;
  }

  static String? _resolveMobileNumber(String? rawValue) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) {
      return null;
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return null;
    }

    if (value.startsWith('+')) {
      return '+$digits';
    }

    if (digits.length == 10) {
      return '+91$digits';
    }

    return '+$digits';
  }
}

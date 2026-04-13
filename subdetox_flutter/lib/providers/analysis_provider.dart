import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/analyze_transactions_response.dart';
import '../models/detected_subscription.dart';
import '../models/threat_level.dart';
import '../providers/auth_provider.dart';
import '../services/analysis_api_service.dart';

enum DashboardState { initial, analyzing, results, error }

class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider({required AnalysisApiService apiService})
      : _apiService = apiService;

  final AnalysisApiService _apiService;
  AuthProvider? _authProvider;
  bool _wasAuthenticated = false;
  bool _isLoadingLatest = false;

  DashboardState _state = DashboardState.initial;
  AnalyzeTransactionsResponse? _analysis;
  String? _errorMessage;
  final Set<String> _resolvedMerchantCodes = <String>{};

  DashboardState get state => _state;
  AnalyzeTransactionsResponse? get analysis => _analysis;
  String? get errorMessage => _errorMessage;

  void updateAuthProvider(
    AuthProvider authProvider, {
    required bool canLoadAnalysis,
  }) {
    _authProvider = authProvider;

    if (!authProvider.isAuthenticated || !canLoadAnalysis) {
      _wasAuthenticated = false;
      _resetForSignedOutUser();
      return;
    }

    if (!_wasAuthenticated) {
      _wasAuthenticated = true;
      unawaited(loadLatestAnalysis());
    }
  }

  Future<void> loadLatestAnalysis() async {
    if (_isLoadingLatest) {
      return;
    }

    final token = await _authProvider?.getIdToken();
    if (token == null) {
      _resetForSignedOutUser();
      return;
    }

    _isLoadingLatest = true;
    _state = DashboardState.analyzing;
    _errorMessage = null;
    notifyListeners();

    try {
      final latest = await _apiService.fetchLatestAnalysis(token);
      if (latest == null) {
        _analysis = null;
        _resolvedMerchantCodes.clear();
        _state = DashboardState.initial;
      } else {
        _analysis = latest;
        _resolvedMerchantCodes
          ..clear()
          ..addAll(
            latest.detectedSubscriptions
                .where((item) => item.resolved)
                .map((item) => item.merchantCode),
          );
        _state = DashboardState.results;
      }
      notifyListeners();
    } catch (error) {
      if (error is AnalysisApiException && error.statusCode == 401) {
        await _authProvider?.signOut();
        return;
      }
      _analysis = null;
      _errorMessage = error.toString();
      _state = DashboardState.error;
      notifyListeners();
    } finally {
      _isLoadingLatest = false;
    }
  }

  bool isResolved(String merchantCode) =>
      _resolvedMerchantCodes.contains(merchantCode);

  List<DetectedSubscription> get immediateActionRequired {
    return _filteredByThreat(ThreatLevel.high);
  }

  List<DetectedSubscription> get monitorClosely {
    return _filteredByThreat(ThreatLevel.medium);
  }

  List<DetectedSubscription> get knownSubscriptions {
    return _filteredByThreat(ThreatLevel.low);
  }

  List<DetectedSubscription> get resolvedSubscriptions {
    final all = _analysis?.detectedSubscriptions ?? <DetectedSubscription>[];
    return all.where((item) => isResolved(item.merchantCode)).toList();
  }

  int get activeDetectedCount {
    final all = _analysis?.detectedSubscriptions ?? <DetectedSubscription>[];
    return all.where((item) => !isResolved(item.merchantCode)).length;
  }

  int get resolvedCount => _resolvedMerchantCodes.length;

  double get activeMonthlyLeakage {
    final all = _analysis?.detectedSubscriptions ?? <DetectedSubscription>[];
    return all
        .where((item) => !isResolved(item.merchantCode))
        .fold<double>(0, (sum, item) => sum + item.estimatedMonthlyAmount);
  }

  Future<void> analyze() async {
    _state = DashboardState.analyzing;
    _errorMessage = null;
    _analysis = null;
    notifyListeners();

    try {
      final token = await _authProvider?.getIdToken();
      if (token == null) {
        throw AnalysisApiException(
          'Missing auth token. Please sign in again.',
          statusCode: 401,
        );
      }

      _analysis = await _apiService.analyzeTransactions(token);
      _resolvedMerchantCodes
        ..clear()
        ..addAll(
          _analysis!.detectedSubscriptions
              .where((item) => item.resolved)
              .map((item) => item.merchantCode),
        );
      _state = DashboardState.results;
      notifyListeners();
    } catch (error) {
      if (error is AnalysisApiException && error.statusCode == 401) {
        await _authProvider?.signOut();
      }
      _errorMessage = error.toString();
      _state = DashboardState.error;
      notifyListeners();
    }
  }

  Future<void> revokeMandate(DetectedSubscription subscription) async {
    final token = await _authProvider?.getIdToken();
    if (token == null) {
      throw AnalysisApiException(
        'Missing auth token. Please sign in again.',
        statusCode: 401,
      );
    }

    try {
      await _apiService.revokeMandate(
        idToken: token,
        merchantCode: subscription.merchantCode,
      );
    } on AnalysisApiException catch (error) {
      if (error.statusCode == 401) {
        await _authProvider?.signOut();
      }
      rethrow;
    }

    _resolvedMerchantCodes.add(subscription.merchantCode);
    notifyListeners();
  }

  void markResolved(DetectedSubscription subscription) {
    _resolvedMerchantCodes.add(subscription.merchantCode);
    notifyListeners();
  }

  List<DetectedSubscription> _filteredByThreat(ThreatLevel level) {
    final all = _analysis?.detectedSubscriptions ?? <DetectedSubscription>[];
    return all.where((item) => item.threatLevel == level).toList();
  }

  void _resetForSignedOutUser() {
    final hasDashboardState = _state != DashboardState.initial ||
        _analysis != null ||
        _errorMessage != null ||
        _resolvedMerchantCodes.isNotEmpty;

    if (!hasDashboardState) {
      return;
    }

    _state = DashboardState.initial;
    _analysis = null;
    _errorMessage = null;
    _resolvedMerchantCodes.clear();
    notifyListeners();
  }
}

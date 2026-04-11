import 'package:flutter/foundation.dart';

import '../models/analyze_transactions_response.dart';
import '../models/detected_subscription.dart';
import '../models/threat_level.dart';
import '../services/analysis_api_service.dart';

enum DashboardState { initial, analyzing, results, error }

class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider({required AnalysisApiService apiService}) : _apiService = apiService;

  final AnalysisApiService _apiService;

  DashboardState _state = DashboardState.initial;
  AnalyzeTransactionsResponse? _analysis;
  String? _errorMessage;
  final Set<String> _resolvedMerchantCodes = <String>{};

  DashboardState get state => _state;
  AnalyzeTransactionsResponse? get analysis => _analysis;
  String? get errorMessage => _errorMessage;

  bool isResolved(String merchantCode) => _resolvedMerchantCodes.contains(merchantCode);

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
    _resolvedMerchantCodes.clear();
    notifyListeners();

    try {
      _analysis = await _apiService.analyzeTransactions();
      _state = DashboardState.results;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      _state = DashboardState.error;
      notifyListeners();
    }
  }

  void markResolved(DetectedSubscription subscription) {
    _resolvedMerchantCodes.add(subscription.merchantCode);
    notifyListeners();
  }

  List<DetectedSubscription> _filteredByThreat(ThreatLevel level) {
    final all = _analysis?.detectedSubscriptions ?? <DetectedSubscription>[];
    return all.where((item) => item.threatLevel == level).toList();
  }
}

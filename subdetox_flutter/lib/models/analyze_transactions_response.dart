import 'detected_subscription.dart';

class AnalyzeTransactionsResponse {
  const AnalyzeTransactionsResponse({
    required this.generatedAt,
    required this.scannedTransactionCount,
    required this.detectedSubscriptions,
    required this.totalMonthlyLeakage,
    required this.currency,
    required this.analysisSource,
    this.geminiError,
  });

  final DateTime generatedAt;
  final int scannedTransactionCount;
  final List<DetectedSubscription> detectedSubscriptions;
  final double totalMonthlyLeakage;
  final String currency;
  final String analysisSource;
  final String? geminiError;

  factory AnalyzeTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final subscriptions =
        (json['detected_subscriptions'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DetectedSubscription.fromJson)
            .toList();

    return AnalyzeTransactionsResponse(
      generatedAt: DateTime.parse((json['generated_at'] ?? '') as String),
      scannedTransactionCount: _parseInt(json['scanned_transaction_count']),
      detectedSubscriptions: subscriptions,
      totalMonthlyLeakage: _parseNum(json['total_monthly_leakage']),
      currency: (json['currency'] ?? 'INR') as String,
      analysisSource: (json['analysis_source'] ?? 'RULES_ENGINE') as String,
      geminiError: json['gemini_error'] as String?,
    );
  }

  static double _parseNum(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

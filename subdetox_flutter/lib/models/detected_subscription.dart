import 'threat_level.dart';

class DetectedSubscription {
  const DetectedSubscription({
    required this.merchantCode,
    required this.displayName,
    required this.sampleNarration,
    required this.threatLevel,
    required this.confidenceScore,
    required this.occurrenceCount,
    required this.averageAmount,
    required this.estimatedMonthlyAmount,
    required this.firstSeen,
    required this.lastChargedOn,
    required this.reasoning,
    required this.resolved,
  });

  final String merchantCode;
  final String displayName;
  final String sampleNarration;
  final ThreatLevel threatLevel;
  final double confidenceScore;
  final int occurrenceCount;
  final double averageAmount;
  final double estimatedMonthlyAmount;
  final DateTime firstSeen;
  final DateTime lastChargedOn;
  final String reasoning;
  final bool resolved;

  factory DetectedSubscription.fromJson(Map<String, dynamic> json) {
    return DetectedSubscription(
      merchantCode: (json['merchant_code'] ?? '') as String,
      displayName: (json['display_name'] ?? '') as String,
      sampleNarration: (json['sample_narration'] ?? '') as String,
      threatLevel: ThreatLevelParsing.fromString(
        (json['threat_level'] ?? 'UNKNOWN') as String,
      ),
      confidenceScore: _parseNum(json['confidence_score']),
      occurrenceCount: _parseInt(json['occurrence_count']),
      averageAmount: _parseNum(json['average_amount']),
      estimatedMonthlyAmount: _parseNum(json['estimated_monthly_amount']),
      firstSeen: DateTime.parse((json['first_seen'] ?? '') as String),
      lastChargedOn: DateTime.parse((json['last_charged_on'] ?? '') as String),
      reasoning: (json['reasoning'] ?? '') as String,
      resolved: (json['resolved'] ?? false) as bool,
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

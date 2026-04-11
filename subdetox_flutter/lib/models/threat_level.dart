enum ThreatLevel { high, medium, low, unknown }

extension ThreatLevelParsing on ThreatLevel {
  static ThreatLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'HIGH':
        return ThreatLevel.high;
      case 'MEDIUM':
        return ThreatLevel.medium;
      case 'LOW':
        return ThreatLevel.low;
      default:
        return ThreatLevel.unknown;
    }
  }

  String get label {
    switch (this) {
      case ThreatLevel.high:
        return 'HIGH';
      case ThreatLevel.medium:
        return 'MEDIUM';
      case ThreatLevel.low:
        return 'LOW';
      case ThreatLevel.unknown:
        return 'UNKNOWN';
    }
  }
}

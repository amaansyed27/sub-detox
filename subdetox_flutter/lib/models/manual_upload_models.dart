class ManualUploadResponse {
  const ManualUploadResponse({
    required this.uploadId,
    required this.status,
    required this.recordsParsed,
    required this.estimatedSubscriptions,
    required this.nextSteps,
  });

  final String uploadId;
  final String status;
  final int recordsParsed;
  final int estimatedSubscriptions;
  final List<String> nextSteps;

  factory ManualUploadResponse.fromJson(Map<String, dynamic> json) {
    final next = (json['nextSteps'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(growable: false);

    return ManualUploadResponse(
      uploadId: (json['uploadId'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      recordsParsed: _parseInt(json['recordsParsed']),
      estimatedSubscriptions: _parseInt(json['estimatedSubscriptions']),
      nextSteps: next,
    );
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

class SupportTicketResponse {
  const SupportTicketResponse({
    required this.ticketId,
    required this.status,
    required this.message,
  });

  final String ticketId;
  final String status;
  final String message;

  factory SupportTicketResponse.fromJson(Map<String, dynamic> json) {
    return SupportTicketResponse(
      ticketId: (json['ticketId'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      message: (json['message'] ?? '') as String,
    );
  }
}

class ServiceRequestResponse {
  const ServiceRequestResponse({
    required this.requestId,
    required this.status,
    required this.message,
  });

  final String requestId;
  final String status;
  final String message;

  factory ServiceRequestResponse.fromJson(Map<String, dynamic> json) {
    return ServiceRequestResponse(
      requestId: (json['requestId'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      message: (json['message'] ?? '') as String,
    );
  }
}

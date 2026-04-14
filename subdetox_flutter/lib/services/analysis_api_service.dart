import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analyze_transactions_response.dart';
import '../models/chat_assist_models.dart';
import '../models/linked_bank_models.dart';
import '../models/manual_upload_models.dart';
import 'api_config.dart';

class AnalysisApiService {
  const AnalysisApiService();

  Future<UserSelectionProfile> fetchUserSelectionProfile(String idToken) async {
    final response = await http.get(
      ApiConfig.meUri,
      headers: ApiConfig.authHeaders(idToken),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UserSelectionProfile.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to fetch user profile. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<AccountAvailabilityResponse> fetchAccountAvailability({
    required String idToken,
    required String mobileNumber,
  }) async {
    final response = await http.post(
      ApiConfig.accountAvailabilityUri,
      headers: ApiConfig.authHeaders(idToken),
      body: jsonEncode({'mobileNumber': mobileNumber}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AccountAvailabilityResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to fetch linked bank accounts. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<AccountSelectionResponse> saveAccountSelection({
    required String idToken,
    required String mobileNumber,
    required List<String> selectedLinkRefNumbers,
  }) async {
    final response = await http.post(
      ApiConfig.accountSelectionUri,
      headers: ApiConfig.authHeaders(idToken),
      body: jsonEncode(
        {
          'mobileNumber': mobileNumber,
          'selectedLinkRefNumbers': selectedLinkRefNumbers,
        },
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AccountSelectionResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to save selected accounts. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<AnalyzeTransactionsResponse?> fetchLatestAnalysis(
      String idToken) async {
    final response = await http.get(
      ApiConfig.latestAnalysisUri,
      headers: ApiConfig.authHeaders(idToken),
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalyzeTransactionsResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to fetch latest analysis. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<AnalyzeTransactionsResponse> analyzeTransactions(
      String idToken) async {
    final response = await http.post(
      ApiConfig.analyzeTransactionsUri,
      headers: ApiConfig.authHeaders(idToken),
      body: '{}',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalyzeTransactionsResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to analyze transactions. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<void> revokeMandate({
    required String idToken,
    required String merchantCode,
  }) async {
    final response = await http.post(
      ApiConfig.revokeMandateUri,
      headers: ApiConfig.authHeaders(idToken),
      body: jsonEncode({'merchant_code': merchantCode}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw AnalysisApiException(
      'Failed to revoke mandate. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<ManualUploadResponse> submitManualUpload({
    required String idToken,
    required String fileName,
    required String content,
    required String uploadMethod,
  }) async {
    final response = await http.post(
      ApiConfig.manualUploadUri,
      headers: ApiConfig.authHeaders(idToken),
      body: jsonEncode(
        {
          'fileName': fileName,
          'content': content,
          'uploadMethod': uploadMethod,
        },
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ManualUploadResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to submit manual upload. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<ChatAssistResponse> askGeminiAssistant({
    required String idToken,
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final response = await http.post(
      ApiConfig.chatAssistUri,
      headers: ApiConfig.authHeaders(idToken),
      body: jsonEncode(
        {
          'message': message,
          'history': history,
        },
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatAssistResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to get assistant reply. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<SupportTicketResponse> createSupportTicket({
    required String idToken,
    required String title,
    required String description,
    String category = 'BANKING_HELP',
    String priority = 'MEDIUM',
  }) async {
    final response = await http.post(
      ApiConfig.chatTicketsUri,
      headers: ApiConfig.authHeaders(idToken),
      body: jsonEncode(
        {
          'title': title,
          'description': description,
          'category': category,
          'priority': priority,
        },
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return SupportTicketResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to create support ticket. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  Future<ServiceRequestResponse> createServiceRequest({
    required String idToken,
    required String requestType,
    required String details,
    String? accountLinkRefNumber,
  }) async {
    final response = await http.post(
      ApiConfig.chatRequestsUri,
      headers: ApiConfig.authHeaders(idToken),
      body: jsonEncode(
        {
          'requestType': requestType,
          'details': details,
          'accountLinkRefNumber': accountLinkRefNumber,
        },
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ServiceRequestResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to create service request. '
      'Status ${response.statusCode}: ${response.body}',
      statusCode: response.statusCode,
    );
  }
}

class AnalysisApiException implements Exception {
  AnalysisApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

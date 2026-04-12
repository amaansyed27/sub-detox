import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analyze_transactions_response.dart';
import 'api_config.dart';

class AnalysisApiService {
  const AnalysisApiService();

  Future<AnalyzeTransactionsResponse> analyzeTransactions(String idToken) async {
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
}

class AnalysisApiException implements Exception {
  AnalysisApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

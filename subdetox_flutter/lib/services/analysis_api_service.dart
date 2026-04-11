import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analyze_transactions_response.dart';
import 'api_config.dart';

class AnalysisApiService {
  const AnalysisApiService();

  Future<AnalyzeTransactionsResponse> analyzeTransactions() async {
    final response = await http.post(
      ApiConfig.analyzeTransactionsUri,
      headers: const {'Content-Type': 'application/json'},
      body: '{}',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalyzeTransactionsResponse.fromJson(decoded);
    }

    throw AnalysisApiException(
      'Failed to analyze transactions. '
      'Status ${response.statusCode}: ${response.body}',
    );
  }
}

class AnalysisApiException implements Exception {
  AnalysisApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

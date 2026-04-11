import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/analysis_provider.dart';
import 'screens/dashboard_screen.dart';
import 'services/analysis_api_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SubDetoxApp());
}

class SubDetoxApp extends StatelessWidget {
  const SubDetoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AnalysisProvider>(
          create: (_) => AnalysisProvider(apiService: AnalysisApiService()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SubDetox',
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}

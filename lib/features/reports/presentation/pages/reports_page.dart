import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Center(
        child: Text('Reportes — Sprint 8', style: AppTextStyles.headlineMedium),
      ),
    );
  }
}

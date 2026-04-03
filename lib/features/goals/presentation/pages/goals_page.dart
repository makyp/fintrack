import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metas')),
      body: Center(
        child: Text('Metas de Ahorro — Sprint 6', style: AppTextStyles.headlineMedium),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: Text('Perfil — Sprint 10', style: AppTextStyles.headlineMedium),
      ),
    );
  }
}

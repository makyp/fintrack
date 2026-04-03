import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/onboarding_service.dart';
import '../widgets/onboarding_step_indicator.dart';
import 'onboarding_step_cash.dart';
import 'onboarding_step_accounts.dart';
import 'onboarding_step_cards.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isSaving = false;

  // Shared data collected across steps
  double cashBalance = 0;
  final List<Map<String, dynamic>> bankAccounts = [];
  final List<Map<String, dynamic>> cards = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.uid;
    if (userId == null) {
      context.go('/login');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await getIt<OnboardingService>().completeOnboarding(
        userId: userId,
        cashBalance: cashBalance,
        bankAccounts: bankAccounts,
        cards: cards,
      );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _skipOnboarding() async {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.uid;
    if (userId == null) {
      context.go('/login');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await getIt<OnboardingService>().completeOnboarding(
        userId: userId,
        cashBalance: 0,
        bankAccounts: const [],
        cards: const [],
      );
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) context.go('/');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  OnboardingStepCash(
                    onBalanceChanged: (v) => cashBalance = v,
                  ),
                  OnboardingStepAccounts(
                    accounts: bankAccounts,
                  ),
                  OnboardingStepCards(
                    cards: cards,
                  ),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding,
        vertical: AppDimensions.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'FinTrack',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _isSaving ? null : _skipOnboarding,
                child: Text(
                  'Omitir',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          OnboardingStepIndicator(current: _currentStep, total: _totalSteps),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _previousStep,
                child: const Text('Atrás'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppDimensions.md),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextStep,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : Text(
                      _currentStep < _totalSteps - 1 ? 'Continuar' : 'Comenzar',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

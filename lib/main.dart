import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'core/analytics/analytics_service.dart';
import 'core/cubit/theme_cubit.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/widget_service.dart';
import 'core/theme/app_color_scheme.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/budgets/data/budget_alert_service.dart';
import 'features/budgets/presentation/cubit/budgets_cubit.dart';
import 'features/categories/presentation/cubit/categories_cubit.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Offline-first: keep the whole Firestore dataset cached locally so the app
  // opens and works with no connection (mobile enables persistence by default,
  // but the default cache is capped and web starts disabled — make it explicit).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await configureDependencies();
  await initializeDateFormatting('es', null);
  Intl.defaultLocale = 'es';
  await LocalNotificationService.initialize();

  if (!kIsWeb) {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  }

  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const FimakypApp());
}

class FimakypApp extends StatefulWidget {
  const FimakypApp({super.key});

  @override
  State<FimakypApp> createState() => _FimakypAppState();
}

class _FimakypAppState extends State<FimakypApp> {
  late final AuthBloc _authBloc;
  late final ThemeCubit _themeCubit;
  late final GoRouter _routerConfig;
  String? _authedUid;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthStarted());
    _themeCubit = ThemeCubit();
    _routerConfig = AppRouter.buildRouter();

    _authBloc.stream.listen((state) {
      if (state.isAuthenticated && state.user != null) {
        AnalyticsService.setUser(state.user!.uid);
        // On first authentication (login or session restore), reschedule
        // reminders and refresh the home widget with today's data.
        if (_authedUid != state.user!.uid) {
          _authedUid = state.user!.uid;
          unawaited(LocalNotificationService.scheduleFromString(state.user!.reminderTime));
          if (!kIsWeb) unawaited(WidgetService.update(state.user!.uid));
          // Load the category catalog app-wide: everything that renders a
          // movement resolves its label through CategoryRegistry.
          unawaited(getIt<CategoriesCubit>().watchCategories(state.user!.uid));
          unawaited(getIt<BudgetsCubit>().watchBudgets(state.user!.uid));
          // Catch a cap that was blown while the app was closed (a recurring
          // charge, a shared household expense).
          unawaited(getIt<BudgetAlertService>().check(state.user!.uid));
        }
      } else if (state.isUnauthenticated) {
        AnalyticsService.clearUser();
        _authedUid = null;
        getIt<CategoriesCubit>().clear();
        getIt<BudgetsCubit>().clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, AppColorSchemeType>(
        builder: (context, schemeType) {
          final palette = AppColorPalette.fromType(schemeType);
          return MaterialApp.router(
            title: 'Fimakyp',
            theme: AppTheme.light(palette),
            themeMode: ThemeMode.light,
            routerConfig: _routerConfig,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/providers/service_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/home/employee_shell.dart';
import 'l10n/generated/app_localizations.dart';

class ShaqoNetEmployeeApp extends ConsumerStatefulWidget {
  const ShaqoNetEmployeeApp({super.key});

  @override
  ConsumerState<ShaqoNetEmployeeApp> createState() =>
      _ShaqoNetEmployeeAppState();
}

class _ShaqoNetEmployeeAppState extends ConsumerState<ShaqoNetEmployeeApp> {
  late final _routerRefresh = ValueNotifier<int>(0);
  late final _router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _routerRefresh,
    redirect: (context, state) {
      final isSignedIn = ref.read(currentSessionProvider);
      final isLogin = state.matchedLocation == '/login';

      if (!isSignedIn && !isLogin) return '/login';
      if (isSignedIn && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const EmployeeShell(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    _routerRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isSignedInProvider, (previous, next) => _routerRefresh.value++);
    ref.listen(demoSessionProvider, (previous, next) => _routerRefresh.value++);
    return MaterialApp.router(
      title: 'ShaqoNet',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.orangeHours,
          surface: AppColors.cardBackground,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: AppColors.darkText,
              displayColor: AppColors.darkText,
            ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.cardBackground,
            minimumSize: const Size(72, 52),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

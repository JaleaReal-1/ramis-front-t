import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/dashboard/dashboard_screen.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/features/login/login_provider.dart';
import 'package:sistema_ocs/features/login/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: OCSApp()));
}

class OCSApp extends ConsumerWidget {
  const OCSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authNotifierProvider);
    final navigatorKey = ref.watch(navigatorKeyProvider);

    ref.listen<AuthStatus>(authNotifierProvider, (previous, next) {
      if (next == AuthStatus.unauthenticated && previous == AuthStatus.authenticated) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });

    final Widget homeScreen = authStatus == AuthStatus.authenticated
        ? const DashboardScreen()
        : const LoginScreen();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Sistema OCS',
      theme: AppTheme.lightTheme,
      home: homeScreen,
    );
  }
}

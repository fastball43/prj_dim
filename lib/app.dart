import 'package:flutter/material.dart';
import 'data/app_database.dart';
import 'core/database/profile_dao.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/dashboard_screen.dart';

class DimApp extends StatelessWidget {
  const DimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뇌 건강 지킴이',
      theme: AppTheme.light,
      home: const _StartRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _StartRouter extends StatelessWidget {
  const _StartRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _loadProfile(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.data == null
            ? const OnboardingScreen()
            : const DashboardScreen();
      },
    );
  }

  Future<UserProfile?> _loadProfile() async {
    final db = await AppDatabase.instance;
    return ProfileDao(db).get();
  }
}

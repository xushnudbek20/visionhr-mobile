import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_mobile/features/auth/presentation/login_provider.dart';
import 'package:hr_mobile/features/auth/presentation/login_screen.dart';
import 'package:hr_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hr_mobile/shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Vision HR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.isAuthenticated 
          ? const DashboardScreen() 
          : const LoginScreen(),
    );
  }
}

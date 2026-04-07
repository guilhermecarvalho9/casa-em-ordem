import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/app/providers/app_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/house_setup_page.dart';
import 'features/app/pages/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: CasaEmOrdemApp()));
}

class CasaEmOrdemApp extends ConsumerWidget {
  const CasaEmOrdemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);

    return MaterialApp(
      title: 'Casa em Ordem',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.loading) {
      return const _SplashScreen();
    }

    if (authState.user == null) {
      return const LoginPage();
    }

    if (authState.currentHouse == null) {
      return const HouseSetupPage();
    }

    return const MainScaffold();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A9D90), Color(0xFF3BB5A8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFF2A9D90),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

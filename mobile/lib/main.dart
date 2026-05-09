import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/version_check_service.dart';
import 'core/services/notification_service.dart';
import 'features/bills/providers/bills_provider.dart';
import 'features/app/providers/app_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/house_setup_page.dart';
import 'features/auth/pages/expired_access_page.dart';
import 'features/app/pages/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  MobileAds.instance.initialize();
  await initializeDateFormatting('pt_BR');
  await initializeDateFormatting('en_US');
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: HomioApp()));
}

class HomioApp extends ConsumerWidget {
  const HomioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);

    return MaterialApp(
      title: 'Homio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  bool _versionChecked = false;
  bool _notificationsScheduled = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final appState = ref.watch(appProvider);

    if (authState.loading) {
      return const _SplashScreen();
    }

    if (authState.user == null) {
      _versionChecked = false;
      _notificationsScheduled = false;
      return const LoginPage();
    }

    if (authState.accessExpired) {
      return const ExpiredAccessPage();
    }

    if (authState.currentHouse == null) {
      return const HouseSetupPage();
    }

    if (!_versionChecked) {
      _versionChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          checkAndShowUpdateDialog(context, appState.language);
        }
      });
    }

    // Reschedule notifications for all unpaid bills once after login
    if (!_notificationsScheduled) {
      final billsAsync = ref.watch(billsProvider);
      billsAsync.whenData((bills) {
        if (!_notificationsScheduled) {
          _notificationsScheduled = true;
          final unpaid = bills.where((b) => !b.paid).toList();
          NotificationService.instance.rescheduleAll(
            unpaid.map((b) => (id: b.id, title: b.title, dueDate: b.dueDate)).toList(),
            language: appState.language,
          );
        }
      });
    }

    return const MainScaffold();
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _float;
  late final AnimationController _dots;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoY;
  late final Animation<double> _textY;
  late final Animation<double> _textOpacity;
  late final Animation<double> _tagOpacity;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _logoScale = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.52, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.22, curve: Curves.easeIn),
      ),
    );
    _logoY = Tween(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _float, curve: Curves.easeInOut),
    );
    _textY = Tween(begin: 22.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.42, 0.70, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.42, 0.70, curve: Curves.easeIn),
      ),
    );
    _tagOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.64, 0.90, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF2A9D90);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0C1E1D), const Color(0xFF152B29), const Color(0xFF0C1E1D)]
                : [const Color(0xFFF3FCFB), const Color(0xFFE6F7F6), const Color(0xFFF3FCFB)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -90, right: -55,
              child: _bgCircle(220, primary, isDark ? 0.10 : 0.07),
            ),
            Positioned(
              bottom: 50, left: -70,
              child: _bgCircle(190, primary, isDark ? 0.07 : 0.05),
            ),
            Positioned(
              top: 200, left: -20,
              child: _bgCircle(70, primary, isDark ? 0.06 : 0.04),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo: bounce-in + continuous float
                  AnimatedBuilder(
                    animation: Listenable.merge([_intro, _float]),
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _logoY.value),
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B3634) : Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.30),
                                  blurRadius: 48,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/logo-homio-fundo-transparente.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // App name slide-up
                  AnimatedBuilder(
                    animation: _intro,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _textY.value),
                      child: Opacity(
                        opacity: _textOpacity.value.clamp(0.0, 1.0),
                        child: Text(
                          'Homio',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0C1E1D),
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline fade-in
                  AnimatedBuilder(
                    animation: _intro,
                    builder: (_, __) => Opacity(
                      opacity: _tagOpacity.value.clamp(0.0, 1.0),
                      child: Text(
                        'Sua casa, em ordem.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Staggered bouncing dots at bottom
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _dots,
                builder: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final phase = (_dots.value - i * 0.30) % 1.0;
                    final bounce =
                        (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2)
                            .clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Opacity(
                        opacity: 0.25 + 0.75 * bounce,
                        child: Transform.translate(
                          offset: Offset(0, -8 * bounce),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bgCircle(double size, Color color, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      );
}

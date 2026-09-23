import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/settings_service.dart';

class OnboarderApp extends StatelessWidget {
  const OnboarderApp({super.key});

  static Color brandTeal = const Color(0xFF0D9488);
  static Color brandTealDark = const Color(0xFF115E59);
  static Color brandTealLight = const Color(0xFFCCFBF1);
  static const Color ink = Color(0xFF111418);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F6F8);
  static String appName = 'MarketGO Onboarder';
  static String fontFamily = '';
  static bool maintenanceMode = false;
  static String currencySymbol = '₦';

  /// Apply branding loaded from the admin-managed public settings.
  static void applyBranding(AppSettings s) {
    if (s.brandColor != const Color(0xFF0D9488)) brandTeal = s.brandColor;
    if (s.brandDarkColor != const Color(0xFF115E59)) brandTealDark = s.brandDarkColor;
    if (s.brandLightColor != const Color(0xFFCCFBF1)) brandTealLight = s.brandLightColor;
    appName = s.appName;
    if (s.fontFamily.isNotEmpty) fontFamily = s.fontFamily;
    if (s.currencySymbol.isNotEmpty) currencySymbol = s.currencySymbol;
    maintenanceMode = s.maintenanceMode;
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandTeal,
      primary: brandTeal,
      secondary: brandTealDark,
    );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        textTheme: base.textTheme
            .apply(
              bodyColor: ink,
              displayColor: ink,
            )
            .apply(fontFamily: fontFamily.isEmpty ? null : fontFamily),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: surfaceMuted,
          labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w700),
          side: const BorderSide(color: Color(0xFFE4E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: brandTeal,
            disabledBackgroundColor: const Color(0xFFB9C0C7),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandTealDark,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFCFD6DC)),
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: brandTealDark),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFB),
          hintStyle: const TextStyle(color: Color(0xFF99A1AA)),
          labelStyle: const TextStyle(color: Color(0xFF5B6470)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: brandTeal, width: 1.6),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: brandTealLight,
          elevation: 3,
          shadowColor: const Color(0x55000000),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? brandTealDark
                  : const Color(0xFF7C8594),
              size: 24,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: states.contains(WidgetState.selected)
                  ? brandTealDark
                  : const Color(0xFF7C8594),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: brandTeal,
          foregroundColor: Colors.white,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFEAF0EE),
          thickness: 1,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

/// Watches public settings and swaps the whole app to a maintenance screen
/// whenever the admin enables platform-wide maintenance mode.
class MaintenanceGate extends StatefulWidget {
  const MaintenanceGate({super.key, required this.child});

  final Widget child;

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate> {
  Timer? _timer;
  bool maintenance = OnboarderApp.maintenanceMode;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final s = await SettingsService.fetchSettings();
    if (!mounted) return;
    final on = s.maintenanceMode;
    if (on != maintenance) {
      setState(() => maintenance = on);
    }
  }

  @override
  Widget build(BuildContext context) {
    return maintenance ? const MaintenanceScreen() : widget.child;
  }
}

/// Full-screen notice shown while the platform is under maintenance.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: OnboarderApp.brandTealLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(Icons.build_circle_rounded,
                      size: 46, color: OnboarderApp.brandTealDark),
                ),
                const SizedBox(height: 24),
                Text(
                  '${OnboarderApp.appName} is under maintenance',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  "We're performing scheduled maintenance right now. "
                  'Please check back shortly — we will be back up soon.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
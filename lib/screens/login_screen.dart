import 'package:flutter/material.dart';
import '../app.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../widgets/route_animation.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';

/// Intro / login screen for the MarketGO Onboarder (field onboarding) app.
///
/// Premium split layout like the rider app: a teal gradient hero band with the
/// brand mark and live animated route, and a light rounded panel overlapping
/// the lower edge holding the sign-in form plus a "create account" link.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _keepSignedIn = true;
  bool _loading = false;
  String? _error;
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    SettingsService.fetchSettings().then((s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password to continue.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await OnboarderSession.instance.signIn(email, password);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const OnboarderHome()),
    );
  }

  void _useDemo(String email) {
    _emailController.text = email;
    _passwordController.text = 'Onboard@123';
  }

  /// Opens the phone/OTP sign-in flow. The OTP screen verifies the code with
  /// the backend and enters the authenticated session before navigating on.
  void _openOtp() {
    FocusScope.of(context).unfocus();
    final nav = Navigator.of(context);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(
          onVerified: () {
            nav.pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const OnboarderHome()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  /// Bypasses the server entirely and enters an authenticated demo session.
  void _signInTest() {
    FocusScope.of(context).unfocus();
    OnboarderSession.instance.enterDemo();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const OnboarderHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: OnboarderApp.surfaceMuted,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.46,
            child: const _HeroBand(markIcon: Icons.handshake_rounded),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          tooltip: 'Back',
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.10),
                  _HeroContent(settings: _settings),
                  const SizedBox(height: 28),
                  Container(
                    width: size.width,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: const BoxDecoration(
                      color: OnboarderApp.surfaceMuted,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoginCard(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscure: _obscure,
                          onToggleObscure: () =>
                              setState(() => _obscure = !_obscure),
                          keepSignedIn: _keepSignedIn,
                          onToggleKeep: (v) =>
                              setState(() => _keepSignedIn = v),
                          error: _error,
                          loading: _loading,
                          onSignIn: _signIn,
                          onTestMode: _signInTest,
                          onOpenOtp: _openOtp,
                          onUseDemo: _useDemo,
                          appName: _settings?.appName ?? 'MarketGO',
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('New to MarketGO?',
                                style: theme.textTheme.bodyMedium),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignupScreen(),
                                ),
                              ),
                              child: const Text('Create account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBand extends StatelessWidget {
  const _HeroBand({required this.markIcon});

  final IconData markIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3D3A), Color(0xFF0D9488)],
        ),
      ),
      child: AnimatedRouteBackdrop(markIcon: markIcon),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.settings});

  final AppSettings? settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BrandTile(settings: settings),
        const SizedBox(height: 20),
        const Text(
          'Field onboarding, done right',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Onboard vendors and riders on the go. Earn commission from every account you open.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 15, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.settings});

  final AppSettings? settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: settings?.logoUrl.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.network(
                settings!.logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.handshake_rounded,
                  size: 52,
                  color: OnboarderApp.brandTeal,
                ),
              ),
            )
          : Icon(Icons.handshake_rounded,
              size: 52, color: OnboarderApp.brandTeal),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.onToggleObscure,
    required this.keepSignedIn,
    required this.onToggleKeep,
    required this.error,
    required this.loading,
    required this.onSignIn,
    required this.onTestMode,
    required this.onOpenOtp,
    required this.onUseDemo,
    required this.appName,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool keepSignedIn;
  final ValueChanged<bool> onToggleKeep;
  final String? error;
  final bool loading;
  final VoidCallback onSignIn;
  final VoidCallback onTestMode;
  final VoidCallback onOpenOtp;
  final ValueChanged<String> onUseDemo;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Sign in', style: theme.textTheme.headlineMedium),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: OnboarderApp.brandTealDark,
              ),
              child: const Text('Forgot password?'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Use your $appName onboarder account to continue.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OnboarderApp.brandTealLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: OnboarderApp.brandTeal.withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.flash_on_rounded,
                  color: OnboarderApp.brandTealDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No server? Explore the full app now',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: OnboarderApp.brandTealDark,
                      ),
                    ),
                    Text(
                      'Skips sign-in entirely for testing.',
                      style: TextStyle(
                        color: OnboarderApp.brandTealDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTestMode,
                style: TextButton.styleFrom(
                  foregroundColor: OnboarderApp.brandTealDark,
                ),
                child: const Text('Test mode'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Text('Demo onboarder', style: theme.textTheme.bodySmall),
            const Spacer(),
            ActionChip(
              avatar: Icon(Icons.bolt,
                  size: 16, color: OnboarderApp.brandTeal),
              label: const Text('Use demo'),
              backgroundColor: OnboarderApp.brandTealLight,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: OnboarderApp.brandTealDark,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onPressed: () => onUseDemo('onboarder@marketgo.com'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'you@marketgo.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passwordController,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => onSignIn(),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              tooltip: obscure ? 'Show password' : 'Hide password',
            ),
          ),
        ),

        if (error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFB3261E), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFF8F1D16),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),
        Row(
          children: [
            Switch(
              value: keepSignedIn,
              onChanged: onToggleKeep,
              activeTrackColor: OnboarderApp.brandTeal,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text('Keep me signed in', style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
        const SizedBox(height: 6),

        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: loading ? null : onSignIn,
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign in'),
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: theme.textTheme.bodyMedium),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _OutlineAction(
                icon: Icons.phone_iphone_rounded,
                label: 'Phone',
                onTap: onOpenOtp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineAction(
                icon: Icons.mark_email_read_outlined,
                label: 'OTP',
                onTap: onOpenOtp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: Color(0xFFD5DAE1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: OnboarderApp.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: OnboarderApp.brandTealDark),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
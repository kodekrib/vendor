import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Password recovery screen — requests a reset code for an onboarder account
/// and lets the onboarder choose a new password.
///
/// Step 1 collects the account email; the backend delivers a one-time code to
/// the account's email (falling back to WhatsApp or SMS via Termii). Step 2
/// verifies the code and stores the new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, reset, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  _Step _step = _Step.email;
  String? _error;
  String? _devCode;
  List<String> _channels = const [];
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  /// " by email and SMS" (or similar) when the server reported the delivery
  /// channels; empty when nothing was reported.
  String get _sentVia {
    final label = describeOtpChannels(_channels);
    return label.isEmpty ? '' : ' by $label';
  }

  /// Step 1: ask the backend to send a reset code to the account's email.
  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter the email linked to your account.');
      return;
    }
    if (!_validEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _auth.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = _Step.reset;
        _devCode = result.devCode;
        _channels = result.channels;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not send a reset code. Please try again.';
      });
    }
  }

  /// Step 2: verify the code and store the new password.
  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if (code.isEmpty) {
      setState(() => _error = 'Enter the code we sent you.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Choose a password of at least 8 characters.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.resetPassword(
        email: _emailController.text.trim(),
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = _Step.done;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not reset your password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboarderApp.surfaceMuted,
      appBar: AppBar(
        backgroundColor: OnboarderApp.surfaceMuted,
        surfaceTintColor: Colors.transparent,
        title: const Text('Forgot password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: switch (_step) {
          _Step.email => _buildEmailStep(context),
          _Step.reset => _buildResetStep(context),
          _Step.done => _SuccessView(email: _emailController.text.trim()),
        },
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _iconBadge(Icons.lock_reset_rounded),
        const SizedBox(height: 20),
        Text('Reset your password', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Enter the email on your ${OnboarderApp.appName} account and we\'ll send '
          'you a code to choose a new password.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _requestCode(),
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'you@marketgo.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: _error!),
        ],
        const SizedBox(height: 16),
        _submitButton('Send reset code', _requestCode),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }

  Widget _buildResetStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _iconBadge(Icons.password_rounded),
        const SizedBox(height: 20),
        Text('Choose a new password', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Enter the code we sent to ${_emailController.text.trim()}$_sentVia '
          'and pick a new password.',
          style: theme.textTheme.bodyMedium,
        ),
        if (_devCode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: OnboarderApp.brandTealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Developer preview code: $_devCode',
              style: TextStyle(
                color: OnboarderApp.brandTealDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: const InputDecoration(
            labelText: 'Reset code',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _resetPassword(),
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: _error!),
        ],
        const SizedBox(height: 16),
        _submitButton('Reset password', _resetPassword),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _requestCode,
          child: const Text('Resend code'),
        ),
      ],
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: OnboarderApp.brandTealLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, size: 36, color: OnboarderApp.brandTealDark),
    );
  }

  Widget _submitButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.6, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB3261E), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8F1D16),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: OnboarderApp.brandTealLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mark_email_read_rounded,
              size: 44, color: OnboarderApp.brandTealDark),
        ),
        const SizedBox(height: 20),
        Text('Password updated', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Your password for $email has been changed. '
          'Sign in with your new password.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.tonal(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back to sign in'),
          ),
        ),
      ],
    );
  }
}

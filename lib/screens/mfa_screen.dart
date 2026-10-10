import 'package:flutter/material.dart';
import '../app.dart';
import '../services/auth_service.dart';

/// MFA verification screen for the login flow.
///
/// Matches the styling of the phone/OTP screen. Requires the user to enter
/// a numeric code to complete authentication when MFA is required.
class MfaScreen extends StatefulWidget {
  const MfaScreen({
    super.key,
    required this.onVerified,
    required this.email,
    this.title,
  });

  final VoidCallback onVerified;
  final String email;
  final String? title;

  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  final _codeFocus = FocusNode();
  final _codeController = TextEditingController();
  final List<String> _digits = List.filled(6, '');

  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '').padRight(6, ' ');
    setState(() {
      _digits.fillRange(0, 6, '');
      for (var i = 0; i < 6 && i < digits.length; i++) {
        if (digits[i] != ' ') {
          _digits[i] = digits[i];
        } else {
          _digits[i] = '';
        }
      }
    });
    if (value.replaceAll(RegExp(r'[^0-9]'), '').length == 6) {
      _verify();
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (code.length != 6) {
      setState(() => _error = 'Enter the full 6-digit code.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final ok = await OnboarderSession.instance.verifyMfaCode(code);
    if (!mounted) return;
    if (ok) {
      setState(() => _verifying = false);
      widget.onVerified();
      Navigator.of(context).pop();
    } else {
      setState(() {
        _verifying = false;
        _error = OnboarderSession.instance.pendingMfa == null
            ? 'Could not verify the code. Try again.'
            : 'Could not verify the code. Try again.';
      });
      // If session still has error via other means, but we just show generic
      try {
        // ignore
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = OnboarderSession.instance.pendingMfa;
    return Scaffold(
      backgroundColor: OnboarderApp.surfaceMuted,
      appBar: AppBar(
        backgroundColor: OnboarderApp.surfaceMuted,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: true,
        title: Text(widget.title ?? 'Multi-factor authentication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: OnboarderApp.brandTealLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.security_outlined,
                  size: 36, color: OnboarderApp.brandTealDark),
            ),
            const SizedBox(height: 20),
            Text('Enter the code', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'We sent a verification code to ${widget.email}.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (pending != null &&
                pending.devCode != null &&
                pending.devCode!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: OnboarderApp.brandTealLight,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: OnboarderApp.brandTealDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Developer preview — your code is ${pending.devCode}.',
                        style: TextStyle(
                          color: OnboarderApp.brandTealDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            GestureDetector(
              onTap: () => _codeFocus.requestFocus(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return Container(
                    width: 46,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _digits[i].isNotEmpty
                            ? OnboarderApp.brandTeal
                            : const Color(0xFFE2E5EA),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      _digits[i],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              focusNode: _codeFocus,
              keyboardType: TextInputType.number,
              maxLength: 6,
              maxLines: 1,
              autofocus: true,
              onChanged: _onCodeChanged,
              style: const TextStyle(fontSize: 0.1, color: Colors.transparent),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            if (_error != null) _ErrorBanner(message: _error!),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.6, color: Colors.white),
                      )
                    : const Text('Verify & sign in'),
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(top: 12),
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

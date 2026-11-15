import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

/// Identity information is entered directly into the provider's browser flow.
class ProviderVerification extends StatefulWidget {
  const ProviderVerification(
      {super.key, required this.api, required this.token});
  final ApiClient api;
  final String? Function() token;
  @override
  State<ProviderVerification> createState() => _ProviderVerificationState();
}

class _ProviderVerificationState extends State<ProviderVerification>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _checks = [];
  String? _error;
  Uri? _launchUri;
  bool _busy = false;
  static const _labels = {
    'instant_identity': 'Instant Identity Verification',
    'last_mile': 'Last Mile Verification',
    'ai_authentication': 'AI-Powered Authentication'
  };
  Map<String, String> get _headers =>
      {'Authorization': 'Bearer ${widget.token()}'};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    if (widget.token() == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.api
          .get('/api/v1/verification/status', headers: _headers);
      if (mounted) {
        setState(() => _checks = (data['checks'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start(String category) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.api.post('/api/v1/verification/start',
          headers: _headers, body: {'category': category});
      final uri =
          Uri.parse(widget.api.baseUrl).resolve(data['launch_path'] as String);
      if (kIsWeb) {
        if (mounted) setState(() => _launchUri = uri);
      } else if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open verification.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token() == null) return const SizedBox.shrink();
    final required = _checks.where((c) => c['required'] == true).toList();
    if (required.isEmpty && _error == null && !_busy) {
      return const SizedBox.shrink();
    }
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_launchUri != null)
                OutlinedButton(
                    onPressed: () => launchUrl(_launchUri!,
                        mode: LaunchMode.externalApplication),
                    child: const Text('Open secure verification')),
              const Text('Secure identity verification',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(
                  'Complete required checks with QoreID. Identity numbers and identity images are not saved by MarketGO. Some results require admin review.'),
              for (final check in required) ...[
                Text(
                    '${_labels[check['category']] ?? check['category']}: ${check['status']}'),
                if (check['status'] != 'verified' &&
                    (check['status'] != 'pending' || check['session_id'] == ''))
                  OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _start(check['category'] as String),
                      child: const Text('Verify with QoreID'))
              ],
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              TextButton(
                  onPressed: _busy ? null : _load,
                  child: Text(
                      _busy ? 'Checking…' : 'Refresh verification status')),
            ])));
  }
}

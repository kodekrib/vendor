import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/onboarder_app_bar.dart';

/// Identity and guarantor submission for the field onboarding account.
class KYCStatusScreen extends StatefulWidget {
  const KYCStatusScreen({super.key, this.onSubmitted});
  final VoidCallback? onSubmitted;
  @override
  State<KYCStatusScreen> createState() => _KYCStatusScreenState();
}

class _KYCStatusScreenState extends State<KYCStatusScreen> {
  final _form = GlobalKey<FormState>();
  final _api = ApiClient();
  static const _labels = {
    'nin': 'NIN (11 digits)',
    'address': 'Residential address',
    'phone': 'Phone number',
    'guarantor_name': 'Guarantor full name',
    'guarantor_phone': 'Guarantor phone number',
    'guarantor_address': 'Guarantor residential address',
    'guarantor_relationship': 'Relationship to guarantor',
  };
  final _fields = {
    for (final key in _labels.keys) key: TextEditingController()
  };
  bool _loading = true, _saving = false, _uploading = false, _submitted = false;
  String? _error;
  String _document = '';
  Map<String, String> get _auth =>
      {'Authorization': 'Bearer ${OnboarderSession.instance.accessToken}'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get('/api/v1/onboarder/profile', headers: _auth);
      if (!mounted) return;
      final kyc = data['profile']['kyc'];
      if (kyc is Map) {
        for (final key in _fields.keys) {
          _fields[key]!.text = kyc[key]?.toString() ?? '';
        }
        _document = kyc['identity_card_url']?.toString() ?? '';
        _submitted = true;
      }
    } catch (e) {
      if (mounted) _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: true);
      if (result == null) return;
      final file = result.files.single;
      if (file.bytes == null || file.size > 10 * 1024 * 1024) {
        throw const ApiException('Choose a document smaller than 10 MB.');
      }
      final url = await _api.uploadDocumentBytes(
          file.bytes!, file.name, OnboarderSession.instance.accessToken!);
      if (mounted) setState(() => _document = url);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_document.isEmpty) {
      setState(() => _error = 'Upload your identity document to continue.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Preserve the existing editable profile when submitting verification.
      final data = await _api.get('/api/v1/onboarder/profile', headers: _auth);
      final profile = Map<String, dynamic>.from(data['profile'] as Map);
      await _api.put('/api/v1/onboarder/profile', headers: _auth, body: {
        for (final key in [
          'address',
          'bio',
          'instagram_handle',
          'twitter_handle',
          'linkedin_handle',
          'facebook_handle',
          'tiktok_handle'
        ])
          key: profile[key] ?? '',
        'kyc': {
          for (final entry in _fields.entries)
            entry.key: entry.value.text.trim(),
          'identity_card_url': _document
        },
      });
      if (!mounted) return;
      setState(() => _submitted = true);
      widget.onSubmitted?.call();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('KYC and guarantor details submitted.')));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const OnboarderAppBar(title: 'KYC & Guarantor'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _form,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Text(_submitted
                      ? 'Your KYC and guarantor details have been submitted.'
                      : 'Submit your identity and guarantor details to use the app.'),
                  const SizedBox(height: 20),
                  for (final entry in _fields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: entry.value,
                        enabled: !_saving && !_uploading,
                        decoration:
                            InputDecoration(labelText: _labels[entry.key]),
                        keyboardType: entry.key == 'nin'
                            ? TextInputType.number
                            : entry.key.contains('phone')
                                ? TextInputType.phone
                                : TextInputType.text,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'This field is required.';
                          if (entry.key == 'nin' &&
                              !RegExp(r'^\d{11}$').hasMatch(text)) {
                            return 'Enter an 11-digit NIN.';
                          }
                          if (entry.key.contains('phone') &&
                              !RegExp(r'^\+?[0-9 ()-]{10,20}$')
                                  .hasMatch(text)) {
                            return 'Enter a valid phone number.';
                          }
                          return null;
                        },
                      ),
                    ),
                  OutlinedButton.icon(
                      onPressed: _saving || _uploading ? null : _upload,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_uploading
                          ? 'Uploading…'
                          : _document.isEmpty
                              ? 'Upload identity document'
                              : 'Replace identity document')),
                  if (_document.isNotEmpty)
                    const Text('Identity document uploaded.'),
                  if (_error != null) ...[
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    TextButton(
                        onPressed: _loading || _saving ? null : _load,
                        child: const Text('Reload'))
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: _saving || _uploading ? null : _submit,
                      child: Text(
                          _saving ? 'Submitting…' : 'Submit KYC & guarantor')),
                ]),
              ),
      );

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }
}

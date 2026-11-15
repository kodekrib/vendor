import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/onboard_service.dart';
import '../services/profile_service.dart';
import '../widgets/onboarder_app_bar.dart';
import '../widgets/profile_photo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.service});
  final ProfileService? service;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final key in [
      'name',
      'email',
      'address',
      'bio',
      'instagram_handle',
      'twitter_handle',
      'linkedin_handle',
      'facebook_handle',
      'tiktok_handle'
    ])
      key: TextEditingController(),
  };
  late final ProfileService _service;
  bool _loading = true, _saving = false;
  String? _error;
  AgentProfile? _profile;
  static const _labels = {
    'name': 'Full name',
    'email': 'Email address',
    'address': 'Address',
    'bio': 'About you',
    'instagram_handle': 'Instagram',
    'twitter_handle': 'X / Twitter',
    'linkedin_handle': 'LinkedIn',
    'facebook_handle': 'Facebook',
    'tiktok_handle': 'TikTok',
  };

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ?? ProfileService(api: OnboarderSession.instance.api);
    _load();
  }

  void _populate(AgentProfile profile) {
    _profile = profile;
    for (final entry in _fields.entries) {
      entry.value.text = profile.value(entry.key);
    }
  }

  Future<void> _load() async {
    final token = OnboarderSession.instance.accessToken;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Sign in to view your profile.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _service.load(token);
      if (mounted) setState(() => _populate(profile));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = OnboarderSession.instance.accessToken;
    if (token == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await _service.save(token,
          {for (final entry in _fields.entries) entry.key: entry.value.text});
      if (!mounted) return;
      setState(() => _populate(profile));
      try {
        await OnboarderSession.instance.refreshProfile();
        await OnboardService.instance.refreshProfile(token);
      } catch (_) {/* Saved server data remains available on next refresh. */}
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const OnboarderAppBar(title: 'Profile'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(20), children: [
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                if (_profile == null)
                  OutlinedButton(onPressed: _load, child: const Text('Retry'))
                else
                  Form(
                      key: _formKey,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                                child: ProfilePhoto(
                                    api: OnboarderSession.instance.api,
                                    tokenProvider: () =>
                                        OnboarderSession.instance.accessToken,
                                    avatarUrl: OnboarderSession
                                            .instance.user?.avatarUrl ??
                                        _profile!.value('profile_photo_url'),
                                    name: _profile!.value('name'),
                                    onUpdated: OnboarderSession
                                        .instance.refreshProfile,
                                    radius: 42)),
                            const SizedBox(height: 24),
                            const Text('Personal details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 14),
                            for (final key in ['name', 'email']) _field(key),
                            TextFormField(
                                initialValue: _profile!.value('phone'),
                                keyboardType: TextInputType.phone,
                                readOnly: true,
                                decoration: const InputDecoration(
                                    labelText: 'Sign-in phone number',
                                    helperText:
                                        'Contact support if your sign-in number needs to change.')),
                            const SizedBox(height: 16),
                            for (final key in ['address', 'bio']) _field(key),
                            const SizedBox(height: 8),
                            const Text('Social profiles',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 14),
                            for (final key in [
                              'instagram_handle',
                              'twitter_handle',
                              'linkedin_handle',
                              'facebook_handle',
                              'tiktok_handle'
                            ])
                              _field(key),
                            const SizedBox(height: 8),
                            FilledButton(
                                onPressed: _saving ? null : _save,
                                child:
                                    Text(_saving ? 'Saving…' : 'Save profile')),
                          ])),
              ]),
      );
  Widget _field(String key) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
          controller: _fields[key],
          enabled: !_saving,
          maxLength: key == 'bio'
              ? 1000
              : key == 'address'
                  ? 500
                  : 255,
          minLines: key == 'address' || key == 'bio' ? 3 : 1,
          maxLines: key == 'address' || key == 'bio' ? 5 : 1,
          keyboardType: key == 'email'
              ? TextInputType.emailAddress
              : key == 'address' || key == 'bio'
                  ? TextInputType.multiline
                  : TextInputType.text,
          textInputAction: key == 'address' || key == 'bio'
              ? TextInputAction.newline
              : TextInputAction.next,
          textCapitalization: key == 'email' || key.endsWith('_handle')
              ? TextCapitalization.none
              : key == 'name'
                  ? TextCapitalization.words
                  : TextCapitalization.sentences,
          autocorrect: key != 'email' && !key.endsWith('_handle'),
          validator: (value) {
            if (['name', 'email'].contains(key) &&
                (value?.trim().isEmpty ?? true)) {
              return '${_labels[key]} is required.';
            }
            if (key == 'email' &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value!.trim())) {
              return 'Enter a valid email address.';
            }
            return null;
          },
          decoration:
              InputDecoration(labelText: _labels[key], counterText: '')));
}

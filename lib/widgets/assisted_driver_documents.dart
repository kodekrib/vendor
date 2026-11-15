import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'onboarding_form.dart';
import 'place_search_field.dart';
import '../services/auth_service.dart';

/// Assisted uploads never capture NIN or claim the driver's personal consent.
class AssistedDriverDocuments extends StatefulWidget {
  const AssistedDriverDocuments(
      {super.key, this.collectDriverDetails = false, this.collectPhone = true});
  final bool collectDriverDetails, collectPhone;

  @override
  State<AssistedDriverDocuments> createState() =>
      AssistedDriverDocumentsState();
}

class AssistedDriverDocumentsState extends State<AssistedDriverDocuments> {
  ApiClient get _api => OnboarderSession.instance.api;
  final _fields = <String, TextEditingController>{
    for (final key in [
      'drivers_license_no',
      'insurance_no',
      'lasrra_permit_no',
      'date_of_birth',
      'address',
      'phone'
    ])
      key: TextEditingController(),
  };
  final _urls = <String, String>{};
  final _dates = <String, String>{};
  final _uploading = <String>{};
  String? _policy, _error;
  bool _acknowledged = false;

  static const _documents = {
    'drivers_license_image_url': 'Driver’s license',
    'insurance_image_url': 'Insurance certificate',
    'vehicle_registration_image_url': 'Vehicle registration',
    'lasrra_permit_image_url': 'LASRRA permit (optional)',
  };

  Map<String, dynamic> get payload => {
        ..._urls,
        ..._dates,
        if (widget.collectDriverDetails)
          for (final entry in _fields.entries)
            if (entry.key != 'phone' || widget.collectPhone)
              entry.key: entry.value.text.trim(),
        'ndpr_notice_acknowledged': _acknowledged,
        'ndpr_policy_text': _policy,
      };

  bool validate() {
    final missing = !_acknowledged ||
        _policy == null ||
        _uploading.isNotEmpty ||
        _documents.keys.take(3).any((key) => (_urls[key] ?? '').isEmpty) ||
        _dates.length < 2 ||
        (widget.collectDriverDetails &&
            _fields.entries.any((entry) =>
                entry.key != 'lasrra_permit_no' &&
                (entry.key != 'phone' || widget.collectPhone) &&
                entry.value.text.trim().isEmpty));
    setState(() => _error = missing
        ? 'Complete the driver details, required uploads, expiry dates and notice acknowledgement.'
        : null);
    return !missing;
  }

  Future<void> _notice() async {
    final token = OnboarderSession.instance.accessToken;
    if (token == null) return;
    try {
      final data = await _api.get('/api/v1/onboarder/ndpr-notice',
          headers: {'Authorization': 'Bearer $token'});
      final policy = data['ndpr_policy'] as String?;
      if (policy == null || policy.trim().isEmpty) {
        throw const ApiException('Notice is unavailable.');
      }
      if (!mounted) return;
      final accepted = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('NDPR assisted onboarding'),
                content: SingleChildScrollView(
                    child: Text(
                        '$policy\n\nBy continuing, I confirm that I have explained this notice to the driver and have their permission to upload these documents. The driver must personally accept it in the rider app.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Acknowledge')),
                ],
              ));
      if (mounted && accepted == true) {
        setState(() {
          _policy = policy;
          _acknowledged = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _upload(String key) async {
    if (!_acknowledged) {
      await _notice();
    }
    if (!_acknowledged || !mounted) return;
    final token = OnboarderSession.instance.accessToken;
    if (token == null) return;
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        withData: true);
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.size > 5 * 1024 * 1024) {
      setState(() => _error = 'Choose an image smaller than 5 MB.');
      return;
    }
    setState(() {
      _uploading.add(key);
      _error = null;
    });
    try {
      final url = await _api.uploadDocumentBytes(file.bytes!, file.name, token);
      if (mounted) setState(() => _urls[key] = url);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _uploading.remove(key));
    }
  }

  Future<void> _pickDate(String key, {bool birth = false}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: birth ? DateTime(now.year - 25) : now,
        firstDate:
            birth ? DateTime(1900) : DateTime(now.year, now.month, now.day),
        lastDate: birth
            ? DateTime(now.year - 18, now.month, now.day)
            : DateTime(now.year + 30));
    if (mounted && date != null) {
      setState(() {
        final value = date.toIso8601String().split('T').first;
        if (birth) {
          _fields[key]!.text = value;
        } else {
          _dates[key] = value;
        }
      });
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
  Widget build(BuildContext context) {
    final uploaded = _documents.keys.take(3).where(_urls.containsKey).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      OnboardingCard(
          title: 'Permission to upload',
          subtitle:
              'Explain the notice to the driver before sharing any documents.',
          children: [
            const OnboardingNotice(
                text:
                    'Do not collect NIN. The driver will review these documents and personally accept the NDPR notice in their own account.'),
            const SizedBox(height: 10),
            OutlinedButton.icon(
                onPressed: _notice,
                icon: Icon(_acknowledged
                    ? Icons.check_circle
                    : Icons.privacy_tip_outlined),
                label: Text(_acknowledged
                    ? 'Notice acknowledged — view'
                    : 'Read & acknowledge NDPR notice')),
          ]),
      if (widget.collectDriverDetails)
        OnboardingCard(
            title: 'Driver details',
            subtitle: 'Use the details printed on the driver’s documents.',
            children: [
              for (final entry in _fields.entries)
                if (entry.key != 'phone' || widget.collectPhone)
                  if (entry.key == 'address')
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PlaceSearchField(
                            controller: entry.value,
                            labelText: 'Home address *',
                            hintText: 'Street, area, city',
                            inForm: true,
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true)
                                    ? 'Enter the home address.'
                                    : null))
                  else
                    OnboardingField(
                      controller: entry.value,
                      required: entry.key != 'lasrra_permit_no',
                      label: const {
                        'drivers_license_no': 'Driver’s license number',
                        'insurance_no': 'Insurance number',
                        'lasrra_permit_no': 'LASRRA permit number',
                        'date_of_birth': 'Date of birth',
                        'address': 'Home address',
                        'phone': 'Driver phone number',
                      }[entry.key]!,
                      readOnly: entry.key == 'date_of_birth',
                      icon: entry.key == 'date_of_birth'
                          ? Icons.calendar_today_outlined
                          : null,
                      onTap: entry.key == 'date_of_birth'
                          ? () => _pickDate(entry.key, birth: true)
                          : null,
                      keyboardType: entry.key == 'phone'
                          ? TextInputType.phone
                          : TextInputType.text,
                      hint: entry.key == 'date_of_birth' ? 'Select date' : null,
                    ),
            ]),
      OnboardingCard(
          title: 'Document photos',
          subtitle:
              '$uploaded of 3 required documents uploaded. Use clear images with all corners visible.',
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:
                    LinearProgressIndicator(value: uploaded / 3, minHeight: 5)),
            const SizedBox(height: 16),
            for (final entry in _documents.entries)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _urls.containsKey(entry.key)
                        ? const Color(0xFFF0FAF6)
                        : const Color(0xFFF7F9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E8E9))),
                child: Row(children: [
                  Icon(
                      _urls.containsKey(entry.key)
                          ? Icons.check_circle_rounded
                          : Icons.description_outlined,
                      color: _urls.containsKey(entry.key)
                          ? const Color(0xFF15803D)
                          : const Color(0xFF7B8794)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(entry.value,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                            _urls.containsKey(entry.key)
                                ? 'Uploaded • Ready for review'
                                : 'Image up to 5 MB',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF64748B))),
                      ])),
                  const SizedBox(width: 4),
                  _uploading.contains(entry.key)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: () => _upload(entry.key),
                          child: Text(_urls.containsKey(entry.key)
                              ? 'Replace'
                              : 'Upload')),
                ]),
              ),
          ]),
      OnboardingCard(
          title: 'Expiry dates',
          subtitle: 'Select the expiry date shown on each document.',
          children: [
            for (final key in ['license_expires_at', 'insurance_expires_at'])
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton.icon(
                      onPressed: () => _pickDate(key),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12)),
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                          '${key == 'license_expires_at' ? 'License' : 'Insurance'} expiry: ${_dates[key] ?? 'Select date'}'))),
          ]),
      if (_error != null) OnboardingNotice(text: _error!, error: true),
      const SizedBox(height: 12),
    ]);
  }
}

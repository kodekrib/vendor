import 'package:flutter/material.dart';
import '../app.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/onboard_service.dart';
import 'onboarding_form.dart';
import 'assisted_driver_documents.dart';
import 'vehicle_color_picker.dart';

class OnboardDriverForm extends StatefulWidget {
  const OnboardDriverForm(
      {super.key, required this.mover, this.api, this.tokenProvider});
  final ApiClient? api;
  final String? Function()? tokenProvider;
  final bool mover;
  @override
  State<OnboardDriverForm> createState() => _OnboardDriverFormState();
}

class _OnboardDriverFormState extends State<OnboardDriverForm> {
  final _packingOptions = ExpansionTileController();
  final _flowKey = GlobalKey<OnboardingFlowState>();
  final _documentsKey = GlobalKey<AssistedDriverDocumentsState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _phone = TextEditingController(),
      _password = TextEditingController(),
      _brand = TextEditingController(),
      _model = TextEditingController(),
      _reg = TextEditingController(),
      _capacity = TextEditingController(),
      _packerFee = TextEditingController(text: '5000');
  List<Map<String, dynamic>> _types = [];
  String? _type, _typesError, _error;
  String _color = '#111418';
  bool _typesLoading = true, _submitting = false;
  int _maxPackers = 2;
  String get _noun => widget.mover ? 'mover' : 'rider';
  String get _vehicleLabel => _types
      .where((type) => type['name'] == _type)
      .map((type) => type['label'])
      .join();

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() {
      _typesLoading = true;
      _typesError = null;
    });
    try {
      final token =
          widget.tokenProvider?.call() ?? OnboarderSession.instance.accessToken;
      if (token == null) {
        throw const ApiException('Sign in to load vehicle types.');
      }
      final result = await (widget.api ?? OnboarderSession.instance.api).get(
          '/api/v1/onboarder/vehicle-types',
          headers: {'Authorization': 'Bearer $token'});
      final types = (result['vehicle_types'] as List)
          .whereType<Map<String, dynamic>>()
          .where((type) =>
              type['is_active'] == true &&
              (!widget.mover ||
                  ['pickup_truck', 'van', 'mini_truck', 'lorry']
                      .contains(type['name'])))
          .toList();
      if (types.isEmpty) {
        throw const ApiException(
            'No vehicle types are available. Contact admin.');
      }
      if (mounted) {
        setState(() {
          _types = types;
          if (!types.any((type) => type['name'] == _type)) _type = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _typesError = '$e');
    } finally {
      if (mounted) setState(() => _typesLoading = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
      _brand,
      _model,
      _reg,
      _capacity,
      _packerFee
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final token = OnboarderSession.instance.accessToken;
    if (token == null) {
      setState(() => _error = 'Sign in before creating this account.');
      return;
    }
    final docs = _documentsKey.currentState?.payload;
    if (docs == null || !(_documentsKey.currentState?.validate() ?? false)) {
      _flowKey.currentState?.goToStep(2);
      return;
    }
    final typeId = _types.firstWhere((type) => type['name'] == _type)['id'];
    setState(() {
      _submitting = true;
      _error = null;
    });
    final String? error;
    if (widget.mover) {
      error = await OnboardService.instance.onboardMover(
          token: token,
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          assistedDocuments: {
            ...docs,
            'phone': _phone.text.trim(),
            'vehicle_type_id': typeId
          },
          vehicleBrand: _brand.text.trim(),
          vehicleModel: _model.text.trim(),
          vehicleType: _type!,
          vehicleColor: _color,
          vehicleRegNo: _reg.text.trim().toUpperCase(),
          vehicleCapacity: _capacity.text.trim(),
          vehiclePackerFee: double.tryParse(_packerFee.text.trim()) ?? 0,
          vehicleMaxPackers: _maxPackers);
    } else {
      error = await OnboardService.instance.onboardRider(
          token: token,
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          phone: _phone.text.trim(),
          assistedDocuments: docs,
          driversLicenseNo: docs['drivers_license_no'] as String,
          insuranceNo: docs['insurance_no'] as String,
          lasrraPermitNo: docs['lasrra_permit_no'] as String,
          dateOfBirth: docs['date_of_birth'] as String,
          address: docs['address'] as String,
          vehicleTypeId: '$typeId',
          vehicleRegNo: _reg.text.trim().toUpperCase(),
          vehicleBrand: _brand.text.trim(),
          vehicleModel: _model.text.trim(),
          vehicleType: _type!,
          vehicleColor: _color);
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
        content: Text(
            '${widget.mover ? 'Mover' : 'Rider'} account created. The driver must accept the NDPR notice in the rider app.')));
  }

  @override
  Widget build(BuildContext context) => OnboardingFlow(
        key: _flowKey,
        title: 'Onboard $_noun',
        icon: widget.mover
            ? Icons.local_shipping_rounded
            : Icons.two_wheeler_rounded,
        busy: _submitting,
        error: _error,
        submitLabel: 'Onboard $_noun',
        onSubmit: _submit,
        steps: [
          OnboardingStep(
              label: 'Account',
              title: 'Meet your new $_noun',
              description:
                  'Use the driver’s own contact details. Their phone number connects them to this account when they sign in.',
              builder: (_) => Column(children: [
                    OnboardingCard(title: 'Driver account', children: [
                      OnboardingField(
                          controller: _name,
                          label: widget.mover ? 'Mover name' : 'Rider name',
                          hint: 'Full name',
                          icon: Icons.person_outline_rounded),
                      OnboardingField(
                          controller: _email,
                          label: 'Email address',
                          hint: 'driver@example.com',
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.mail_outline),
                      OnboardingField(
                          controller: _phone,
                          label: 'Phone number',
                          hint: '0803 123 4567',
                          keyboardType: TextInputType.phone,
                          icon: Icons.phone_outlined),
                      OnboardingField(
                          controller: _password,
                          label: 'Password',
                          password: true,
                          icon: Icons.lock_outline,
                          helper:
                              'At least 8 characters. Share it securely with the driver.'),
                    ]),
                    const OnboardingNotice(
                        text:
                            'You can help upload driver and vehicle documents. The driver personally accepts the NDPR notice after signing in. Do not collect NIN.'),
                  ])),
          OnboardingStep(
              label: 'Vehicle',
              ready: !_typesLoading && _typesError == null,
              title: 'Match the driver to their vehicle',
              description: widget.mover
                  ? 'Register the moving vehicle. Optional packing services can be configured below.'
                  : 'Add the vehicle customers should expect at pickup.',
              validate: () {
                final value = _packerFee.text.trim();
                final price = double.tryParse(value);
                if (widget.mover &&
                    value.isNotEmpty &&
                    (price == null || !price.isFinite || price < 0)) {
                  _packingOptions.expand();
                  return false;
                }
                return !_typesLoading && _typesError == null && _type != null;
              },
              validationMessage:
                  'Choose an available vehicle type and check the vehicle details.',
              builder: (_) => Column(children: [
                    OnboardingCard(title: 'Vehicle details', children: [
                      if (_typesLoading)
                        const Padding(
                            padding: EdgeInsets.all(16),
                            child: LinearProgressIndicator())
                      else if (_typesError != null) ...[
                        OnboardingNotice(text: _typesError!, error: true),
                        TextButton.icon(
                            onPressed: _loadTypes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry vehicle types')),
                      ] else
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: DropdownButtonFormField<String>(
                                value: _type,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Vehicle type *',
                                    prefixIcon:
                                        Icon(Icons.local_shipping_outlined)),
                                validator: (value) => value == null
                                    ? 'Choose a vehicle type.'
                                    : null,
                                items: _types
                                    .map((type) => DropdownMenuItem(
                                        value: type['name'] as String,
                                        child: Text(type['label'] as String)))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _type = value))),
                      OnboardingField(
                          controller: _brand,
                          label: 'Vehicle brand',
                          hint: 'e.g. Toyota / Bajaj',
                          icon: Icons.directions_car_outlined),
                      OnboardingField(
                          controller: _model,
                          label: 'Vehicle model',
                          required: false,
                          hint: widget.mover ? 'e.g. Hiace' : 'e.g. Boxer 150'),
                      OnboardingField(
                          controller: _reg,
                          label: 'Registration number',
                          hint: 'e.g. LAG-560-JKK',
                          icon: Icons.numbers_rounded),
                      const Text('Vehicle color',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      VehicleColorPicker(
                          value: _color,
                          onChanged: (color) => setState(() => _color = color)),
                    ]),
                    if (widget.mover)
                      OnboardingCard(
                          title: 'Extra vehicle options',
                          subtitle:
                              'Optional details for capacity and packing assistance.',
                          children: [
                            ExpansionTile(
                                controller: _packingOptions,
                                tilePadding: EdgeInsets.zero,
                                title: const Text('Capacity & packing services',
                                    style: TextStyle(fontSize: 13)),
                                maintainState: true,
                                children: [
                                  OnboardingField(
                                      controller: _capacity,
                                      label: 'Vehicle capacity',
                                      required: false,
                                      hint: 'e.g. 1.5 tons / 12 chairs'),
                                  OnboardingField(
                                      controller: _packerFee,
                                      label:
                                          'Packer fee per person (${OnboarderApp.currencySymbol})',
                                      required: false,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      validator: (value) {
                                        final price = double.tryParse(
                                            value?.trim() ?? '');
                                        return value?.trim().isEmpty ?? true
                                            ? null
                                            : price == null ||
                                                    !price.isFinite ||
                                                    price < 0
                                                ? 'Enter a valid amount of zero or more.'
                                                : null;
                                      }),
                                  DropdownButtonFormField<int>(
                                      value: _maxPackers,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Maximum extra packers'),
                                      items: List.generate(
                                          21,
                                          (index) => DropdownMenuItem(
                                              value: index,
                                              child: Text(index == 0
                                                  ? 'No extra packers'
                                                  : '$index ${index == 1 ? 'packer' : 'packers'}'))),
                                      onChanged: (value) => setState(
                                          () => _maxPackers = value ?? 0)),
                                  const SizedBox(height: 14),
                                ]),
                          ]),
                    if (widget.mover)
                      const OnboardingNotice(
                          text:
                              'Your onboarding commission is determined by the admin.'),
                  ])),
          OnboardingStep(
              label: 'Documents',
              title: 'Help them get verified',
              description:
                  'Keep the driver with you while you confirm their details and upload clear document photos.',
              validate: () => _documentsKey.currentState?.validate() ?? false,
              validationMessage:
                  'Check the driver details, notice acknowledgement, required photos and expiry dates.',
              builder: (_) => AssistedDriverDocuments(
                  key: _documentsKey,
                  collectDriverDetails: true,
                  collectPhone: false)),
          OnboardingStep(
              label: 'Review',
              title: 'One last check',
              description:
                  'Make sure the details match the driver and their vehicle before you create the account.',
              builder: (_) {
                final docs =
                    _documentsKey.currentState?.payload ?? <String, dynamic>{};
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OnboardingCard(
                          title: 'Driver account',
                          onEdit: () => _flowKey.currentState?.goToStep(0),
                          children: [
                            onboardingSummary('Name', _name.text),
                            onboardingSummary('Email', _email.text),
                            onboardingSummary('Phone', _phone.text),
                            onboardingSummary(
                                'Password', 'Set • Hidden for privacy'),
                          ]),
                      OnboardingCard(
                          title: 'Vehicle',
                          onEdit: () => _flowKey.currentState?.goToStep(1),
                          children: [
                            onboardingSummary('Vehicle',
                                '$_vehicleLabel · ${_brand.text} ${_model.text}'),
                            onboardingSummary(
                                'Registration', _reg.text.toUpperCase()),
                            onboardingSummary('Color', _color),
                            if (widget.mover)
                              onboardingSummary('Packing assistance',
                                  'Up to $_maxPackers packers · ${OnboarderApp.currencySymbol}${_packerFee.text.isEmpty ? '0' : _packerFee.text} per person'),
                          ]),
                      OnboardingCard(
                          title: 'Verification documents',
                          onEdit: () => _flowKey.currentState?.goToStep(2),
                          children: [
                            onboardingSummary('Driver’s license',
                                docs['drivers_license_no']?.toString() ?? ''),
                            onboardingSummary('Insurance',
                                docs['insurance_no']?.toString() ?? ''),
                            onboardingSummary('Document photos',
                                'Driver’s license, insurance and vehicle registration'),
                            onboardingSummary('Expiry dates',
                                'License: ${docs['license_expires_at'] ?? 'Not selected'}\nInsurance: ${docs['insurance_expires_at'] ?? 'Not selected'}'),
                            onboardingSummary(
                                'NDPR notice',
                                docs['ndpr_notice_acknowledged'] == true
                                    ? 'Explained to driver • Acknowledged by you'
                                    : 'Not acknowledged'),
                          ]),
                      const OnboardingNotice(
                          text:
                              'Next: the driver signs in to the rider app, reviews their documents and accepts the NDPR notice. Admin reviews the verification before new jobs are enabled.'),
                    ]);
              }),
        ],
      );
}

import '../widgets/place_search_field.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/merchant_group_service.dart';
import '../services/auth_service.dart';
import '../services/onboard_service.dart';
import '../widgets/onboarding_form.dart';
import '../widgets/onboarding_image_upload.dart';

/// Field form for onboarding a new vendor with KYC documents.
class OnboardVendorScreen extends StatefulWidget {
  const OnboardVendorScreen({super.key, this.groupService, this.tokenProvider});
  final MerchantGroupService? groupService;
  final String? Function()? tokenProvider;

  @override
  State<OnboardVendorScreen> createState() => _OnboardVendorScreenState();
}

class _OnboardVendorScreenState extends State<OnboardVendorScreen> {
  final _storeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingHoursController = TextEditingController(text: '08:00');
  final _closingHoursController = TextEditingController(text: '22:00');
  final _descriptionController = TextEditingController();
  final _flowKey = GlobalKey<OnboardingFlowState>();
  final Set<String> _imageUploads = {};
  String _logoUrl = '', _bannerUrl = '';

  String? _merchantGroup;
  List<Map<String, dynamic>> _merchantGroups = [];
  bool _groupsLoading = true;
  String? _groupsError;

  @override
  void initState() {
    super.initState();
    _loadMerchantGroups();
  }

  Future<void> _loadMerchantGroups() async {
    setState(() {
      _groupsLoading = true;
      _groupsError = null;
    });
    try {
      final token =
          widget.tokenProvider?.call() ?? OnboarderSession.instance.accessToken;
      if (token == null) {
        throw const ApiException('Sign in to load merchant groups.');
      }
      final groups = await (widget.groupService ??
              MerchantGroupService(api: OnboarderSession.instance.api))
          .load(token);
      if (mounted) {
        setState(() {
          _merchantGroups = groups;
          if (!groups.any((group) => group['slug'] == _merchantGroup)) {
            _merchantGroup = null;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _groupsError = '$e');
    } finally {
      if (mounted) setState(() => _groupsLoading = false);
    }
  }

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _storeController.dispose();
    _ownerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _openingHoursController.dispose();
    _closingHoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_storeController.text.trim().isEmpty ||
        _ownerController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().length < 8 ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _merchantGroup == null) {
      setState(() => _error = 'Fill in every required field to continue.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = OnboarderSession.instance.accessToken;
    if (token == null) {
      setState(() {
        _submitting = false;
        _error = 'Please sign in with a real account to onboard vendors.';
      });
      return;
    }

    final error = await OnboardService.instance.onboardVendor(
      token: token,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _ownerController.text.trim(),
      storeName: _storeController.text.trim(),
      storeDesc: _descriptionController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      openingHours: _openingHoursController.text.trim(),
      closingHours: _closingHoursController.text.trim(),
      bannerUrl: _bannerUrl,
      logoUrl: _logoUrl,
      merchantGroup: _merchantGroup!,
    );

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
    messenger.showSnackBar(
      const SnackBar(content: Text('Vendor onboarded successfully.')),
    );
  }

  Future<void> _pickHours(TextEditingController controller) async {
    final parts = controller.text.split(':');
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: int.tryParse(parts.first) ?? 8,
            minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0));
    if (picked != null && mounted) {
      setState(() => controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) => OnboardingFlow(
        key: _flowKey,
        title: 'Onboard vendor',
        icon: Icons.storefront_rounded,
        busy: _submitting,
        error: _error,
        submitLabel: 'Onboard vendor',
        onSubmit: _submit,
        steps: [
          OnboardingStep(
              label: 'Business',
              ready: !_groupsLoading && _groupsError == null,
              title: 'Introduce the business',
              description:
                  'Start with the store customers will discover on MarketGO.',
              validate: () =>
                  !_groupsLoading &&
                  _groupsError == null &&
                  _merchantGroup != null,
              validationMessage:
                  'Choose a merchant group and complete the store details.',
              builder: (_) => OnboardingCard(title: 'Store details', children: [
                    OnboardingField(
                        controller: _storeController,
                        label: 'Store name',
                        hint: 'e.g. FreshCart',
                        icon: Icons.storefront_outlined),
                    if (_groupsLoading)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: LinearProgressIndicator())
                    else if (_groupsError != null) ...[
                      OnboardingNotice(text: _groupsError!, error: true),
                      TextButton.icon(
                          onPressed: _loadMerchantGroups,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry merchant groups')),
                    ] else
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DropdownButtonFormField<String>(
                            value: _merchantGroup,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Merchant group *',
                                prefixIcon: Icon(Icons.category_outlined),
                                helperText:
                                    'Where customers will find this business.'),
                            validator: (value) => value == null
                                ? 'Choose a merchant group.'
                                : null,
                            items: _merchantGroups
                                .map((group) => DropdownMenuItem(
                                    value: group['slug'] as String,
                                    child: Text(group['name'] as String)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _merchantGroup = value),
                          )),
                    PlaceSearchField(
                        controller: _addressController,
                        labelText: 'Store address *',
                        hintText: 'Street, area, city',
                        inForm: true,
                        validator: (value) => value?.trim().isEmpty ?? true
                            ? 'Enter the store address.'
                            : null),
                    const SizedBox(height: 16),
                    OnboardingField(
                        controller: _descriptionController,
                        label: 'Store description',
                        required: false,
                        hint: 'Tell customers what this business sells.',
                        maxLines: 3),
                  ])),
          OnboardingStep(
              label: 'Account',
              title: 'Set up owner access',
              description:
                  'Use the owner’s contact details so they can access their own merchant account.',
              builder: (_) => OnboardingCard(title: 'Owner account', children: [
                    OnboardingField(
                        controller: _ownerController,
                        label: 'Owner name',
                        hint: 'e.g. Amina Bello',
                        icon: Icons.person_outline_rounded),
                    OnboardingField(
                        controller: _emailController,
                        label: 'Business email',
                        hint: 'owner@example.com',
                        keyboardType: TextInputType.emailAddress,
                        icon: Icons.mail_outline_rounded),
                    OnboardingField(
                        controller: _phoneController,
                        label: 'Phone number',
                        hint: '0803 123 4567',
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone_outlined),
                    OnboardingField(
                        controller: _passwordController,
                        label: 'Password',
                        password: true,
                        icon: Icons.lock_outline,
                        helper:
                            'At least 8 characters. Share it securely with the account owner.'),
                  ])),
          OnboardingStep(
              label: 'Storefront',
              ready: _imageUploads.isEmpty,
              title: 'Make the store feel familiar',
              description:
                  'Set operating hours and add optional images. Images can be added later.',
              validate: () => _imageUploads.isEmpty,
              validationMessage:
                  'Wait for image uploads to finish before continuing.',
              builder: (_) => Column(children: [
                    OnboardingCard(title: 'Operating hours', children: [
                      OnboardingField(
                          controller: _openingHoursController,
                          label: 'Opens at',
                          readOnly: true,
                          icon: Icons.schedule,
                          onTap: () => _pickHours(_openingHoursController)),
                      OnboardingField(
                          controller: _closingHoursController,
                          label: 'Closes at',
                          readOnly: true,
                          icon: Icons.schedule,
                          onTap: () => _pickHours(_closingHoursController)),
                    ]),
                    OnboardingCard(
                        title: 'Store images',
                        subtitle:
                            'Give the merchant a recognizable storefront.',
                        children: [
                          OnboardingImageUpload(
                              label: 'Logo',
                              value: _logoUrl,
                              onChanged: (url) =>
                                  setState(() => _logoUrl = url),
                              onBusyChanged: (busy) => setState(() => busy
                                  ? _imageUploads.add('logo')
                                  : _imageUploads.remove('logo'))),
                          OnboardingImageUpload(
                              label: 'Banner',
                              value: _bannerUrl,
                              banner: true,
                              onChanged: (url) =>
                                  setState(() => _bannerUrl = url),
                              onBusyChanged: (busy) => setState(() => busy
                                  ? _imageUploads.add('banner')
                                  : _imageUploads.remove('banner'))),
                        ]),
                  ])),
          OnboardingStep(
              label: 'Review',
              title: 'Ready to welcome this vendor?',
              description:
                  'Check the details below. You can edit any section before creating the account.',
              builder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OnboardingCard(
                            title: 'Business',
                            onEdit: () => _flowKey.currentState?.goToStep(0),
                            children: [
                              onboardingSummary('Store', _storeController.text),
                              onboardingSummary(
                                  'Merchant group',
                                  _merchantGroups
                                      .where((g) => g['slug'] == _merchantGroup)
                                      .map((g) => g['name'])
                                      .join()),
                              onboardingSummary(
                                  'Address', _addressController.text),
                              onboardingSummary(
                                  'Description', _descriptionController.text),
                            ]),
                        OnboardingCard(
                            title: 'Owner account',
                            onEdit: () => _flowKey.currentState?.goToStep(1),
                            children: [
                              onboardingSummary('Owner', _ownerController.text),
                              onboardingSummary('Email', _emailController.text),
                              onboardingSummary('Phone', _phoneController.text),
                              onboardingSummary(
                                  'Password', 'Set • Hidden for privacy'),
                            ]),
                        OnboardingCard(
                            title: 'Storefront',
                            onEdit: () => _flowKey.currentState?.goToStep(2),
                            children: [
                              onboardingSummary('Operating hours',
                                  '${_openingHoursController.text} – ${_closingHoursController.text}'),
                              onboardingSummary('Images',
                                  'Logo: ${_logoUrl.isEmpty ? 'Not added' : 'Uploaded'} · Banner: ${_bannerUrl.isEmpty ? 'Not added' : 'Uploaded'}'),
                            ]),
                        const OnboardingNotice(
                            text:
                                'After account creation, the merchant signs in to complete their private KYC and required guarantor details. Your commission is managed by admin.'),
                      ])),
        ],
      );
}

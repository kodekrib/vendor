import 'package:flutter/material.dart';

import '../app.dart';
import '../models/onboarding.dart';
import '../services/auth_service.dart';
import '../services/onboard_service.dart';

/// Field form for onboarding a new vendor with KYC documents.
class OnboardVendorScreen extends StatefulWidget {
  const OnboardVendorScreen({super.key});

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
  final _ninController = TextEditingController();
  final _idCardController = TextEditingController();
  final _cacController = TextEditingController();
  final _openingHoursController = TextEditingController(text: '08:00');
  final _closingHoursController = TextEditingController(text: '22:00');
  final _bannerUrlController = TextEditingController();
  final _logoUrlController = TextEditingController();

  String _category = vendorCategories.first;
  double _deliveryFee = 500;

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
    _ninController.dispose();
    _idCardController.dispose();
    _cacController.dispose();
    _openingHoursController.dispose();
    _closingHoursController.dispose();
    _bannerUrlController.dispose();
    _logoUrlController.dispose();
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
        _ninController.text.trim().isEmpty ||
        _idCardController.text.trim().isEmpty) {
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
      storeDesc: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      nin: _ninController.text.trim(),
      identityCardUrl: _idCardController.text.trim(),
      cacRegNo: _cacController.text.trim(),
      address: _addressController.text.trim(),
      openingHours: _openingHoursController.text.trim(),
      closingHours: _closingHoursController.text.trim(),
      bannerUrl: _bannerUrlController.text.trim(),
      logoUrl: _logoUrlController.text.trim(),
      deliveryFee: _deliveryFee,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vendor onboarded successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboard vendor')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'You become the account officer for this vendor. Their '
                          'commission rate is set by the MarketGO admin panel.',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF1E40AF),
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          _error!,
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
              const SizedBox(height: 20),

              // --- Store Info ---
              _sectionHeader('Store Information'),
              const SizedBox(height: 10),
              TextField(
                controller: _storeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Store name',
                  hintText: 'e.g. FreshCart',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ownerController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Owner name',
                  hintText: 'e.g. Amina Bello',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Business email',
                  hintText: 'vendor@marketgo.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Min 8 characters',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+234 802 000 0000',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addressController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Store address',
                  hintText: 'Street, Area, City',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: vendorCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 24),

              // --- Store Settings ---
              _sectionHeader('Store Settings'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _openingHoursController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Opening hours',
                        hintText: '08:00',
                        prefixIcon: Icon(Icons.access_time_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _closingHoursController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Closing hours',
                        hintText: '22:00',
                        prefixIcon: Icon(Icons.access_time_filled_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bannerUrlController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Banner image URL (optional)',
                  hintText: 'Link to store banner image',
                  prefixIcon: Icon(Icons.photo_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _logoUrlController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Logo image URL (optional)',
                  hintText: 'Link to store logo image',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<double>(
                value: _deliveryFee,
                decoration: InputDecoration(
                  labelText: 'Delivery fee (${OnboarderApp.currencySymbol})',
                  prefixIcon: const Icon(Icons.delivery_dining_rounded),
                ),
                items: const [0, 500, 1000, 1500, 2000, 2500, 3000]
                    .map((f) => DropdownMenuItem(
                          value: f.toDouble(),
                          child: Text(f == 0 ? 'Free' : '${OnboarderApp.currencySymbol}${f.toInt()}'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _deliveryFee = v ?? _deliveryFee),
              ),
              const SizedBox(height: 24),

              // --- KYC Documents ---
              _sectionHeader('KYC Documents (Required)'),
              const SizedBox(height: 10),
              TextField(
                controller: _ninController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'NIN (National Identification Number)',
                  hintText: '11-digit NIN',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _idCardController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Identity Card URL',
                  hintText: 'Link to uploaded ID card image',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _cacController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'CAC Registration No. (optional)',
                  hintText: 'Business registration number',
                  prefixIcon: Icon(Icons.business_center_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Onboard vendor'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0D9488),
        letterSpacing: 0.3,
      ),
    );
  }
}

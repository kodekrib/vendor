import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/onboard_service.dart';

/// Field form for onboarding a new delivery rider with full KYC documents.
class OnboardRiderScreen extends StatefulWidget {
  const OnboardRiderScreen({super.key});

  @override
  State<OnboardRiderScreen> createState() => _OnboardRiderScreenState();
}

class _OnboardRiderScreenState extends State<OnboardRiderScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ninController = TextEditingController();
  final _licenseController = TextEditingController();
  final _lasrraController = TextEditingController();
  final _vehicleRegController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _vehicleBrandController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedVehicleType;
  List<Map<String, dynamic>> _vehicleTypes = [];
  String _vehicleColor = '#111418';
  DateTime? _selectedDob;

  static const _colorOptions = [
    '#111418',
    '#2563EB',
    '#16A34A',
    '#DC2626',
    '#D97706',
    '#7C3AED',
  ];

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    final token = OnboarderSession.instance.accessToken;
    if (token == null || token == 'demo.access') {
      setState(() {
        _vehicleTypes = [
          {'id': 1, 'name': 'bike', 'label': 'Bike'},
          {'id': 2, 'name': 'sedan', 'label': 'Sedan'},
          {'id': 3, 'name': 'lorry', 'label': 'Lorry'},
        ];
      });
      return;
    }
    try {
      final api = ApiClient();
      final data = await api.get('/api/v1/onboarder/vehicle-types',
          headers: {'Authorization': 'Bearer $token'});
      final list = data['vehicle_types'];
      if (list is List) {
        setState(() {
          _vehicleTypes = list
              .whereType<Map<String, dynamic>>()
              .where((v) => v['is_active'] == true)
              .map((v) => {
                    'id': v['id'],
                    'name': v['name'],
                    'label': v['label'],
                  })
              .toList();
        });
      }
    } catch (_) {
      setState(() {
        _vehicleTypes = [
          {'id': 1, 'name': 'bike', 'label': 'Bike'},
          {'id': 2, 'name': 'sedan', 'label': 'Sedan'},
          {'id': 3, 'name': 'lorry', 'label': 'Lorry'},
        ];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ninController.dispose();
    _licenseController.dispose();
    _lasrraController.dispose();
    _vehicleRegController.dispose();
    _insuranceController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime(now.year - 18),
      helpText: 'SELECT DATE OF BIRTH',
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().length < 8 ||
        _phoneController.text.trim().isEmpty ||
        _ninController.text.trim().isEmpty ||
        _licenseController.text.trim().isEmpty ||
        _lasrraController.text.trim().isEmpty ||
        _vehicleRegController.text.trim().isEmpty ||
        _insuranceController.text.trim().isEmpty ||
        _dobController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      setState(() => _error = 'Fill in every field to continue.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = OnboarderSession.instance.accessToken;
    if (token == null || token == 'demo.access') {
      setState(() {
        _submitting = false;
        _error = 'Please sign in with a real account to onboard riders.';
      });
      return;
    }

    String vehicleTypeName = '';
    if (_selectedVehicleType != null) {
      for (final v in _vehicleTypes) {
        if ('${v['id']}' == _selectedVehicleType) {
          vehicleTypeName = (v['name'] as String?) ?? '';
          break;
        }
      }
    }

    final error = await OnboardService.instance.onboardRider(
      token: token,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      nin: _ninController.text.trim(),
      driversLicenseNo: _licenseController.text.trim(),
      lasrraPermitNo: _lasrraController.text.trim(),
      vehicleTypeId: _selectedVehicleType,
      vehicleRegNo: _vehicleRegController.text.trim(),
      insuranceNo: _insuranceController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      address: _addressController.text.trim(),
      vehicleBrand: _vehicleBrandController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
      vehicleType: vehicleTypeName,
      vehicleColor: _vehicleColor,
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
      const SnackBar(content: Text('Rider onboarded successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboard rider')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
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
                const SizedBox(height: 16),
              ],
              // --- Basic Info ---
              _sectionHeader('Basic Information'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Rider name',
                  hintText: 'e.g. Adewale Johnson',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'rider@marketgo.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+234 805 000 0000',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
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
              const SizedBox(height: 24),

              // --- KYC Documents ---
              _sectionHeader('KYC Documents (Required by FRSC / LASRRA)'),
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
                controller: _licenseController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Driver's License Number",
                  hintText: 'FRSC-issued license number',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _lasrraController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'LASRRA Permit Number',
                  hintText: 'Lagos State resident permit',
                  prefixIcon: Icon(Icons.verified_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _insuranceController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Insurance Number',
                  hintText: 'Motor insurance policy number',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // --- Vehicle Details ---
              _sectionHeader('Vehicle Details'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle type',
                  prefixIcon: Icon(Icons.two_wheeler_rounded),
                ),
                items: _vehicleTypes
                    .map((v) => DropdownMenuItem(
                          value: '${v['id']}',
                          child: Text(v['label']),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedVehicleType = v),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _vehicleRegController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Registration Number',
                  hintText: 'e.g. ABC-123-DE',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _vehicleBrandController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Brand',
                  hintText: 'e.g. Toyota',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _vehicleModelController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model (optional)',
                  hintText: 'e.g. Hilux',
                  prefixIcon: Icon(Icons.car_rental_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vehicle Colour',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _colorOptions.map((c) {
                  final selected = _vehicleColor == c;
                  final parsed = _parseColor(c);
                  return InkWell(
                    onTap: () => setState(() => _vehicleColor = c),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: parsed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: selected ? 3 : 1,
                          color: selected
                              ? const Color(0xFF0D9488)
                              : const Color(0xFFE2E5EA),
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 15, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // --- Personal Details ---
              _sectionHeader('Personal Details'),
              const SizedBox(height: 10),
              TextField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDob,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addressController,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Home Address',
                  hintText: 'Street, Area, City, State',
                  prefixIcon: Icon(Icons.home_outlined),
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
                      : const Text('Onboard rider'),
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

Color? _parseColor(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  final code = int.tryParse(value, radix: 16);
  if (code == null) return null;
  return Color(code);
}

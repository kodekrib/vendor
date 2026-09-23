import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/onboard_service.dart';

/// Field form for onboarding a new mover rider (heavy-movement vehicles).
///
/// Mirrors [OnboardRiderScreen] but covers the [OnboardMoverRequest] contract:
/// email, password, display name and the onboarder's commission rate against
/// moving-job commissions. Vehicle details (pickup truck / van / mini truck /
/// lorry) are added later by the rider from within the rider app.
class OnboardMoverScreen extends StatefulWidget {
  const OnboardMoverScreen({super.key});

  @override
  State<OnboardMoverScreen> createState() => _OnboardMoverScreenState();
}

class _OnboardMoverScreenState extends State<OnboardMoverScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _commissionController = TextEditingController(text: '2.5');
  final _regController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _capacityController = TextEditingController();
  final _packerFeeController = TextEditingController(text: '5000');
  List<Map<String, dynamic>> _vehicleTypes = [];
  String _vehicleType = '';
  String _vehicleColor = '#111418';
  int _maxPackers = 2;

  static const _moverTypeFallback = [
    {'id': 1, 'name': 'pickup_truck', 'label': 'Pickup Truck'},
    {'id': 2, 'name': 'van', 'label': 'Van'},
    {'id': 3, 'name': 'mini_truck', 'label': 'Mini Truck'},
    {'id': 4, 'name': 'lorry', 'label': 'Lorry'},
  ];

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
      setState(() => _vehicleTypes = _moverTypeFallback);
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
              .where((v) => v['is_active'] == true &&
                  ['pickup_truck', 'van', 'mini_truck', 'lorry']
                      .contains(v['name']))
              .map((v) =>
                  {'id': v['id'], 'name': v['name'], 'label': v['label']})
              .toList();
          if (_vehicleTypes.isEmpty) {
            _vehicleTypes = _moverTypeFallback;
          }
        });
      }
    } catch (_) {
      setState(() => _vehicleTypes = _moverTypeFallback);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _commissionController.dispose();
    _regController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _capacityController.dispose();
    _packerFeeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().length < 8) {
      setState(() => _error = 'Name, email and a min-8-char password are required.');
      return;
    }
    final commission = double.tryParse(_commissionController.text.trim());
    if (commission == null || commission <= 0 || commission > 50) {
      setState(() => _error = 'Commission rate must be a number between 0 and 50.');
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
        _error = 'Please sign in with a real account to onboard movers.';
      });
      return;
    }

    final error = await OnboardService.instance.onboardMover(
      token: token,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      commissionRate: commission,
      vehicleBrand: _brandController.text.trim(),
      vehicleModel: _modelController.text.trim(),
      vehicleType: _vehicleType,
      vehicleColor: _vehicleColor,
      vehicleRegNo: _regController.text.trim(),
      vehicleCapacity: _capacityController.text.trim(),
      vehiclePackerFee: double.tryParse(_packerFeeController.text) ?? 0,
      vehicleMaxPackers: _maxPackers,
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
      const SnackBar(content: Text('Mover onboarded successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboard mover')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F6F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB7E0DA)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_shipping_rounded, color: Color(0xFF0D9488), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mover riders operate heavy-movement vehicles (pickup truck, '
                        'van, mini truck, lorry) for home-to-home moving jobs. They set '
                        'their own prices per move.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Basic Information'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Mover name',
                  hintText: 'e.g. Tunde Adebayo',
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
                  hintText: 'mover@marketgo.com',
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
              const SizedBox(height: 24),
              _sectionHeader('Commission'),
              const SizedBox(height: 10),
              TextField(
                controller: _commissionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Commission rate (%)',
                  hintText: 'e.g. 2.5',
                  helperText: 'Your % share of each moving job\u2019s platform commission.',
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader('Vehicle Details (optional now, editable in rider app)'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _vehicleType.isEmpty ? null : _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle type',
                  prefixIcon: Icon(Icons.local_shipping_rounded),
                ),
                items: _vehicleTypes
                    .map((v) => DropdownMenuItem(
                          value: v['name'] as String,
                          child: Text(v['label'] as String),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v ?? ''),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _brandController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Brand',
                  hintText: 'e.g. Toyota',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _modelController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model (optional)',
                  hintText: 'e.g. Hiace',
                  prefixIcon: Icon(Icons.car_rental_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _regController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  hintText: 'e.g. LAG-560-JKK',
                  prefixIcon: Icon(Icons.local_offer_outlined),
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
              const SizedBox(height: 16),
              TextField(
                controller: _capacityController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Capacity (optional)',
                  hintText: 'e.g. 1.5 tons / 12 chairs',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _packerFeeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Packer fee per person (₦)',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Max extra packers',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _maxPackers > 0
                              ? () => setState(() => _maxPackers--)
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        Text('$_maxPackers',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _maxPackers < 20
                              ? () => setState(() => _maxPackers++)
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      : const Text('Onboard mover'),
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
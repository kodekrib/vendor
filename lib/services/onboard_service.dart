import 'package:flutter/material.dart';
import '../models/onboarding.dart';
import 'api_client.dart';

/// API-backed onboarder data store.
///
/// Calls the marketgo-api onboarding endpoints and holds the onboarder's
/// vendors, riders, movers and earnings in real backend data.  The UI layer
/// reads from this service via its getters and reacts to data changes.
class OnboardService extends ChangeNotifier {
  OnboardService._({ApiClient? api})
      : _api = api ?? ApiClient(),
        _loading = false;

  static final OnboardService instance = OnboardService._();

  final ApiClient _api;

  // --- State ---

  OnboarderProfile? _profile;
  List<VendorRecord> _vendors = [];
  List<RiderRecord> _riders = [];
  List<MoverRecord> _movers = [];
  List<CommissionTxn> _txns = [];
  bool _loading = false;
  double _totalEarned = 0;
  double _vendorEarned = 0;
  double _riderEarned = 0;
  double _moverEarned = 0;

  // --- Getters (same interface as before, minus offline flag) ---

  OnboarderProfile? get profile => _profile;
  List<VendorRecord> get vendors => List.unmodifiable(_vendors);
  List<RiderRecord> get riders => List.unmodifiable(_riders);
  List<MoverRecord> get movers => List.unmodifiable(_movers);
  List<CommissionTxn> get txns => List.unmodifiable(_txns);
  bool get loading => _loading;

  int get activeVendors =>
      _vendors.where((v) => v.status == OnboardStatus.active).length;
  int get activeRiders =>
      _riders.where((r) => r.status == OnboardStatus.active).length;
  int get activeMovers =>
      _movers.where((m) => m.status == OnboardStatus.active).length;
  int get pendingCount =>
      _vendors.where((v) => v.status == OnboardStatus.pending).length +
      _riders.where((r) => r.status == OnboardStatus.pending).length +
      _movers.where((m) => m.status == OnboardStatus.pending).length;

  double get totalVendorCommission => _vendorEarned;
  double get totalRiderCommission => _riderEarned;
  double get totalMoverCommission => _moverEarned;
  int get totalOnboardingFees => 0;
  double get totalEarned => _totalEarned;

  Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

  /// Connect to the API and load all data.  Falls back to an empty state
  /// (no dummy data) when the backend is unreachable; the UI will show
  /// empty lists / placeholder text accordingly.
  Future<void> connect(String token) async {
    _loading = true;
    notifyListeners();
    await _loadProfile(token);
    await _loadVendors(token);
    await _loadRiders(token);
    await _loadMovers(token);
    await _loadEarnings(token);
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshProfile(String token) async {
    await _loadProfile(token);
    notifyListeners();
  }

  void disconnect() {
    _profile = null;
    _vendors = [];
    _riders = [];
    _movers = [];
    _txns = [];
    _totalEarned = _vendorEarned = _riderEarned = _moverEarned = 0;
    notifyListeners();
  }

  // --- API calls ---

  Future<void> _loadProfile(String token) async {
    try {
      final data =
          await _api.get('/api/v1/onboarder/profile', headers: _auth(token));
      final details = data['profile'] as Map<String, dynamic>;
      _profile = OnboarderProfile(
        name: details['name'] ?? 'Onboarder',
        email: details['email'] ?? '',
        phone: details['phone'] ?? '',
      );
    } catch (_) {
      _profile = null;
    }
  }

  Future<void> _loadVendors(String token) async {
    try {
      final data =
          await _api.get('/api/v1/onboarder/vendors', headers: _auth(token));
      final list = data['vendors'];
      if (list is! List) {
        _vendors = [];
        return;
      }
      _vendors = list.whereType<Map<String, dynamic>>().map((j) {
        return VendorRecord(
          id: '${j['vendor_id'] ?? 0}',
          storeName: j['store_name'] ?? '',
          ownerName: j['vendor_name'] ?? '',
          email: j['vendor_email'] ?? '',
          phone: j['vendor_phone'] ?? '',
          category: j['category'] ?? '',
          city: j['city'] ?? '',
          address: j['address'] ?? '',
          status: onboardStatusFromName(j['status'] ?? 'active'),
          commissionRate: (j['commission_rate'] as num?)?.toDouble() ?? 2.5,
          monthlyCommissions: (j['monthly_commissions'] as num?)?.toInt() ?? 0,
          icon: _iconFromName(j['store_type'] ?? 'store'),
          color: _colorFromName(j['store_type'] ?? 'store'),
          joinedOn: j['onboarded_at'] ?? '',
        );
      }).toList();
    } catch (_) {
      _vendors = [];
    }
  }

  Future<void> _loadRiders(String token) async {
    try {
      final data =
          await _api.get('/api/v1/onboarder/riders', headers: _auth(token));
      final list = data['riders'];
      if (list is! List) {
        _riders = [];
        return;
      }
      _riders = list.whereType<Map<String, dynamic>>().map((j) {
        return RiderRecord(
          id: '${j['rider_id'] ?? 0}',
          name: j['rider_name'] ?? '',
          email: j['rider_email'] ?? '',
          phone: j['rider_phone'] ?? '',
          vehicle: j['vehicle_type'] ?? '',
          city: j['city'] ?? '',
          status: onboardStatusFromName(j['status'] ?? 'active'),
          monthlyFareShare: (j['fare_share'] as num?)?.toInt() ?? 0,
          icon: _iconFromName(j['vehicle_type'] ?? 'two_wheeler'),
          color: _colorFromName(j['vehicle_type'] ?? 'two_wheeler'),
          joinedOn: j['onboarded_at'] ?? '',
        );
      }).toList();
    } catch (_) {
      _riders = [];
    }
  }

  Future<void> _loadMovers(String token) async {
    try {
      final data =
          await _api.get('/api/v1/onboarder/movers', headers: _auth(token));
      final list = data['movers'];
      if (list is! List) {
        _movers = [];
        return;
      }
      _movers = list.whereType<Map<String, dynamic>>().map((j) {
        return MoverRecord(
          id: '${j['rider_id'] ?? 0}',
          name: j['rider_name'] ?? '',
          email: j['rider_email'] ?? '',
          phone: j['rider_phone'] ?? '',
          vehicleType: j['vehicle_type'] ?? '',
          plateNumber: j['plate_number'] ?? '',
          status: onboardStatusFromName(j['status'] ?? 'active'),
          commissionRate: (j['commission_rate'] as num?)?.toDouble() ?? 2.5,
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFFEA580C),
          joinedOn: j['onboarded_at'] ?? '',
        );
      }).toList();
    } catch (_) {
      _movers = [];
    }
  }

  Future<void> _loadEarnings(String token) async {
    try {
      final data =
          await _api.get('/api/v1/onboarder/earnings', headers: _auth(token));
      _totalEarned = (data['total_earned'] as num?)?.toDouble() ?? 0;
      _vendorEarned = (data['vendor_earnings'] as num?)?.toDouble() ?? 0;
      _riderEarned = (data['rider_earnings'] as num?)?.toDouble() ?? 0;
      _moverEarned = (data['mover_earnings'] as num?)?.toDouble() ?? 0;
      final txList = data['transactions'];
      if (txList is! List) {
        _txns = [];
        return;
      }
      _txns = txList.whereType<Map<String, dynamic>>().map((j) {
        final kind = j['type'] == 'vendor_order'
            ? CommissionKind.vendor
            : j['type'] == 'rider_delivery'
                ? CommissionKind.rider
                : j['type'] == 'mover_job'
                    ? CommissionKind.mover
                    : CommissionKind.vendor;
        final amount = (j['amount'] as num?)?.toDouble() ?? 0;
        return CommissionTxn(
          id: '${j['id'] ?? 0}',
          label: j['description'] ?? '',
          amount: amount,
          date: j['created_at'] ?? '',
          kind: kind,
        );
      }).toList();
    } catch (_) {
      _txns = [];
    }
  }

  // --- Onboard actions ---

  Future<String?> onboardVendor({
    required String token,
    required String email,
    required String password,
    required String name,
    required String storeName,
    required String storeDesc,
    required String phone,
    String address = '',
    String openingHours = '08:00',
    String closingHours = '22:00',
    String bannerUrl = '',
    String logoUrl = '',
    required String merchantGroup,
  }) async {
    try {
      await _api.post(
        '/api/v1/onboarder/vendors',
        headers: _auth(token),
        body: {
          'email': email,
          'password': password,
          'name': name,
          'store_name': storeName,
          'store_description': storeDesc,
          'address': address,
          'phone': phone,
          'opening_hours': openingHours,
          'closing_hours': closingHours,
          'banner_url': bannerUrl,
          'logo_url': logoUrl,
          'merchant_group': merchantGroup,
        },
      );
      await _loadVendors(token);
      notifyListeners();
      return null; // success
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> onboardRider({
    required String token,
    required Map<String, dynamic> assistedDocuments,
    required String email,
    required String password,
    required String name,
    required String phone,
    String driversLicenseNo = '',
    String lasrraPermitNo = '',
    String? vehicleTypeId,
    String vehicleRegNo = '',
    String insuranceNo = '',
    String dateOfBirth = '',
    String address = '',
    String vehicleBrand = '',
    String vehicleModel = '',
    String vehicleType = '',
    String vehicleColor = '',
  }) async {
    try {
      await _api.post(
        '/api/v1/onboarder/riders',
        headers: _auth(token),
        body: {
          ...assistedDocuments,
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'drivers_license_no': driversLicenseNo,
          'lasrra_permit_no': lasrraPermitNo,
          'vehicle_type_id':
              vehicleTypeId != null ? int.tryParse(vehicleTypeId) : null,
          'vehicle_reg_no': vehicleRegNo,
          'insurance_no': insuranceNo,
          'date_of_birth': dateOfBirth,
          'address': address,
          'profile_photo_url': '',
          'vehicle_brand': vehicleBrand,
          'vehicle_model': vehicleModel,
          'vehicle_type': vehicleType,
          'vehicle_color': vehicleColor,
        },
      );
      await _loadRiders(token);
      notifyListeners();
      return null; // success
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> onboardMover({
    required String token,
    required Map<String, dynamic> assistedDocuments,
    required String email,
    required String password,
    required String name,
    String vehicleBrand = '',
    String vehicleModel = '',
    String vehicleType = '',
    String vehicleColor = '',
    String vehicleRegNo = '',
    String vehicleCapacity = '',
    double vehiclePackerFee = 0,
    int vehicleMaxPackers = 2,
  }) async {
    try {
      await _api.post(
        '/api/v1/onboarder/movers',
        headers: _auth(token),
        body: {
          ...assistedDocuments,
          'email': email,
          'password': password,
          'name': name,
          'vehicle_brand': vehicleBrand,
          'vehicle_model': vehicleModel,
          'vehicle_type': vehicleType,
          'vehicle_color': vehicleColor,
          'vehicle_reg_no': vehicleRegNo,
          'vehicle_capacity': vehicleCapacity,
          'vehicle_packer_fee': vehiclePackerFee,
          'vehicle_max_packers': vehicleMaxPackers,
        },
      );
      await _loadMovers(token);
      notifyListeners();
      return null; // success
    } catch (e) {
      return '$e';
    }
  }

  /// Fetch commission detail for a specific vendor.
  Future<VendorCommissionDetail?> fetchVendorCommissionDetail(
      String token, int vendorId) async {
    try {
      final data = await _api.get(
        '/api/v1/onboarder/vendors/$vendorId/commission',
        headers: _auth(token),
      );
      return VendorCommissionDetail.fromJson(data);
    } catch (e) {
      debugPrint('Fetch vendor commission detail failed: $e');
      return null;
    }
  }

  /// Fetch commission detail for a specific rider.
  Future<RiderCommissionDetail?> fetchRiderCommissionDetail(
      String token, int riderId) async {
    try {
      final data = await _api.get(
        '/api/v1/onboarder/riders/$riderId/commission',
        headers: _auth(token),
      );
      return RiderCommissionDetail.fromJson(data);
    } catch (e) {
      debugPrint('Fetch rider commission detail failed: $e');
      return null;
    }
  }

  /// Fetch commission detail for a specific mover rider.
  Future<MoverCommissionDetail?> fetchMoverCommissionDetail(
      String token, int riderId) async {
    try {
      final data = await _api.get(
        '/api/v1/onboarder/movers/$riderId/commission',
        headers: _auth(token),
      );
      return MoverCommissionDetail.fromJson(data);
    } catch (e) {
      debugPrint('Fetch mover commission detail failed: $e');
      return null;
    }
  }

  Future<void> refresh(String token) async {
    _loading = true;
    notifyListeners();
    await _loadProfile(token);
    await _loadVendors(token);
    await _loadRiders(token);
    await _loadMovers(token);
    await _loadEarnings(token);
    _loading = false;
    notifyListeners();
  }

  // --- Helpers for parsing vendor/rider type names into Icon / Color ---

  IconData _iconFromName(String name) {
    final n = name.toLowerCase();
    if (n.contains('motorcycle') || n.contains('bike')) {
      return Icons.motorcycle_rounded;
    }
    if (n.contains('bicycle')) return Icons.directions_bike_rounded;
    if (n.contains('car') || n.contains('sedan') || n.contains('vehicle')) {
      return Icons.directions_car_rounded;
    }
    if (n.contains('van')) return Icons.local_shipping_rounded;
    if (n.contains('truck') || n.contains('lorry')) {
      return Icons.local_shipping_rounded;
    }
    return Icons.store_rounded;
  }

  Color _colorFromName(String name) {
    final n = name.toLowerCase();
    if (n.contains('motorcycle') || n.contains('bike')) {
      return const Color(0xFF0D9488);
    }
    if (n.contains('bicycle')) return const Color(0xFF115E59);
    if (n.contains('car') || n.contains('sedan') || n.contains('vehicle')) {
      return const Color(0xFF0D9488);
    }
    if (n.contains('van')) return const Color(0xFF16A34A);
    if (n.contains('truck') || n.contains('lorry')) {
      return const Color(0xFFEA580C);
    }
    return const Color(0xFF6B7280);
  }
}

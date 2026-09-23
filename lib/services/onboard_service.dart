import 'package:flutter/material.dart';
import '../models/onboarding.dart';
import 'api_client.dart';

/// API-backed onboarder data store.
///
/// Replaces the in-memory [OnboardRepository] with real calls to the
/// marketgo-api onboarding endpoints. The UI layer reads from this service
/// via the same getters, so screens need minimal changes.
class OnboardService extends ChangeNotifier {
  OnboardService._({ApiClient? api, this.onOfflineChanged})
      : _api = api ?? ApiClient();

  static final OnboardService instance = OnboardService._();

  final ApiClient _api;
  final void Function(bool offline)? onOfflineChanged;

  OnboarderProfile? _profile;
  List<VendorRecord> _vendors = [];
  List<RiderRecord> _riders = [];
  List<MoverRecord> _movers = [];
  List<CommissionTxn> _txns = [];
  bool _loading = false;
  bool _isOffline = true; // start offline until connected

  // --- Getters (same interface as OnboardRepository) ---

  OnboarderProfile? get profile => _profile;
  List<VendorRecord> get vendors => List.unmodifiable(_vendors);
  List<RiderRecord> get riders => List.unmodifiable(_riders);
  List<MoverRecord> get movers => List.unmodifiable(_movers);
  List<CommissionTxn> get txns => List.unmodifiable(_txns);
  bool get loading => _loading;
  bool get isOffline => _isOffline;

  int get activeVendors => _vendors.where((v) => v.status == OnboardStatus.active).length;
  int get activeRiders => _riders.where((r) => r.status == OnboardStatus.active).length;
  int get activeMovers => _movers.where((m) => m.status == OnboardStatus.active).length;
  int get pendingCount =>
      _vendors.where((v) => v.status == OnboardStatus.pending).length +
      _riders.where((r) => r.status == OnboardStatus.pending).length +
      _movers.where((m) => m.status == OnboardStatus.pending).length;

  int get totalVendorCommission =>
      _txns.where((t) => t.kind == CommissionKind.vendor).fold(0, (s, t) => s + t.amount);
  int get totalRiderCommission =>
      _txns.where((t) => t.kind == CommissionKind.rider).fold(0, (s, t) => s + t.amount);
  int get totalMoverCommission =>
      _txns.where((t) => t.kind == CommissionKind.mover).fold(0, (s, t) => s + t.amount);
  int get totalOnboardingFees => 0; // no onboarding fees in production
  int get totalEarned => _txns.fold(0, (sum, t) => sum + t.amount);

  Map<String, String> _auth(String token) =>
      {'Authorization': 'Bearer $token'};

  /// Attempt to connect to the API. Falls back to offline mode on failure.
  Future<void> connect(String token) async {
    if (token == 'demo.access') {
      _isOffline = true;
      onOfflineChanged?.call(true);
      notifyListeners();
      return;
    }
    _isOffline = false;
    onOfflineChanged?.call(false);
    await _loadDashboard(token);
    await _loadVendors(token);
    await _loadRiders(token);
    await _loadMovers(token);
    await _loadEarnings(token);
  }

  void disconnect() {
    _isOffline = true;
    _profile = null;
    _vendors = [];
    _riders = [];
    _movers = [];
    _txns = [];
    notifyListeners();
  }

  // --- API calls ---

  Future<void> _loadDashboard(String token) async {
    try {
      final data = await _api.get('/api/v1/onboarder/dashboard', headers: _auth(token));
      _profile = OnboarderProfile(
        name: data['name'] ?? 'Onboarder',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
      );
    } catch (_) {
      _profile = const OnboarderProfile(
        name: 'Onboarder',
        email: '',
        phone: '',
      );
    }
  }

  Future<void> _loadVendors(String token) async {
    try {
      final data = await _api.get('/api/v1/onboarder/vendors', headers: _auth(token));
      final list = data['vendors'];
      if (list is! List) { _vendors = []; return; }
      _vendors = list.whereType<Map<String, dynamic>>().map((j) {
        return VendorRecord(
          id: '${j['id'] ?? 0}',
          storeName: j['store_name'] ?? '',
          ownerName: j['vendor_name'] ?? '',
          email: j['vendor_email'] ?? '',
          phone: '',
          category: '',
          city: '',
          address: '',
          status: OnboardStatus.active,
          commissionRate: (j['commission_rate'] as num?)?.toDouble() ?? 2.5,
          monthlyCommissions: 0,
          icon: Icons.store_rounded,
          color: const Color(0xFF16A34A),
          joinedOn: j['onboarded_at'] ?? '',
        );
      }).toList();
    } catch (_) {
      _vendors = [];
    }
  }

  Future<void> _loadRiders(String token) async {
    try {
      final data = await _api.get('/api/v1/onboarder/riders', headers: _auth(token));
      final list = data['riders'];
      if (list is! List) { _riders = []; return; }
      _riders = list.whereType<Map<String, dynamic>>().map((j) {
        return RiderRecord(
          id: '${j['id'] ?? 0}',
          name: j['rider_name'] ?? '',
          email: j['rider_email'] ?? '',
          phone: '',
          vehicle: '',
          city: '',
          status: OnboardStatus.active,
          monthlyFareShare: 0,
          icon: Icons.two_wheeler_rounded,
          color: const Color(0xFF0D9488),
          joinedOn: j['onboarded_at'] ?? '',
        );
      }).toList();
    } catch (_) {
      _riders = [];
    }
  }

  Future<void> _loadMovers(String token) async {
    try {
      final data = await _api.get('/api/v1/onboarder/movers', headers: _auth(token));
      final list = data['movers'];
      if (list is! List) { _movers = []; return; }
      _movers = list.whereType<Map<String, dynamic>>().map((j) {
        return MoverRecord(
          id: '${j['id'] ?? 0}',
          name: j['rider_name'] ?? '',
          email: j['rider_email'] ?? '',
          phone: '',
          vehicleType: '',
          plateNumber: '',
          status: OnboardStatus.active,
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
      final data = await _api.get('/api/v1/onboarder/earnings', headers: _auth(token));
      final txList = data['transactions'];
      if (txList is! List) { _txns = []; return; }
      _txns = txList.whereType<Map<String, dynamic>>().map((j) {
        final kind = j['type'] == 'vendor_order'
            ? CommissionKind.vendor
            : j['type'] == 'rider_delivery'
                ? CommissionKind.rider
                : j['type'] == 'mover_job'
                    ? CommissionKind.mover
                    : CommissionKind.vendor;
        final amount = ((j['amount'] as num?)?.toDouble() ?? 0).toInt();
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
    required String nin,
    required String identityCardUrl,
    String cacRegNo = '',
    String address = '',
    String openingHours = '08:00',
    String closingHours = '22:00',
    String bannerUrl = '',
    String logoUrl = '',
    double deliveryFee = 500,
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
          'phone': phone,
          'opening_hours': openingHours,
          'closing_hours': closingHours,
          'banner_url': bannerUrl,
          'logo_url': logoUrl,
          'delivery_fee': deliveryFee,
        },
      );
      // Submit KYC for the newly created vendor.
      // We need the vendor's user ID — the onboard endpoint returns it.
      // For now, reload vendors which will pick up the new one.
      await _loadVendors(token);
      notifyListeners();
      return null; // success
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> onboardRider({
    required String token,
    required String email,
    required String password,
    required String name,
    required String phone,
    String nin = '',
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
      // The backend persists rider KYC details up front during onboarding,
      // so the whole payload is sent in a single request.
      await _api.post(
        '/api/v1/onboarder/riders',
        headers: _auth(token),
        body: {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'nin': nin,
          'drivers_license_no': driversLicenseNo,
          'lasrra_permit_no': lasrraPermitNo,
          'vehicle_type_id': vehicleTypeId != null ? int.tryParse(vehicleTypeId) : null,
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
    required String email,
    required String password,
    required String name,
    double commissionRate = 2.5,
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
          'email': email,
          'password': password,
          'name': name,
          'commission_rate': commissionRate,
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

  /// Fetch commission detail for a specific rider.
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
    if (token == 'demo.access') return;
    _loading = true;
    notifyListeners();
    await _loadDashboard(token);
    await _loadVendors(token);
    await _loadRiders(token);
    await _loadMovers(token);
    await _loadEarnings(token);
    _loading = false;
    notifyListeners();
  }
}

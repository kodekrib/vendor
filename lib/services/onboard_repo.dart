import 'package:flutter/material.dart';
import '../models/onboarding.dart';

/// Offline data store for the onboarder app.
///
/// Everything is seeded in-memory so the app is fully explorable without the
/// backend / database. Production wiring will POST these records to the
/// marketgo-api onboarding endpoints; the UI layer is already built around
/// this repository so the swap is transparent.
class OnboardRepository extends ChangeNotifier {
  OnboardRepository._() {
    _seed();
  }

  static final OnboardRepository instance = OnboardRepository._();

  final OnboarderProfile _profile = const OnboarderProfile(
    name: 'Olabisi Adeyemi',
    email: 'onboarder@marketgo.com',
    phone: '+234 803 000 1111',
  );

  final List<VendorRecord> _vendors = [];
  final List<RiderRecord> _riders = [];
  final List<CommissionTxn> _txns = [];

  OnboarderProfile get profile => _profile;
  List<VendorRecord> get vendors => List.unmodifiable(_vendors);
  List<RiderRecord> get riders => List.unmodifiable(_riders);
  List<CommissionTxn> get txns => List.unmodifiable(_txns);

  int get activeVendors => _vendors.where((v) => v.status == OnboardStatus.active).length;
  int get activeRiders => _riders.where((r) => r.status == OnboardStatus.active).length;
  int get pendingCount => _vendors.where((v) => v.status == OnboardStatus.pending).length +
      _riders.where((v) => v.status == OnboardStatus.pending).length;

  int get totalVendorCommission =>
      _txns.where((t) => t.kind == CommissionKind.vendor).fold(0, (s, t) => s + t.amount);
  int get totalRiderCommission =>
      _txns.where((t) => t.kind == CommissionKind.rider).fold(0, (s, t) => s + t.amount);
  int get totalEarned =>
      _txns.fold(0, (sum, t) => sum + t.amount);

  void addVendor(VendorRecord record) {
    _vendors.add(record);
    notifyListeners();
  }

  void addRider(RiderRecord record) {
    _riders.add(record);
    notifyListeners();
  }

  void _seed() {
    _vendors.addAll(const [
      VendorRecord(
        id: 'VND-001',
        storeName: 'FreshCart',
        ownerName: 'Amina Bello',
        email: 'fresh@marketgo.com',
        phone: '+234 802 111 2233',
        category: 'Groceries',
        city: 'Ikeja',
        address: '14 Simbiat Abiola Way, Ikeja',
        status: OnboardStatus.active,
        commissionRate: 2.5,
        monthlyCommissions: 48200,
        icon: Icons.local_grocery_store_rounded,
        color: Color(0xFF16A34A),
        joinedOn: 'Aug 2026',
      ),
      VendorRecord(
        id: 'VND-002',
        storeName: 'TechHub Lagos',
        ownerName: 'Emeka Obi',
        email: 'tech@marketgo.com',
        phone: '+234 803 222 3344',
        category: 'Electronics',
        city: 'Yaba',
        address: '3 Herbert Macaulay Way, Yaba',
        status: OnboardStatus.active,
        commissionRate: 2.0,
        monthlyCommissions: 61200,
        icon: Icons.devices_rounded,
        color: Color(0xFF2563EB),
        joinedOn: 'Aug 2026',
      ),
      VendorRecord(
        id: 'VND-003',
        storeName: 'BeautyStack',
        ownerName: 'Ifeoma Nwosu',
        email: 'beauty@marketgo.com',
        phone: '+234 804 333 4455',
        category: 'Health & Beauty',
        city: 'Lekki',
        address: '9 Admiralty Way, Lekki Phase 1',
        status: OnboardStatus.pending,
        commissionRate: 3.0,
        monthlyCommissions: 0,
        icon: Icons.spa_rounded,
        color: Color(0xFFEC4899),
        joinedOn: 'Sep 2026',
      ),
    ]);

    _riders.addAll(const [
      RiderRecord(
        id: 'RDR-001',
        name: 'Adewale Johnson',
        email: 'adewale@marketgo.com',
        phone: '+234 805 444 5566',
        vehicle: 'Motorcycle',
        city: 'Lekki',
        status: OnboardStatus.active,
        monthlyFareShare: 18600,
        icon: Icons.two_wheeler_rounded,
        color: Color(0xFF0D9488),
        joinedOn: 'Aug 2026',
      ),
      RiderRecord(
        id: 'RDR-002',
        name: 'Chidinma Eze',
        email: 'chidinma@marketgo.com',
        phone: '+234 806 555 6677',
        vehicle: 'Car',
        city: 'Ikeja',
        status: OnboardStatus.pending,
        monthlyFareShare: 0,
        icon: Icons.directions_car_rounded,
        color: Color(0xFFF97316),
        joinedOn: 'Sep 2026',
      ),
    ]);

    _txns.addAll(const [
      CommissionTxn(
        id: 'TXN-001',
        label: 'Commission · FreshCart orders',
        amount: 1205,
        date: 'Today',
        kind: CommissionKind.vendor,
      ),
      CommissionTxn(
        id: 'TXN-002',
        label: 'Commission · TechHub Lagos orders',
        amount: 1530,
        date: 'Yesterday',
        kind: CommissionKind.vendor,
      ),
      CommissionTxn(
        id: 'TXN-003',
        label: 'Commission · Gbedu Movers jobs',
        amount: 2200,
        date: 'Aug 28',
        kind: CommissionKind.vendor,
      ),
      CommissionTxn(
        id: 'TXN-004',
        label: 'Commission · Yoruba Fashion orders',
        amount: 2890,
        date: 'Aug 24',
        kind: CommissionKind.vendor,
      ),
      CommissionTxn(
        id: 'TXN-005',
        label: 'Delivery commission · Adewale Johnson',
        amount: 465,
        date: 'Yesterday',
        kind: CommissionKind.rider,
      ),
    ]);
  }
}
import 'package:flutter/material.dart';

import '../app.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Displays the onboarder's KYC review status and submitted documents.
class KYCStatusScreen extends StatefulWidget {
  const KYCStatusScreen({super.key});

  @override
  State<KYCStatusScreen> createState() => _KYCStatusScreenState();
}

class _KYCStatusScreenState extends State<KYCStatusScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = OnboarderSession.instance.accessToken;
    if (token == null || token == 'demo.access') {
      setState(() {
        _loading = false;
        _profile = null;
      });
      return;
    }
    try {
      final api = ApiClient();
      final data = await api.get('/api/v1/onboarder/profile',
          headers: {'Authorization': 'Bearer $token'});
      setState(() {
        _profile = data['profile'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status banner
                  _buildStatusBanner(),
                  const SizedBox(height: 24),

                  // Submitted documents
                  _sectionHeader('Onboarder Profile'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _infoRow('Instagram', _profile?['instagram_handle'] ?? ''),
                    _infoRow('Twitter/X', _profile?['twitter_handle'] ?? ''),
                    _infoRow('LinkedIn', _profile?['linkedin_handle'] ?? ''),
                    _infoRow('Facebook', _profile?['facebook_handle'] ?? ''),
                    _infoRow('TikTok', _profile?['tiktok_handle'] ?? ''),
                    _infoRow('Profile Photo',
                        _profile?['profile_photo_url'] ?? 'Not uploaded'),
                  ]),
                  const SizedBox(height: 24),

                  // KYC info
                  _sectionHeader('About KYC Review'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BulletItem('KYC documents are reviewed within 2 business days.'),
                        _BulletItem('You will be notified once your documents are verified.'),
                        _BulletItem('Verified onboarders unlock full commission payouts.'),
                        _BulletItem(
                            'Ensure all documents are clear and legible before submitting.'),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFF8F1D16),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _profile?['kyc_status'] ?? 'pending';
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;
    String desc;

    switch (status) {
      case 'approved':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        icon = Icons.check_circle_rounded;
        label = 'Verified';
        desc = 'Your profile has been verified. Full payouts are unlocked.';
        break;
      case 'rejected':
        bgColor = const Color(0xFFFDECEC);
        textColor = const Color(0xFF8F1D16);
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        desc = _profile?['kyc_rejection_reason']?.isNotEmpty == true
            ? _profile!['kyc_rejection_reason']
            : 'Your documents were rejected. Please update and resubmit.';
        break;
      case 'under_review':
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1E40AF);
        icon = Icons.hourglass_top_rounded;
        label = 'Under Review';
        desc = 'Your documents are being reviewed. This usually takes 1-2 business days.';
        break;
      default:
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFF92400E);
        icon = Icons.info_outline_rounded;
        label = 'Pending';
        desc = 'Submit your KYC documents to get verified and unlock full payouts.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: textColor)),
                const SizedBox(height: 4),
                Text(desc,
                    style:
                        TextStyle(fontSize: 13, color: textColor, height: 1.4)),
              ],
            ),
          ),
        ],
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

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OnboarderApp.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0EE)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                fontSize: 13,
                color: value.isEmpty ? const Color(0xFF9CA3AF) : OnboarderApp.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  \u2022  ',
              style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w800)),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF1E3A5F), height: 1.4)),
          ),
        ],
      ),
    );
  }
}

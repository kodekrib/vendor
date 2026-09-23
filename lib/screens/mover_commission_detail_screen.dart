import 'package:flutter/material.dart';
import '../app.dart';
import '../models/onboarding.dart';
import '../services/onboard_service.dart';
import '../services/auth_service.dart';

class MoverCommissionDetailScreen extends StatefulWidget {
  final int riderId;
  final String riderName;

  const MoverCommissionDetailScreen({
    super.key,
    required this.riderId,
    required this.riderName,
  });

  @override
  State<MoverCommissionDetailScreen> createState() =>
      _MoverCommissionDetailScreenState();
}

class _MoverCommissionDetailScreenState
    extends State<MoverCommissionDetailScreen> {
  MoverCommissionDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = OnboarderSession.instance.accessToken ?? '';
    final detail = await OnboardService.instance
        .fetchMoverCommissionDetail(token, widget.riderId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.riderName} Commission'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('No commission data'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _detail!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(d),
          const SizedBox(height: 16),
          Text(
            'Moving History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (d.lines.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No moving jobs yet'),
              ),
            )
          else
            ...d.lines.map(_lineCard),
        ],
      ),
    );
  }

  Widget _summaryCard(MoverCommissionDetail d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.riderName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('Rate', '${d.commissionRate}%'),
                const SizedBox(width: 24),
                _stat('Jobs', '${d.totalJobs}'),
                const SizedBox(width: 24),
                _stat('Earned', '${OnboarderApp.currencySymbol}${d.totalEarnings.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                )),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
      ],
    );
  }

  Widget _lineCard(CommissionDetailLine l) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          'Job #${l.orderId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Fee: ${OnboarderApp.currencySymbol}${l.deliveryFee.toStringAsFixed(0)} · '
          'Rate: ${l.commissionRate}%',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${OnboarderApp.currencySymbol}${l.onboarderCut.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${l.date.day}/${l.date.month}/${l.date.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/api_client.dart';
import '../../data/healthreach_api.dart';

class PatientVisitsPage extends StatefulWidget {
  const PatientVisitsPage({super.key});

  @override
  State<PatientVisitsPage> createState() => _PatientVisitsPageState();
}

class _PatientVisitsPageState extends State<PatientVisitsPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  List<dynamic> _visits = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final visits = await _api.getMyVisits(limit: 20);
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load visits.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('My Medical Visits',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text('View your complete medical visit history',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined,
                        color: AppTheme.deepBlue),
                    const SizedBox(width: 8),
                    Text('Visit History',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const LinearProgressIndicator()
                else if (_error != null)
                  Text(
                    _error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(0xFFE06C75)),
                  )
                else if (_visits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                        'Your past medical appointments and consultations',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textMuted)),
                  )
                else
                  Column(
                    children: _visits
                        .whereType<Map<String, dynamic>>()
                        .map((visit) => _VisitRow(visit: visit))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.visit});

  final Map<String, dynamic> visit;

  @override
  Widget build(BuildContext context) {
    final type = visit['visitType'] ?? visit['visit_type'] ?? 'Visit';
    final date = visit['visitDate'] ??
        visit['visit_date'] ??
        visit['date'] ??
        visit['createdAt'] ??
        visit['created_at'];
    final status = visit['status'] ?? 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              color: AppTheme.deepBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                if (date != null)
                  Text(date.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(status.toString(),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

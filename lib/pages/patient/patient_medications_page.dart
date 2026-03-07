import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';

class PatientMedicationsPage extends StatefulWidget {
  const PatientMedicationsPage({super.key});

  @override
  State<PatientMedicationsPage> createState() => _PatientMedicationsPageState();
}

class _PatientMedicationsPageState extends State<PatientMedicationsPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  List<dynamic> _medications = const [];

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
      final meds = await _api.getMyMedications();
      if (!mounted) return;
      setState(() {
        _medications = meds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _medications = const [];
        _loading = false;
      });
    }
  }

  bool _isActiveMedication(Map<String, dynamic> medication) {
    final raw = medication['isActive'] ?? medication['is_active'];
    if (raw is bool) return raw;

    final text = raw?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'active') return true;
    if (text == 'false' || text == '0' || text == 'inactive') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final activeMedications = _medications
        .whereType<Map<String, dynamic>>()
        .where(_isActiveMedication)
        .toList();
    final activeCount = activeMedications.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('My Medications',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text('View your prescribed medications and stay on track',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final cards = [
                _MetricCard(
                  title: 'Active Medications',
                  subtitle: 'Currently active prescriptions',
                  value: activeCount.toString(),
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFFEFE8FF),
                ),
                const _MetricCard(
                  title: 'Stay On Schedule',
                  subtitle: 'Take as prescribed',
                  icon: Icons.schedule_outlined,
                  color: Color(0xFFE8F2FF),
                ),
                const _MetricCard(
                  title: 'Track Progress',
                  subtitle: 'Monitor your adherence',
                  icon: Icons.check_circle_outline,
                  color: Color(0xFFE6FFF2),
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[2]),
                  ],
                );
              }

              return Column(
                children: cards
                    .map((card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ))
                    .toList(),
              );
            },
          ),
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
                    const Icon(Icons.medical_services_outlined,
                        color: AppTheme.deepBlue),
                    const SizedBox(width: 8),
                    Text('My Current Medications',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 16),
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
                else if (_medications.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            size: 36, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        Text('No active medications',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textMuted)),
                        Text('Your prescribed medications will appear here.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textMuted)),
                      ],
                    ),
                  )
                else
                  Column(
                    children: activeMedications
                        .map((med) => _MedicationRow(medication: med))
                        .toList(),
                  ),
              ],
            ),
          ),
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
                Text('Medication Tips',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final tips = const [
                      _TipCard(
                        title: 'Set Reminders',
                        subtitle:
                            'Use phone alarms or a pill organizer to remember your doses.',
                      ),
                      _TipCard(
                        title: 'Take as Directed',
                        subtitle:
                            'Always follow your doctor\'s instructions for each medication.',
                      ),
                      _TipCard(
                        title: 'Do Not Skip Doses',
                        subtitle:
                            'Even if you feel better, complete your full course of medication.',
                      ),
                      _TipCard(
                        title: 'Report Side Effects',
                        subtitle:
                            'Contact your provider if you experience any unusual symptoms.',
                      ),
                    ];

                    if (isWide) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.8,
                        children: tips,
                      );
                    }

                    return Column(
                      children: tips
                          .map((tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: tip,
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.value,
  });

  final String title;
  final String subtitle;
  final String? value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          if (value != null)
            Text(value!,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({required this.medication});

  final Map<String, dynamic> medication;

  @override
  Widget build(BuildContext context) {
    final name = medication['medicationName'] ??
        medication['medication_name'] ??
        'Medication';
    final dosage = medication['dosage'] ?? 'N/A';
    final frequency = medication['frequency'] ?? 'N/A';

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
          const Icon(Icons.medical_services_outlined,
              color: AppTheme.deepBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                Text('$dosage  -  $frequency',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

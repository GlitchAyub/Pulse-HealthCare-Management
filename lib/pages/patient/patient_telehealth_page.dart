import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/api_client.dart';
import '../../data/healthreach_api.dart';

class PatientTelehealthPage extends StatefulWidget {
  const PatientTelehealthPage({super.key});

  @override
  State<PatientTelehealthPage> createState() => _PatientTelehealthPageState();
}

class _PatientTelehealthPageState extends State<PatientTelehealthPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  List<dynamic> _consultations = const [];
  String? _joiningConsultationId;

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
      final consultations = await _api.getMyConsultations(upcoming: true);
      if (!mounted) return;
      setState(() {
        _consultations = consultations;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _consultations = const [];
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _consultations = const [];
        _error = 'Unable to load consultations.';
        _loading = false;
      });
    }
  }

  Future<void> _joinConsultation(String consultationId) async {
    if (_joiningConsultationId == consultationId) return;

    setState(() => _joiningConsultationId = consultationId);

    try {
      await _api.updateConsultation(consultationId, {
        'status': 'active',
        'callStartTime': DateTime.now().toUtc().toIso8601String(),
      });
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation marked as active.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to join consultation right now.')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _joiningConsultationId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('My Virtual Consultations',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Connect with your healthcare provider from anywhere',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final cards = const [
              _HighlightCard(
                title: 'Video Visits',
                subtitle: 'See your doctor face to face from home',
                icon: Icons.videocam_outlined,
                color: Color(0xFFE8F2FF),
              ),
              _HighlightCard(
                title: 'Save Time',
                subtitle: 'No travel or waiting room time',
                icon: Icons.schedule_outlined,
                color: Color(0xFFE6FFF2),
              ),
              _HighlightCard(
                title: 'Same Quality Care',
                subtitle: 'Get the same care as in-person visits',
                icon: Icons.verified_outlined,
                color: Color(0xFFF3E8FF),
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
                  const Icon(Icons.calendar_today_outlined,
                      color: AppTheme.deepBlue),
                  const SizedBox(width: 8),
                  Text('My Scheduled Consultations',
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
              else if (_consultations.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Icon(Icons.videocam_outlined,
                          size: 36, color: AppTheme.textMuted),
                      const SizedBox(height: 8),
                      Text('No upcoming virtual consultations',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textMuted)),
                      Text(
                        'When your doctor schedules a video visit, it will appear here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _consultations
                      .whereType<Map<String, dynamic>>()
                      .map((consult) {
                    final consultationId = consult['id']?.toString().trim();
                    final status =
                        consult['status']?.toString().toLowerCase() ??
                            'scheduled';
                    final canJoin = consultationId != null &&
                        consultationId.isNotEmpty &&
                        (status == 'scheduled' ||
                            status == 'approved' ||
                            status == 'pending');
                    return _ConsultationRow(
                      consultation: consult,
                      joining: _joiningConsultationId == consultationId,
                      onJoin: canJoin
                          ? () => _joinConsultation(consultationId)
                          : null,
                    );
                  }).toList(),
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
              Text('How Virtual Visits Work',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                      child:
                          _StepCard(step: '1', title: 'Request Appointment')),
                  SizedBox(width: 12),
                  Expanded(child: _StepCard(step: '2', title: 'Get Confirmed')),
                  SizedBox(width: 12),
                  Expanded(child: _StepCard(step: '3', title: 'Join the Call')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
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
          const SizedBox(width: 10),
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
        ],
      ),
    );
  }
}

class _ConsultationRow extends StatelessWidget {
  const _ConsultationRow({
    required this.consultation,
    required this.joining,
    this.onJoin,
  });

  final Map<String, dynamic> consultation;
  final bool joining;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final type = consultation['consultationType'] ??
        consultation['consultation_type'] ??
        'Consultation';
    final status = consultation['status']?.toString() ?? 'scheduled';
    final scheduledTime =
        consultation['scheduledTime'] ?? consultation['scheduled_time'];
    final scheduleLabel = scheduledTime?.toString().trim().isNotEmpty == true
        ? scheduledTime.toString()
        : 'Time TBD';

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
          const Icon(Icons.video_call_outlined,
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
                const SizedBox(height: 2),
                Text(scheduleLabel,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(status,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppTheme.textMuted)),
              if (onJoin != null)
                TextButton(
                  onPressed: joining ? null : onJoin,
                  child: joining
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.skyBlue.withOpacity(0.2),
            child: Text(step,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppTheme.deepBlue)),
          ),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

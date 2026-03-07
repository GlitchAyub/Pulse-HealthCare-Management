import 'package:flutter/material.dart';
import '../data/api_mappers.dart';
import '../data/healthreach_api.dart';
import '../models/appointment.dart';
import '../models/vital_stat.dart';
import '../widgets/appointment_card.dart';
import '../widgets/date_range_card.dart';
import '../widgets/heart_monitor_card.dart';
import '../widgets/section_header.dart';
import '../widgets/vital_card.dart';
import '../widgets/welcome_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  List<VitalStat> _vitals = const [];
  List<Appointment> _appointments = const [];

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

    Map<String, dynamic>? stats;
    List<dynamic> requests = const [];
    String? error;

    try {
      stats = await _api.getDashboardStats();
    } catch (e) {
      error = e.toString();
    }

    try {
      requests = await _api.getAppointmentRequests();
    } catch (e) {
      error ??= e.toString();
    }

    final vitals = stats == null ? <VitalStat>[] : vitalsFromStats(stats);
    final appointments = requests
        .whereType<Map<String, dynamic>>()
        .map(appointmentFromRequest)
        .toList();

    if (!mounted) return;
    setState(() {
      _vitals = vitals.take(2).toList();
      _appointments = appointments;
      _error = error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 0) {
            return const SizedBox.shrink();
          }
          final isWide = constraints.maxWidth >= 700;
          final horizontalPadding = isWide ? 28.0 : 16.0;
          final availableWidth =
              (constraints.maxWidth - horizontalPadding * 2)
                  .clamp(0.0, double.infinity)
                  .toDouble();
          final cardWidth = isWide
              ? ((availableWidth - 12) / 2)
                  .clamp(0.0, double.infinity)
                  .toDouble()
              : availableWidth;

          final upcoming = _appointments
              .where((appointment) =>
                  appointment.status == AppointmentStatus.upcoming)
              .take(2)
              .toList();

          return RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WelcomeHeader(),
                  const SizedBox(height: 16),
                  const DateRangeCard(),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFE06C75)),
                        ),
                      ),
                    if (_vitals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No dashboard stats available yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFF6B7A90)),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _vitals
                            .map((stat) => SizedBox(
                                  width: cardWidth,
                                  child: VitalCard(
                                    stat: stat,
                                    icon: stat.title.contains('Patients')
                                        ? Icons.people_alt_rounded
                                        : Icons.monitor_heart_rounded,
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Heart Health Monitor',
                    actionLabel: 'View All',
                  ),
                  const SizedBox(height: 12),
                  const HeartMonitorCard(),
                  const SizedBox(height: 22),
                  const SectionHeader(
                    title: 'Upcoming',
                    actionLabel: 'See all',
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const SizedBox.shrink()
                  else if (upcoming.isEmpty)
                    Text(
                      'No upcoming appointments yet.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFF6B7A90)),
                    )
                  else
                    Column(
                      children: upcoming
                          .map((appointment) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppointmentCard(appointment: appointment),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

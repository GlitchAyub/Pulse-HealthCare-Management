import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/api_mappers.dart';
import '../data/healthreach_api.dart';
import '../models/appointment.dart';
import '../widgets/appointment_card.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/segmented_tabs.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final _api = HealthReachApi();
  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;
  List<Appointment> _appointments = const [];

  AppointmentStatus get _status {
    switch (_selectedIndex) {
      case 0:
        return AppointmentStatus.upcoming;
      case 1:
        return AppointmentStatus.completed;
      case 2:
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.upcoming;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await _api.getAppointmentRequests();
      final mapped = requests
          .whereType<Map<String, dynamic>>()
          .map(appointmentFromRequest)
          .toList();
      if (!mounted) return;
      setState(() {
        _appointments = mapped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _appointments
        .where((appointment) => appointment.status == _status)
        .toList();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final horizontalPadding = isWide ? 28.0 : 16.0;

          return RefreshIndicator(
            onRefresh: _loadAppointments,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Appointments',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedTabs(
                    labels: const ['Upcoming', 'Completed', 'Cancelled'],
                    selectedIndex: _selectedIndex,
                    onChanged: (index) => setState(() => _selectedIndex = index),
                  ),
                  const SizedBox(height: 16),
                  const CalendarStrip(),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFFE06C75)),
                      ),
                    )
                  else if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No appointments yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: filtered
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

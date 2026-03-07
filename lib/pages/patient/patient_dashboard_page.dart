import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../data/healthreach_api.dart';
import '../../widgets/app_select.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final _api = HealthReachApi();

  bool _loading = true;
  String? _error;
  int _totalVisits = 0;
  int _activeMedications = 0;
  int _pastMedications = 0;
  int _pendingRequests = 0;
  int _resourceCount = 0;
  int _upcomingConsultations = 0;

  List<Map<String, dynamic>> _requests = const [];
  Set<String> _cancellingIds = <String>{};

  static const Map<String, String> _requestTypes = {
    'consultation': 'Consultation',
    'checkup': 'Checkup',
    'followup': 'Follow-up',
    'specialist': 'Specialist',
  };

  static const Map<String, String> _visitModes = {
    'in_person': 'In-Person Visit',
    'virtual': 'Virtual Visit',
  };

  static const Map<String, String> _timeSlots = {
    'morning': 'Morning (8am - 12pm)',
    'afternoon': 'Afternoon (12pm - 5pm)',
    'evening': 'Evening (5pm - 9pm)',
  };

  static const Map<String, String> _urgencyOptions = {
    'normal': 'Normal',
    'urgent': 'Urgent',
  };

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

    String? loadError;

    Future<List<Map<String, dynamic>>> safeList(
        Future<List<dynamic>> future) async {
      try {
        final rows = await future;
        return rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      } on ApiException catch (error) {
        if (!_isSoftError(error) && loadError == null) {
          loadError = error.message;
        }
        return const [];
      } catch (error) {
        final text = error.toString().toLowerCase();
        if (text.contains('<!doctype html') || text.contains('<html')) {
          return const [];
        }
        loadError ??= error.toString();
        return const [];
      }
    }

    final results = await Future.wait<List<Map<String, dynamic>>>([
      safeList(_api.getAppointmentRequests()),
      safeList(_api.getHealthResources()),
      safeList(_api.getMyMedications()),
      safeList(_api.getMyVisits(limit: 20)),
      safeList(_api.getMyConsultations(upcoming: true)),
    ]);

    if (!mounted) return;

    final requests = results[0];
    final resources = results[1];
    final medications = results[2];
    final visits = results[3];
    final consultations = results[4];

    final activeMedications = medications.where(_isMedicationActive).toList();
    final pendingRequests = requests.where((row) {
      return _readString(row, const ['status'], fallback: 'pending')
              .toLowerCase() ==
          'pending';
    }).length;

    setState(() {
      _requests = [...requests]
        ..sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));
      _totalVisits = visits.length;
      _activeMedications = activeMedications.length;
      _pastMedications = (medications.length - activeMedications.length)
          .clamp(0, 999999)
          .toInt();
      _pendingRequests = pendingRequests;
      _resourceCount = resources.length;
      _upcomingConsultations = consultations.length;
      _error = loadError;
      _loading = false;
    });
  }

  bool _isSoftError(ApiException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == 401 ||
        error.statusCode == 403 ||
        error.statusCode == 404 ||
        error.statusCode == 405 ||
        error.statusCode == 501 ||
        message.contains('returned html instead of json');
  }

  bool _isMedicationActive(Map<String, dynamic> medication) {
    final raw = medication['isActive'] ?? medication['is_active'];
    if (raw is bool) return raw;
    final text = raw?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'active') return true;
    if (text == 'false' || text == '0' || text == 'inactive') return false;
    return true;
  }

  DateTime _sortDate(Map<String, dynamic> row) {
    final raw = row['created_at'] ??
        row['createdAt'] ??
        row['preferred_date'] ??
        row['preferredDate'];
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  String _readString(Map<String, dynamic> row, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _displayDate(dynamic value, {String fallback = 'TBD'}) {
    final text = value?.toString().trim() ?? '';
    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return DateFormat('MMM d, yyyy').format(parsed.toLocal());
    }
    return text.isEmpty ? fallback : text;
  }

  Future<void> _openRequestDialog() async {
    final reasonController = TextEditingController();
    String requestType = 'consultation';
    String visitMode = 'in_person';
    String timeSlot = 'morning';
    String urgency = 'normal';
    DateTime? preferredDate;
    String? formError;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final reason = reasonController.text.trim();
              if (preferredDate == null || reason.isEmpty) {
                setDialogState(() {
                  formError = 'Preferred date and reason are required.';
                });
                return;
              }

              setDialogState(() {
                submitting = true;
                formError = null;
              });

              try {
                await _api.createAppointmentRequest(
                  requestType: requestType,
                  visitMode: visitMode,
                  preferredDate:
                      DateFormat('yyyy-MM-dd').format(preferredDate!),
                  preferredTimeSlot: timeSlot,
                  reason: reason,
                  urgency: urgency,
                );
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                await _load();
              } on ApiException catch (error) {
                setDialogState(() {
                  formError = error.message;
                  submitting = false;
                });
              } catch (_) {
                setDialogState(() {
                  formError = 'Unable to submit request.';
                  submitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Request an Appointment'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppDropdownFormField<String>(
                        value: requestType,
                        decoration: const InputDecoration(
                            labelText: 'Appointment Type'),
                        items: _requestTypes.entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ))
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() => requestType = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      AppDropdownFormField<String>(
                        value: visitMode,
                        decoration:
                            const InputDecoration(labelText: 'Visit Mode'),
                        items: _visitModes.entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ))
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() => visitMode = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      AppDropdownFormField<String>(
                        value: timeSlot,
                        decoration:
                            const InputDecoration(labelText: 'Preferred Time'),
                        items: _timeSlots.entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ))
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() => timeSlot = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      AppDropdownFormField<String>(
                        value: urgency,
                        decoration: const InputDecoration(labelText: 'Urgency'),
                        items: _urgencyOptions.entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ))
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() => urgency = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: submitting
                            ? null
                            : () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: preferredDate ??
                                      now.add(const Duration(days: 1)),
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 365)),
                                );
                                if (picked == null) return;
                                setDialogState(() => preferredDate = picked);
                              },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          preferredDate == null
                              ? 'Select Preferred Date'
                              : DateFormat('MMM d, yyyy')
                                  .format(preferredDate!),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        minLines: 3,
                        maxLines: 4,
                        enabled: !submitting,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Visit',
                        ),
                      ),
                      if (formError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          formError!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFFE06C75)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();
  }

  Future<void> _cancelRequest(String requestId) async {
    if (requestId.isEmpty || _cancellingIds.contains(requestId)) return;
    setState(() => _cancellingIds = {..._cancellingIds, requestId});
    try {
      await _api.deleteAppointmentRequest(requestId);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel appointment request.')),
      );
    } finally {
      if (!mounted) return;
      setState(() =>
          _cancellingIds = Set<String>.from(_cancellingIds)..remove(requestId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    final name = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Health Dashboard',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back, ${name.isEmpty ? 'Patient' : name}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openRequestDialog,
                icon: const Icon(Icons.add),
                label: const Text('Request Appointment'),
              ),
            ],
          ),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFFE06C75)),
                ),
              ),
            _PatientDashboardBody(
              totalVisits: _totalVisits,
              activeMedications: _activeMedications,
              pastMedications: _pastMedications,
              pendingRequests: _pendingRequests,
              resourceCount: _resourceCount,
              upcomingConsultations: _upcomingConsultations,
              requests: _requests,
              cancellingIds: _cancellingIds,
              onCancel: _cancelRequest,
              requestTypes: _requestTypes,
              readString: _readString,
              displayDate: _displayDate,
            ),
          ],
        ],
      ),
    );
  }
}

class _PatientDashboardBody extends StatelessWidget {
  const _PatientDashboardBody({
    required this.totalVisits,
    required this.activeMedications,
    required this.pastMedications,
    required this.pendingRequests,
    required this.resourceCount,
    required this.upcomingConsultations,
    required this.requests,
    required this.cancellingIds,
    required this.onCancel,
    required this.requestTypes,
    required this.readString,
    required this.displayDate,
  });

  final int totalVisits;
  final int activeMedications;
  final int pastMedications;
  final int pendingRequests;
  final int resourceCount;
  final int upcomingConsultations;
  final List<Map<String, dynamic>> requests;
  final Set<String> cancellingIds;
  final ValueChanged<String> onCancel;
  final Map<String, String> requestTypes;
  final String Function(Map<String, dynamic>, List<String>, {String fallback})
      readString;
  final String Function(dynamic, {String fallback}) displayDate;

  String _visitSummary() {
    if (totalVisits <= 0) return 'No visits recorded yet.';
    if (totalVisits == 1) return '1 visit recorded.';
    return '$totalVisits visits recorded.';
  }

  String _telemedicineSummary() {
    if (upcomingConsultations <= 0) return 'No upcoming telemedicine sessions';
    if (upcomingConsultations == 1) return '1 upcoming telemedicine session';
    return '$upcomingConsultations upcoming telemedicine sessions';
  }

  @override
  Widget build(BuildContext context) {
    final quickStats = [
      _KpiCard(
        title: 'Total Visits',
        value: totalVisits.toString(),
        icon: Icons.calendar_month_outlined,
        tint: const Color(0xFFE8F2FF),
      ),
      _KpiCard(
        title: 'Active Medications',
        value: activeMedications.toString(),
        icon: Icons.medication_outlined,
        tint: const Color(0xFFF2ECFF),
      ),
      _KpiCard(
        title: 'Pending Requests',
        value: pendingRequests.toString(),
        icon: Icons.pending_actions_outlined,
        tint: const Color(0xFFFFF4DF),
      ),
      _KpiCard(
        title: 'Health Resources',
        value: resourceCount.toString(),
        icon: Icons.menu_book_outlined,
        tint: const Color(0xFFE7FFF2),
        linkLabel: 'Browse Library',
      ),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.deepBlue, AppTheme.periwinkle],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Health Snapshot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pendingRequests == 1
                          ? '1 pending request'
                          : '$pendingRequests pending requests',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _telemedicineSummary(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    label: totalVisits == 1 ? '1 Visit' : '$totalVisits Visits',
                  ),
                  _HeroChip(
                    label: activeMedications == 1
                        ? '1 Active Medication'
                        : '$activeMedications Active Medications',
                  ),
                  _HeroChip(label: '$resourceCount Resources'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: quickStats[0]),
                  const SizedBox(width: 12),
                  Expanded(child: quickStats[1]),
                  const SizedBox(width: 12),
                  Expanded(child: quickStats[2]),
                  const SizedBox(width: 12),
                  Expanded(child: quickStats[3]),
                ],
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: quickStats
                  .map(
                    (card) => SizedBox(
                      width: constraints.maxWidth >= 640
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: card,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            final left = _AppointmentRequestsPanel(
              requests: requests,
              cancellingIds: cancellingIds,
              onCancel: onCancel,
              requestTypes: requestTypes,
              readString: readString,
              displayDate: displayDate,
            );
            final right = Column(
              children: [
                _InsightCard(
                  title: 'Visit History',
                  subtitle: _visitSummary(),
                  icon: Icons.assignment_outlined,
                  tint: const Color(0xFFE8F2FF),
                ),
                const SizedBox(height: 12),
                _InsightCard(
                  title: 'Telemedicine Sessions',
                  subtitle: _telemedicineSummary(),
                  icon: Icons.videocam_outlined,
                  tint: const Color(0xFFEDE8FF),
                ),
              ],
            );
            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 3, child: left),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: right),
                ],
              );
            }
            return Column(
              children: [
                left,
                const SizedBox(height: 12),
                right,
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _MedicationPanel(
          activeCount: activeMedications,
          pastCount: pastMedications,
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AppointmentRequestsPanel extends StatelessWidget {
  const _AppointmentRequestsPanel({
    required this.requests,
    required this.cancellingIds,
    required this.onCancel,
    required this.requestTypes,
    required this.readString,
    required this.displayDate,
  });

  final List<Map<String, dynamic>> requests;
  final Set<String> cancellingIds;
  final ValueChanged<String> onCancel;
  final Map<String, String> requestTypes;
  final String Function(Map<String, dynamic>, List<String>, {String fallback})
      readString;
  final String Function(dynamic, {String fallback}) displayDate;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'My Appointment Requests',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Track the status of your appointment requests',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            Text(
              'No appointment requests yet.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted),
            )
          else
            Column(
              children: requests.take(5).map((request) {
                final requestId = readString(request, const ['id']);
                final status =
                    readString(request, const ['status'], fallback: 'pending')
                        .toLowerCase();
                final type = readString(
                  request,
                  const ['request_type', 'requestType'],
                  fallback: 'consultation',
                ).toLowerCase();
                final typeLabel = requestTypes[type] ?? type;
                final reason = readString(
                  request,
                  const ['reason'],
                  fallback: 'No reason provided',
                );
                final preferredDate = displayDate(
                    request['preferred_date'] ?? request['preferredDate']);
                final requestedOn =
                    displayDate(request['created_at'] ?? request['createdAt']);
                final canCancel = status == 'pending' && requestId.isNotEmpty;
                final cancelling = cancellingIds.contains(requestId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
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
                            Text(
                              typeLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Requested: $requestedOn | Preferred: $preferredDate',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _StatusChip(status: status),
                          if (canCancel)
                            TextButton(
                              onPressed:
                                  cancelling ? null : () => onCancel(requestId),
                              child: cancelling
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Cancel'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
    this.linkLabel,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color tint;
  final String? linkLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.textPrimary)),
                if (linkLabel != null)
                  Text(linkLabel!,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppTheme.deepBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationPanel extends StatelessWidget {
  const _MedicationPanel({
    required this.activeCount,
    required this.pastCount,
  });

  final int activeCount;
  final int pastCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Text('Medications',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _TabChip(label: 'Active ($activeCount)', selected: true),
              const SizedBox(width: 8),
              _TabChip(label: 'Past ($pastCount)', selected: false),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Open My Medications tab for full prescription details.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.background : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppTheme.textPrimary),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final label = normalized.isEmpty
        ? 'Pending'
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';

    Color background = const Color(0xFFFFF4D8);
    Color foreground = const Color(0xFFAA6B00);

    if (normalized == 'approved' || normalized == 'scheduled') {
      background = const Color(0xFFE6FFF2);
      foreground = const Color(0xFF167D3F);
    } else if (normalized == 'cancelled' || normalized == 'rejected') {
      background = const Color(0xFFFFECEF);
      foreground = const Color(0xFFC34652);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

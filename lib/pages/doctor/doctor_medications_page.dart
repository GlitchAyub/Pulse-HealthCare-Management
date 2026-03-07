import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';
import '../../widgets/app_select.dart';

class DoctorMedicationsPage extends StatefulWidget {
  const DoctorMedicationsPage({super.key});

  @override
  State<DoctorMedicationsPage> createState() => _DoctorMedicationsPageState();
}

class _DoctorMedicationsPageState extends State<DoctorMedicationsPage> {
  final _api = HealthReachApi();

  List<dynamic> _patients = const [];
  List<dynamic> _medications = const [];
  final Map<String, List<Map<String, dynamic>>> _adherenceByMedication = {};

  bool _loadingPatients = true;
  bool _loadingMeds = false;
  String? _selectedPatientId;
  String? _error;

  final Set<String> _busyMedicationIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loadingPatients = true;
      _error = null;
    });

    try {
      final patients = await _api.getPatients(limit: 50);
      if (!mounted) return;

      String? nextSelected = _selectedPatientId;
      final maps = patients.whereType<Map<String, dynamic>>().toList();
      if (maps.isEmpty) {
        nextSelected = null;
      } else {
        final hasCurrent = maps.any((patient) {
          return patient['id']?.toString() == nextSelected;
        });
        if (!hasCurrent) {
          nextSelected = maps.first['id']?.toString();
        }
      }

      setState(() {
        _patients = patients;
        _selectedPatientId = nextSelected;
        _loadingPatients = false;
      });

      if (nextSelected != null && nextSelected.isNotEmpty) {
        await _loadMedications(nextSelected);
      } else if (mounted) {
        setState(() {
          _medications = const [];
          _adherenceByMedication.clear();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPatients = false;
        _error = _messageFromError(error);
      });
    }
  }

  Future<void> _refresh() async {
    if (_selectedPatientId != null && _selectedPatientId!.isNotEmpty) {
      await _loadMedications(_selectedPatientId!, showLoading: false);
      return;
    }
    await _loadPatients();
  }

  Future<void> _loadMedications(String patientId,
      {bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loadingMeds = true;
        _error = null;
        _medications = const [];
        _adherenceByMedication.clear();
      });
    } else {
      setState(() {
        _loadingMeds = true;
        _error = null;
      });
    }

    try {
      final meds = await _api.getMedications(patientId: patientId);
      if (!mounted) return;

      final typedMeds = meds.whereType<Map<String, dynamic>>().toList();
      final today = _isoDate(DateTime.now());
      final adherence = <String, List<Map<String, dynamic>>>{};

      for (final medication in typedMeds) {
        final medicationId = _medicationId(medication);
        if (medicationId == null) continue;
        try {
          final rows = await _api.getMedicationAdherence(
            medicationId: medicationId,
            date: today,
          );
          adherence[medicationId] = rows
              .whereType<Map<String, dynamic>>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
        } catch (_) {
          adherence[medicationId] = const <Map<String, dynamic>>[];
        }
      }

      if (!mounted) return;
      setState(() {
        _medications = meds;
        _loadingMeds = false;
        _adherenceByMedication
          ..clear()
          ..addAll(adherence);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMeds = false;
        _error = _messageFromError(error);
      });
    }
  }

  Future<void> _refreshMedicationAdherence(String medicationId) async {
    final today = _isoDate(DateTime.now());
    try {
      final rows = await _api.getMedicationAdherence(
        medicationId: medicationId,
        date: today,
      );
      if (!mounted) return;
      setState(() {
        _adherenceByMedication[medicationId] = rows
            .whereType<Map<String, dynamic>>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      });
    } catch (_) {
      // Keep medication UI responsive even if adherence reload fails.
    }
  }

  Future<void> _openMedicationDialog({Map<String, dynamic>? medication}) async {
    final patientId = _selectedPatientId;
    if (patientId == null || patientId.isEmpty) {
      _showSnack('Select a patient first.');
      return;
    }

    final draft = await showDialog<_MedicationDraft>(
      context: context,
      builder: (_) => _MedicationDialog(initialMedication: medication),
    );

    if (draft == null) return;

    try {
      if (medication == null) {
        await _api.createMedication(draft.toPayload(patientId: patientId));
        _showSnack('Medication added.');
      } else {
        final medicationId = _medicationId(medication);
        if (medicationId == null || medicationId.isEmpty) {
          _showSnack('Unable to update medication: missing id.');
          return;
        }
        await _api.updateMedication(medicationId, draft.toPayload());
        _showSnack('Medication updated.');
      }
      await _loadMedications(patientId);
    } catch (error) {
      _showSnack(_messageFromError(error));
    }
  }

  Future<void> _markMedication(String medicationId, String status) async {
    final patientId = _selectedPatientId;
    if (patientId == null || patientId.isEmpty) {
      _showSnack('Select a patient first.');
      return;
    }

    setState(() {
      _busyMedicationIds.add(medicationId);
    });

    final today = _isoDate(DateTime.now());

    try {
      final currentEntries = _adherenceByMedication[medicationId] ??
          (await _api.getMedicationAdherence(
            medicationId: medicationId,
            date: today,
          ))
              .whereType<Map<String, dynamic>>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

      final firstEntry =
          currentEntries.isNotEmpty ? currentEntries.first : null;

      if (firstEntry != null && firstEntry['id'] != null) {
        final adherenceId = firstEntry['id'].toString();
        await _api.updateMedicationAdherence(
          adherenceId,
          {
            'status': status,
            'takenDate': status == 'taken' ? today : null,
          },
        );
      } else {
        await _api.createMedicationAdherence(
          {
            'medicationId': medicationId,
            'patientId': patientId,
            'scheduledDate': today,
            'takenDate': status == 'taken' ? today : null,
            'status': status,
          },
        );
      }

      await _refreshMedicationAdherence(medicationId);
      _showSnack(status == 'taken' ? 'Marked as taken.' : 'Marked as missed.');
    } catch (error) {
      _showSnack(_messageFromError(error));
    } finally {
      if (mounted) {
        setState(() {
          _busyMedicationIds.remove(medicationId);
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _messageFromError(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  String? _medicationId(Map<String, dynamic> medication) {
    final id = medication['id'];
    if (id == null) return null;
    final text = id.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _todayStatus(String medicationId) {
    final rows = _adherenceByMedication[medicationId];
    if (rows == null || rows.isEmpty) return 'pending';
    final raw = rows.first['status']?.toString().trim().toLowerCase();
    if (raw == 'taken') return 'taken';
    if (raw == 'missed') return 'missed';
    return 'pending';
  }

  int get _activeMedicationCount {
    return _medications.whereType<Map<String, dynamic>>().where((medication) {
      return _readBool(medication['isActive'] ?? medication['is_active']);
    }).length;
  }

  int get _takenTodayCount {
    return _adherenceByMedication.values
        .expand((rows) => rows)
        .where((entry) =>
            entry['status']?.toString().trim().toLowerCase() == 'taken')
        .length;
  }

  int get _missedTodayCount {
    return _adherenceByMedication.values
        .expand((rows) => rows)
        .where((entry) =>
            entry['status']?.toString().trim().toLowerCase() == 'missed')
        .length;
  }

  int get _pendingTodayCount {
    final count = _activeMedicationCount - _takenTodayCount - _missedTodayCount;
    return count < 0 ? 0 : count;
  }

  int get _takenRate {
    final denominator =
        _takenTodayCount + _missedTodayCount + _pendingTodayCount;
    if (denominator == 0) return 0;
    return ((_takenTodayCount / denominator) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final medicationMaps =
        _medications.whereType<Map<String, dynamic>>().toList(growable: false);
    final activeMedications = medicationMaps.where((medication) {
      return _readBool(medication['isActive'] ?? medication['is_active']);
    }).toList(growable: false);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Medication Tracking',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          _TrackingCard(
            loadingPatients: _loadingPatients,
            patients: _patients,
            selectedPatientId: _selectedPatientId,
            onPatientChanged: (value) {
              if (value == null) return;
              setState(() => _selectedPatientId = value);
              _loadMedications(value);
            },
            onAddMedication: () => _openMedicationDialog(),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Current Medications',
            child: _loadingMeds
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : medicationMaps.isEmpty
                    ? Text('No medications found for this patient.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textMuted))
                    : Column(
                        children: medicationMaps.map((medication) {
                          final medicationId = _medicationId(medication) ?? '';
                          return _MedicationRow(
                            medication: medication,
                            status: _todayStatus(medicationId),
                            busy: _busyMedicationIds.contains(medicationId),
                            onMarkTaken: medicationId.isEmpty
                                ? null
                                : () => _markMedication(medicationId, 'taken'),
                            onMarkMissed: medicationId.isEmpty
                                ? null
                                : () => _markMedication(medicationId, 'missed'),
                            onEdit: () =>
                                _openMedicationDialog(medication: medication),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Today\'s Schedule',
            child: activeMedications.isEmpty
                ? Text('No active medications scheduled.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted))
                : Column(
                    children: activeMedications
                        .map((medication) =>
                            _ScheduleRow(medication: medication))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Adherence Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;
                    final tiles = [
                      _SummaryTile(
                        title: 'Taken Rate',
                        value: '$_takenRate%',
                        color: const Color(0xFFE9F7EF),
                        textColor: const Color(0xFF1F9D55),
                      ),
                      _SummaryTile(
                        title: 'Taken Today',
                        value: _takenTodayCount.toString(),
                        color: const Color(0xFFEAF0FF),
                        textColor: const Color(0xFF3B6EF5),
                      ),
                      _SummaryTile(
                        title: 'Missed Doses',
                        value: _missedTodayCount.toString(),
                        color: const Color(0xFFFFF1E8),
                        textColor: const Color(0xFFE67E22),
                      ),
                      _SummaryTile(
                        title: 'Active Meds',
                        value: _activeMedicationCount.toString(),
                        color: const Color(0xFFF3EBFF),
                        textColor: const Color(0xFF7B4BCE),
                      ),
                    ];

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: tiles[0]),
                          const SizedBox(width: 10),
                          Expanded(child: tiles[1]),
                          const SizedBox(width: 10),
                          Expanded(child: tiles[2]),
                          const SizedBox(width: 10),
                          Expanded(child: tiles[3]),
                        ],
                      );
                    }

                    return Column(
                      children: tiles
                          .map((tile) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: tile,
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (_takenTodayCount + _missedTodayCount == 0)
                  Text('No adherence logs for today yet.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFFE06C75)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.loadingPatients,
    required this.patients,
    required this.selectedPatientId,
    required this.onPatientChanged,
    required this.onAddMedication,
  });

  final bool loadingPatients;
  final List<dynamic> patients;
  final String? selectedPatientId;
  final ValueChanged<String?> onPatientChanged;
  final VoidCallback onAddMedication;

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
          Row(
            children: [
              const Icon(Icons.medical_services_outlined,
                  color: AppTheme.deepBlue),
              const SizedBox(width: 8),
              Text('Medication Tracking',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (loadingPatients)
            const LinearProgressIndicator()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final select = AppDropdownFormField<String>(
                  value: selectedPatientId,
                  decoration: const InputDecoration(
                    labelText: 'Select patient',
                  ),
                  items:
                      patients.whereType<Map<String, dynamic>>().map((patient) {
                    final name = patient['fullName'] ??
                        patient['full_name'] ??
                        'Patient';
                    return DropdownMenuItem<String>(
                      value: patient['id']?.toString(),
                      child: Text(name.toString()),
                    );
                  }).toList(),
                  onChanged: onPatientChanged,
                );

                final add = ElevatedButton.icon(
                  onPressed: selectedPatientId == null ? null : onAddMedication,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medication'),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: select),
                      const SizedBox(width: 12),
                      add,
                    ],
                  );
                }

                return Column(
                  children: [
                    select,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: add),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.textPrimary)),
          ),
          Container(
            height: 1,
            color: AppTheme.border,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({
    required this.medication,
    required this.status,
    required this.busy,
    required this.onMarkTaken,
    required this.onMarkMissed,
    required this.onEdit,
  });

  final Map<String, dynamic> medication;
  final String status;
  final bool busy;
  final VoidCallback? onMarkTaken;
  final VoidCallback? onMarkMissed;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = medication['medicationName'] ??
        medication['medication_name'] ??
        'Medication';
    final dosage = medication['dosage'] ?? 'N/A';
    final frequency = medication['frequency'] ?? 'N/A';
    final startDateValue = medication['startDate'] ?? medication['start_date'];
    final isActive =
        _readBool(medication['isActive'] ?? medication['is_active']);

    final statusColor = switch (status) {
      'taken' => const Color(0xFF16A34A),
      'missed' => const Color(0xFFDC2626),
      _ => AppTheme.textMuted,
    };

    final statusBackground = switch (status) {
      'taken' => const Color(0xFFEAF9EF),
      'missed' => const Color(0xFFFFECEC),
      _ => const Color(0xFFF2F4F7),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(name.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppTheme.textPrimary)),
                      _pill(
                        label: dosage.toString(),
                        color: const Color(0xFFEAF0FF),
                        textColor: const Color(0xFF3B6EF5),
                      ),
                      _pill(
                        label: isActive ? 'Active' : 'Inactive',
                        color: isActive
                            ? const Color(0xFFEAF9EF)
                            : const Color(0xFFF2F4F7),
                        textColor: isActive
                            ? const Color(0xFF16A34A)
                            : AppTheme.textMuted,
                      ),
                      _pill(
                        label: status,
                        color: statusBackground,
                        textColor: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Frequency: ${_frequencyLabel(frequency.toString())}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted)),
                  Text('Started: ${_displayDate(startDateValue?.toString())}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted)),
                ],
              );

              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : onMarkTaken,
                    child: const Text('Mark Taken'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : onMarkMissed,
                    child: const Text('Mark Missed'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : onEdit,
                    child: const Text('Edit'),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    actions,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  info,
                  const SizedBox(height: 10),
                  actions,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.medication});

  final Map<String, dynamic> medication;

  @override
  Widget build(BuildContext context) {
    final name = medication['medicationName'] ??
        medication['medication_name'] ??
        'Medication';
    final dosage = medication['dosage'] ?? 'N/A';
    final frequency = (medication['frequency'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text('$dosage  -  ${_frequencyLabel(frequency)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.border),
              color: Colors.white,
            ),
            child: Text(_scheduleTimeForFrequency(frequency),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
    required this.color,
    required this.textColor,
  });

  final String title;
  final String value;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _MedicationDialog extends StatefulWidget {
  const _MedicationDialog({this.initialMedication});

  final Map<String, dynamic>? initialMedication;

  @override
  State<_MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends State<_MedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _adherenceNotesController = TextEditingController();

  String _frequency = 'daily';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;

  static final Map<String, String> _frequencyLabels = {
    'daily': 'Once daily',
    'twice_daily': 'Twice daily',
    'three_times_daily': 'Three times daily',
    'weekly': 'Weekly',
    'as_needed': 'As needed',
  };

  @override
  void initState() {
    super.initState();

    final initial = widget.initialMedication;
    if (initial != null) {
      _medicationNameController.text =
          (initial['medicationName'] ?? initial['medication_name'] ?? '')
              .toString();
      _dosageController.text = (initial['dosage'] ?? '').toString();
      _frequency = (initial['frequency'] ?? 'daily').toString();
      _instructionsController.text = (initial['instructions'] ?? '').toString();
      _adherenceNotesController.text =
          (initial['adherenceNotes'] ?? initial['adherence_notes'] ?? '')
              .toString();
      _isActive = _readBool(initial['isActive'] ?? initial['is_active']);

      final parsedStart = _tryParseDate(
        (initial['startDate'] ?? initial['start_date'])?.toString(),
      );
      if (parsedStart != null) {
        _startDate = parsedStart;
        _startDateController.text = _displayDateFromDateTime(parsedStart);
      }

      final parsedEnd = _tryParseDate(
        (initial['endDate'] ?? initial['end_date'])?.toString(),
      );
      if (parsedEnd != null) {
        _endDate = parsedEnd;
        _endDateController.text = _displayDateFromDateTime(parsedEnd);
      }
    }

    if (!_frequencyLabels.containsKey(_frequency)) {
      _frequencyLabels[_frequency] = _frequencyLabel(_frequency);
    }
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _instructionsController.dispose();
    _adherenceNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _startDateController.text = _displayDateFromDateTime(picked);
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = null;
        _endDateController.clear();
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _endDateController.text = _displayDateFromDateTime(picked);
    });
  }

  void _submit() {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;
    if (_startDate == null) return;

    final draft = _MedicationDraft(
      medicationName: _medicationNameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      startDate: _isoDate(_startDate!),
      endDate: _endDate == null ? null : _isoDate(_endDate!),
      instructions: _nullableText(_instructionsController.text),
      adherenceNotes: _nullableText(_adherenceNotesController.text),
      isActive: _isActive,
    );

    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialMedication != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isEditing ? 'Edit Medication' : 'Add Medication',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Enter medication details for this patient.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _medicationNameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name *',
                    hintText: 'e.g., Amoxicillin',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Medication name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 520;
                    final dosage = TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage *',
                        hintText: 'e.g., 500mg',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Dosage is required';
                        }
                        return null;
                      },
                    );
                    final frequency = AppDropdownFormField<String>(
                      value: _frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency *',
                      ),
                      items: _frequencyLabels.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _frequency = value);
                        }
                      },
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: dosage),
                          const SizedBox(width: 12),
                          Expanded(child: frequency),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        dosage,
                        const SizedBox(height: 12),
                        frequency,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 520;
                    final startDate = TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: _pickStartDate,
                      decoration: const InputDecoration(
                        labelText: 'Start Date *',
                        hintText: 'mm/dd/yyyy',
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      validator: (_) {
                        if (_startDate == null) return 'Start date is required';
                        return null;
                      },
                    );
                    final endDate = TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      onTap: _pickEndDate,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        hintText: 'mm/dd/yyyy',
                        suffixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: startDate),
                          const SizedBox(width: 12),
                          Expanded(child: endDate),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        startDate,
                        const SizedBox(height: 12),
                        endDate,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructionsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    hintText: 'Special instructions for taking this medication',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _adherenceNotesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Adherence Notes',
                    hintText: 'Notes for follow-up or adherence guidance',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medication Status',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.textPrimary)),
                            Text('Mark this medication as active or inactive',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_isActive ? 'Active' : 'Inactive',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textPrimary)),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      child:
                          Text(isEditing ? 'Save Changes' : 'Add Medication'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationDraft {
  const _MedicationDraft({
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.adherenceNotes,
    required this.isActive,
  });

  final String medicationName;
  final String dosage;
  final String frequency;
  final String startDate;
  final String? endDate;
  final String? instructions;
  final String? adherenceNotes;
  final bool isActive;

  Map<String, dynamic> toPayload({String? patientId}) {
    return {
      if (patientId != null) 'patientId': patientId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': startDate,
      'endDate': endDate,
      'instructions': instructions,
      'adherenceNotes': adherenceNotes,
      'isActive': isActive,
    };
  }
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value == null) return false;
  final text = value.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

String _isoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _displayDate(String? value) {
  final date = _tryParseDate(value);
  if (date == null) return 'N/A';
  return _displayDateFromDateTime(date);
}

String _displayDateFromDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$month/$day/$year';
}

DateTime? _tryParseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

String? _nullableText(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return text;
}

String _frequencyLabel(String raw) {
  if (raw.trim().isEmpty) return 'As prescribed';
  final normalized = raw.trim().toLowerCase();
  const labels = {
    'daily': 'Once daily',
    'once_daily': 'Once daily',
    'twice_daily': 'Twice daily',
    'three_times_daily': 'Three times daily',
    'weekly': 'Weekly',
    'as_needed': 'As needed',
    'prn': 'As needed',
  };
  if (labels.containsKey(normalized)) return labels[normalized]!;
  return raw.replaceAll('_', ' ');
}

String _scheduleTimeForFrequency(String raw) {
  final normalized = raw.trim().toLowerCase();
  switch (normalized) {
    case 'daily':
    case 'once_daily':
      return '8:00 AM';
    case 'twice_daily':
      return '8:00 AM / 8:00 PM';
    case 'three_times_daily':
      return '8AM / 2PM / 8PM';
    case 'weekly':
      return 'Weekly';
    default:
      return 'As prescribed';
  }
}

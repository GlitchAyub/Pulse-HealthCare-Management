import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../data/healthreach_api.dart';
import '../../widgets/app_select.dart';

class AdminVisitsPage extends StatefulWidget {
  const AdminVisitsPage({super.key});

  @override
  State<AdminVisitsPage> createState() => _AdminVisitsPageState();
}

class _AdminVisitsPageState extends State<AdminVisitsPage> {
  final _api = HealthReachApi();

  bool _loading = true;
  bool _loadingVisits = false;
  String? _error;
  String? _role;

  List<Map<String, dynamic>> _patients = const [];
  List<Map<String, dynamic>> _visits = const [];

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

    final role = AuthScope.of(context).user?.role;
    String? loadError;
    var sawUnauthorized = false;

    Future<List<Map<String, dynamic>>> safeList(
      Future<List<dynamic>> Function() fn,
    ) async {
      try {
        final items = await fn();
        return items.whereType<Map>().map((item) {
          return Map<String, dynamic>.from(
            item.map((key, value) => MapEntry(key.toString(), value)),
          );
        }).toList();
      } on ApiException catch (error) {
        sawUnauthorized = sawUnauthorized || _isUnauthorized(error);
        if (!_isSoftError(error) && loadError == null) {
          loadError = error.message;
        }
        return const <Map<String, dynamic>>[];
      } catch (error) {
        loadError ??= error.toString();
        return const <Map<String, dynamic>>[];
      }
    }

    List<Map<String, dynamic>> patients = const [];
    List<Map<String, dynamic>> visits = const [];

    if (_isRoleAllowed(role)) {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        safeList(() => _api.getPatients(limit: 100)),
        safeList(() => _api.getVisits(limit: 20)),
      ]);
      patients = results[0];
      visits = results[1];
    }

    if (!mounted) return;

    if (sawUnauthorized && patients.isEmpty && visits.isEmpty) {
      await AuthScope.of(context).logout();
      return;
    }

    setState(() {
      _role = role;
      _patients = patients;
      _visits = visits;
      _error = loadError;
      _loading = false;
    });
  }

  Future<void> _reloadVisits() async {
    if (!_isRoleAllowed(_role)) return;

    setState(() {
      _loadingVisits = true;
      _error = null;
    });

    try {
      final rawVisits = await _api.getVisits(limit: 20);
      final visits = rawVisits
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (!mounted) return;
      setState(() {
        _visits = visits;
      });
    } on ApiException catch (error) {
      if (_isUnauthorized(error) && mounted) {
        await AuthScope.of(context).logout();
        return;
      }
      if (!mounted) return;
      setState(() {
        if (!_isSoftError(error)) {
          _error = error.message;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingVisits = false;
        });
      }
    }
  }

  Future<bool> _saveVisit(Map<String, dynamic> payload) async {
    try {
      await _api.createVisit(payload);
      await _reloadVisits();
      _showSnack('Visit saved successfully.');
      return true;
    } on ApiException catch (error) {
      if (_isUnauthorized(error) && mounted) {
        await AuthScope.of(context).logout();
        return false;
      }
      _showSnack(error.message);
      return false;
    } catch (error) {
      _showSnack(_errorMessage(error));
      return false;
    }
  }

  Future<void> _openNewVisitDialog() async {
    if (!_isRoleAllowed(_role)) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 920,
              maxHeight: 900,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Document New Visit',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppTheme.textPrimary)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _VisitDocumentationCard(
                    patients: _patients,
                    onSaveVisit: _saveVisit,
                    onVisitSaved: () {
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openVisitDetails(Map<String, dynamic> visit) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _VisitDetailsDialog(visit: visit),
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
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

  bool _isUnauthorized(ApiException error) => error.statusCode == 401;

  @override
  Widget build(BuildContext context) {
    final roleAllowed = _isRoleAllowed(_role);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Visit Documentation',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
              ),
              OutlinedButton.icon(
                onPressed: _loading || !roleAllowed ? null : _reloadVisits,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Filter'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed:
                    _loading || !roleAllowed ? null : _openNewVisitDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Visit'),
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
            if (!roleAllowed)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Text(
                  'Visits are only available for medical professionals and admins.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              )
            else ...[
              _VisitDocumentationCard(
                patients: _patients,
                onSaveVisit: _saveVisit,
              ),
              const SizedBox(height: 16),
              _RecentVisitsCard(
                visits: _visits,
                loading: _loadingVisits,
                onViewDetails: _openVisitDetails,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

String? _firstPatientId(List<Map<String, dynamic>> patients) {
  for (final patient in patients) {
    final id = patient['id']?.toString().trim();
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
}

String _asDisplayText(
  dynamic value, {
  String fallback = '--',
}) {
  if (value == null) return fallback;
  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _nullableText(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return text;
}

dynamic _parseNumberOrString(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  final parsedNumber = num.tryParse(text);
  if (parsedNumber != null) return parsedNumber;
  return text;
}

bool _isRoleAllowed(String? role) {
  return role == 'medical_professional' || role == 'admin';
}

String _visitTypeLabel(String value) {
  switch (value.toLowerCase()) {
    case 'checkup':
      return 'checkup';
    case 'followup':
      return 'followup';
    case 'emergency':
      return 'emergency';
    case 'vaccination':
      return 'vaccination';
    default:
      return value.isEmpty ? 'visit' : value.toLowerCase();
  }
}

String _isoDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatDateTime(dynamic value) {
  final parsed = _parseDate(value);
  if (parsed == null) return 'Unknown date';
  final month = _monthShort(parsed.month);
  final day = parsed.day;
  final year = parsed.year;
  final time = _formatTime(parsed);
  return '$month $day, $year at $time';
}

String _formatDateOnly(dynamic value) {
  final parsed = _parseDate(value);
  if (parsed == null) return 'Not scheduled';
  final month = _monthShort(parsed.month);
  final day = parsed.day;
  final year = parsed.year;
  return '$month $day, $year';
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  return parsed.toLocal();
}

String _monthShort(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) return 'Unknown';
  return months[month - 1];
}

String _formatTime(DateTime value) {
  final hour24 = value.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final meridian = hour24 >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $meridian';
}

Color _urgencyBackground(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'critical':
      return const Color(0xFFFEE2E2);
    case 'high':
      return const Color(0xFFFFEDD5);
    case 'medium':
      return const Color(0xFFFEF9C3);
    case 'low':
    default:
      return const Color(0xFFDCFCE7);
  }
}

Color _urgencyForeground(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'critical':
      return const Color(0xFF991B1B);
    case 'high':
      return const Color(0xFF9A3412);
    case 'medium':
      return const Color(0xFF854D0E);
    case 'low':
    default:
      return const Color(0xFF166534);
  }
}

class _VisitDocumentationCard extends StatefulWidget {
  const _VisitDocumentationCard({
    required this.patients,
    required this.onSaveVisit,
    this.onVisitSaved,
  });

  final List<Map<String, dynamic>> patients;
  final Future<bool> Function(Map<String, dynamic> payload) onSaveVisit;
  final VoidCallback? onVisitSaved;

  @override
  State<_VisitDocumentationCard> createState() =>
      _VisitDocumentationCardState();
}

class _VisitDocumentationCardState extends State<_VisitDocumentationCard> {
  final _formKey = GlobalKey<FormState>();

  final _temperatureController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _weightController = TextEditingController();
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();

  String? _selectedPatientId;
  String _visitType = 'checkup';
  String _followUpRequired = 'no';
  String _urgencyLevel = 'low';

  bool _saving = false;
  String? _formError;

  static const _visitTypeOptions = {
    'checkup': 'General Checkup',
    'followup': 'Follow-up',
    'emergency': 'Emergency',
    'vaccination': 'Vaccination',
  };

  static const _followUpOptions = {
    'no': 'No follow-up needed',
    '1week': '1 week',
    '2weeks': '2 weeks',
    '1month': '1 month',
    '3months': '3 months',
  };

  static const _urgencyOptions = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
    'critical': 'Critical',
  };

  @override
  void initState() {
    super.initState();
    _selectedPatientId = _firstPatientId(widget.patients);
  }

  @override
  void didUpdateWidget(covariant _VisitDocumentationCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final current = _selectedPatientId;
    final hasCurrent = widget.patients.any((patient) {
      return patient['id']?.toString() == current;
    });

    if (!hasCurrent) {
      setState(() {
        _selectedPatientId = _firstPatientId(widget.patients);
      });
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _weightController.dispose();
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;

    if (_selectedPatientId == null || _selectedPatientId!.isEmpty) {
      setState(() {
        _formError = 'Please select a patient.';
      });
      return;
    }

    final payload = <String, dynamic>{
      'patientId': _selectedPatientId,
      'visitType': _visitType,
      'chiefComplaint': _nullableText(_chiefComplaintController.text),
      'symptoms': _nullableText(_symptomsController.text),
      'vitals': {
        'temperature': _parseNumberOrString(_temperatureController.text),
        'bloodPressure': _nullableText(_bloodPressureController.text),
        'heartRate': _parseNumberOrString(_heartRateController.text),
        'weight': _parseNumberOrString(_weightController.text),
      },
      'diagnosis': _nullableText(_diagnosisController.text),
      'treatment': _nullableText(_treatmentController.text),
      'medications': <dynamic>[],
      'followUpRequired': _followUpRequired,
      'urgencyLevel': _urgencyLevel,
      'visitDate': _isoDate(DateTime.now()),
    };

    setState(() {
      _saving = true;
      _formError = null;
    });

    final success = await widget.onSaveVisit(payload);

    if (!mounted) return;
    setState(() {
      _saving = false;
    });

    if (success) {
      _clearForm(keepPatient: true);
      widget.onVisitSaved?.call();
    }
  }

  void _clearForm({required bool keepPatient}) {
    _formKey.currentState?.reset();
    _temperatureController.clear();
    _bloodPressureController.clear();
    _heartRateController.clear();
    _weightController.clear();
    _chiefComplaintController.clear();
    _symptomsController.clear();
    _diagnosisController.clear();
    _treatmentController.clear();

    setState(() {
      if (!keepPatient) {
        _selectedPatientId = _firstPatientId(widget.patients);
      }
      _visitType = 'checkup';
      _followUpRequired = 'no';
      _urgencyLevel = 'low';
      _formError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined, color: AppTheme.deepBlue),
                const SizedBox(width: 8),
                Text('Visit Documentation',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final patient = AppDropdownFormField<String>(
                  value: _selectedPatientId,
                  decoration: const InputDecoration(labelText: 'Patient *'),
                  items: widget.patients.map((patient) {
                    final name = patient['fullName'] ?? 'Patient';
                    final phone = patient['phone']?.toString() ?? '';
                    return DropdownMenuItem<String>(
                      value: patient['id']?.toString(),
                      child: Text(phone.isEmpty ? '$name' : '$name  -  $phone'),
                    );
                  }).toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _selectedPatientId = value),
                );
                final visitType = AppDropdownFormField<String>(
                  value: _visitType,
                  decoration: const InputDecoration(labelText: 'Visit Type *'),
                  items: _visitTypeOptions.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _visitType = value);
                          }
                        },
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: patient),
                      const SizedBox(width: 12),
                      Expanded(child: visitType),
                    ],
                  );
                }

                return Column(
                  children: [
                    patient,
                    const SizedBox(height: 12),
                    visitType,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Vital Signs',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final fields = [
                  _buildTextField(
                    controller: _temperatureController,
                    label: 'Temperature (°C)',
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    controller: _bloodPressureController,
                    label: 'Blood Pressure',
                  ),
                  _buildTextField(
                    controller: _heartRateController,
                    label: 'Heart Rate (bpm)',
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    keyboardType: TextInputType.number,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[1]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[2]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[3]),
                    ],
                  );
                }

                return Column(
                  children: fields
                      .map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: field,
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final chiefComplaint = _buildTextField(
                  controller: _chiefComplaintController,
                  label: 'Chief Complaint',
                  maxLines: 3,
                  hintText: 'Patient\'s main concern...',
                );
                final symptoms = _buildTextField(
                  controller: _symptomsController,
                  label: 'Symptoms',
                  maxLines: 3,
                  hintText: 'Detailed symptoms...',
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: chiefComplaint),
                      const SizedBox(width: 12),
                      Expanded(child: symptoms),
                    ],
                  );
                }

                return Column(
                  children: [
                    chiefComplaint,
                    const SizedBox(height: 12),
                    symptoms,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final diagnosis = _buildTextField(
                  controller: _diagnosisController,
                  label: 'Assessment/Diagnosis',
                  maxLines: 3,
                  hintText: 'Clinical assessment and diagnosis...',
                );
                final treatment = _buildTextField(
                  controller: _treatmentController,
                  label: 'Treatment Plan',
                  maxLines: 3,
                  hintText: 'Treatment recommendations and medications...',
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: diagnosis),
                      const SizedBox(width: 12),
                      Expanded(child: treatment),
                    ],
                  );
                }

                return Column(
                  children: [
                    diagnosis,
                    const SizedBox(height: 12),
                    treatment,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final followUp = AppDropdownFormField<String>(
                  value: _followUpRequired,
                  decoration:
                      const InputDecoration(labelText: 'Follow-up Required'),
                  items: _followUpOptions.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _followUpRequired = value);
                          }
                        },
                );
                final urgency = AppDropdownFormField<String>(
                  value: _urgencyLevel,
                  decoration: const InputDecoration(labelText: 'Urgency Level'),
                  items: _urgencyOptions.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _urgencyLevel = value);
                          }
                        },
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: followUp),
                      const SizedBox(width: 12),
                      Expanded(child: urgency),
                    ],
                  );
                }

                return Column(
                  children: [
                    followUp,
                    const SizedBox(height: 12),
                    urgency,
                  ],
                );
              },
            ),
            if (_formError != null) ...[
              const SizedBox(height: 10),
              Text(
                _formError!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFFE06C75)),
              ),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final save = Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save Visit'),
                  ),
                );
                final clear = Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _saving ? null : () => _clearForm(keepPatient: true),
                    icon: const Icon(Icons.close),
                    label: const Text('Clear Form'),
                  ),
                );

                if (isWide) {
                  return Row(
                    children: [
                      save,
                      const SizedBox(width: 12),
                      clear,
                    ],
                  );
                }

                return Column(
                  children: [
                    save,
                    const SizedBox(height: 12),
                    clear,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
    );
  }
}

class _RecentVisitsCard extends StatelessWidget {
  const _RecentVisitsCard({
    required this.visits,
    required this.loading,
    required this.onViewDetails,
  });

  final List<Map<String, dynamic>> visits;
  final bool loading;
  final ValueChanged<Map<String, dynamic>> onViewDetails;

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
              const Icon(Icons.history_rounded, color: AppTheme.deepBlue),
              const SizedBox(width: 8),
              Text('Recent Visits',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (visits.isEmpty)
            Text('No recent visits found.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textMuted))
          else
            Column(
              children: visits
                  .map((visit) => _RecentVisitRow(
                        visit: visit,
                        onViewDetails: () => onViewDetails(visit),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _RecentVisitRow extends StatelessWidget {
  const _RecentVisitRow({
    required this.visit,
    required this.onViewDetails,
  });

  final Map<String, dynamic> visit;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final visitId = _asDisplayText(visit['id'], fallback: 'N/A');
    final urgency =
        _asDisplayText(visit['urgencyLevel'], fallback: 'low').toLowerCase();
    final visitType = _visitTypeLabel(_asDisplayText(visit['visitType']));
    final chiefComplaint =
        _asDisplayText(visit['chiefComplaint'], fallback: 'No chief complaint');
    final dateText = _formatDateTime(visit['visitDate'] ?? visit['createdAt']);

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Visit #$visitId',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: AppTheme.textPrimary)),
                    _badge(
                      label: urgency,
                      background: _urgencyBackground(urgency),
                      foreground: _urgencyForeground(urgency),
                    ),
                    _badge(
                      label: visitType,
                      background: const Color(0xFFF2F4F7),
                      foreground: AppTheme.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Chief Complaint: $chiefComplaint',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(dateText,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onViewDetails,
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VisitDetailsDialog extends StatelessWidget {
  const _VisitDetailsDialog({required this.visit});

  final Map<String, dynamic> visit;

  @override
  Widget build(BuildContext context) {
    final urgency =
        _asDisplayText(visit['urgencyLevel'], fallback: 'low').toLowerCase();
    final visitType = _visitTypeLabel(_asDisplayText(visit['visitType']));
    final visitDate = _formatDateTime(visit['visitDate'] ?? visit['createdAt']);
    final chiefComplaint =
        _asDisplayText(visit['chiefComplaint'], fallback: 'Not provided');
    final symptoms =
        _asDisplayText(visit['symptoms'], fallback: 'Not provided');
    final diagnosis =
        _asDisplayText(visit['diagnosis'], fallback: 'Not provided');

    final treatment = _asDisplayText(
      visit['treatment'] ??
          visit['treatmentPlan'] ??
          visit['prescriptions'] ??
          visit['notes'],
      fallback: 'Not provided',
    );

    final vitalsRaw = visit['vitals'];
    final vitals = vitalsRaw is Map
        ? Map<String, dynamic>.from(vitalsRaw)
        : <String, dynamic>{};

    final temp = _asDisplayText(vitals['temperature'], fallback: '--');
    final bp = _asDisplayText(
        vitals['bloodPressure'] ?? vitals['blood_pressure'],
        fallback: '--');
    final heartRate = _asDisplayText(
        vitals['heartRate'] ?? vitals['heart_rate'],
        fallback: '--');
    final weight = _asDisplayText(vitals['weight'], fallback: '--');

    final followUpDate = _formatDateOnly(visit['followUpDate']);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Visit Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.textPrimary)),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                label: urgency,
                color: _urgencyBackground(urgency),
                textColor: _urgencyForeground(urgency),
              ),
              _chip(
                label: visitType,
                color: const Color(0xFFF2F4F7),
                textColor: AppTheme.textMuted,
              ),
              _chip(
                label: visitDate,
                color: const Color(0xFFF8FAFC),
                textColor: AppTheme.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailCard(
            context,
            title: 'Chief Complaint',
            value: chiefComplaint,
          ),
          const SizedBox(height: 10),
          _detailCard(
            context,
            title: 'Symptoms',
            value: symptoms,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vital Signs',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Text('Temp: $temp',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textPrimary)),
                    Text('BP: $bp',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textPrimary)),
                    Text('Heart Rate: $heartRate',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textPrimary)),
                    Text('Weight: $weight',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _detailCard(
            context,
            title: 'Diagnosis',
            value: diagnosis,
            emphasize: true,
          ),
          const SizedBox(height: 10),
          _detailCard(
            context,
            title: 'Treatment',
            value: treatment,
          ),
          const SizedBox(height: 10),
          _detailCard(
            context,
            title: 'Follow-up Date',
            value: followUpDate,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailCard(
    BuildContext context, {
    required String title,
    required String value,
    bool emphasize = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasize ? const Color(0xFFF4F8FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

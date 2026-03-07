import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';
import '../../widgets/patient/patient_registration_card.dart';

class AdminPatientsPage extends StatefulWidget {
  const AdminPatientsPage({super.key});

  @override
  State<AdminPatientsPage> createState() => _AdminPatientsPageState();
}

class _AdminPatientsPageState extends State<AdminPatientsPage> {
  final _api = HealthReachApi();
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<dynamic> _patients = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patients = await _api.getPatients(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _patients = patients;
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

  Future<void> _openAddPatientDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 860,
              maxHeight: 900,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PatientRegistrationCard(
                api: _api,
                onPatientRegistered: () async {
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
              ),
            ),
          ),
        );
      },
    );

    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Patient Management',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
              ),
              ElevatedButton.icon(
                onPressed: _openAddPatientDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Patient'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Search patients by name or phone...',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: AppTheme.background,
              filled: true,
            ),
          ),
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
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFFE06C75)),
              ),
            )
          else if (_patients.isEmpty)
            Text(
              'No patients found.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted),
            )
          else
            Column(
              children: _patients
                  .whereType<Map<String, dynamic>>()
                  .map((patient) => _PatientCard(patient: patient))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final fullName = patient['fullName'] ?? patient['full_name'] ?? 'Patient';
    final patientId = patient['patientId'] ?? patient['patient_id'] ?? 'N/A';
    final age = patient['age']?.toString() ?? 'N/A';
    final gender = patient['gender']?.toString() ?? 'N/A';
    final phone = patient['phone']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.skyBlue.withOpacity(0.2),
            child: Text(
              _initials(fullName.toString()),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.deepBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  '$age years - $gender - $phone',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            patientId.toString(),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

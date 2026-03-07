import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../data/healthreach_api.dart';
import '../invitations/accept_invitation_page.dart';
import '../../widgets/patient/patient_registration_card.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<dynamic> _patients = const [];
  List<dynamic> _pending = const [];
  List<dynamic> _pendingInvitations = const [];

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
    var sawUnauthorized = false;

    Future<Map<String, dynamic>> safeMap(
      Future<Map<String, dynamic>> Function() fn,
    ) async {
      try {
        return await fn();
      } on ApiException catch (error) {
        sawUnauthorized = sawUnauthorized || _isUnauthorized(error);
        if (!_isSoftError(error) && loadError == null) {
          loadError = error.message;
        }
        return <String, dynamic>{};
      } catch (error) {
        final text = error.toString().toLowerCase();
        if (text.contains('<!doctype html') || text.contains('<html')) {
          return <String, dynamic>{};
        }
        loadError ??= error.toString();
        return <String, dynamic>{};
      }
    }

    Future<List<dynamic>> safeList(
      Future<List<dynamic>> Function() fn,
    ) async {
      try {
        return await fn();
      } on ApiException catch (error) {
        sawUnauthorized = sawUnauthorized || _isUnauthorized(error);
        if (!_isSoftError(error) && loadError == null) {
          loadError = error.message;
        }
        return const <dynamic>[];
      } catch (error) {
        final text = error.toString().toLowerCase();
        if (text.contains('<!doctype html') || text.contains('<html')) {
          return const <dynamic>[];
        }
        loadError ??= error.toString();
        return const <dynamic>[];
      }
    }

    final results = await Future.wait<dynamic>([
      safeMap(_api.getDashboardStats),
      safeList(() => _api.getPatients(limit: 10)),
      safeList(() => _api.getAppointmentRequests(status: 'pending')),
      safeList(_api.getMyPendingInvitations),
    ]);

    if (!mounted) return;

    final stats = Map<String, dynamic>.from(results[0] as Map);
    final patients = List<dynamic>.from(results[1] as List);
    final pending = List<dynamic>.from(results[2] as List);
    final pendingInvitations = List<dynamic>.from(results[3] as List);

    if (sawUnauthorized &&
        stats.isEmpty &&
        patients.isEmpty &&
        pending.isEmpty &&
        pendingInvitations.isEmpty) {
      await AuthScope.of(context).logout();
      return;
    }

    setState(() {
      _stats = stats;
      _patients = patients;
      _pending = pending;
      _pendingInvitations = pendingInvitations;
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

  bool _isUnauthorized(ApiException error) => error.statusCode == 401;

  Future<void> _reviewInvitation(Map<String, dynamic> invitation) async {
    final token = invitation['token']?.toString().trim() ?? '';
    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation token is missing.')),
      );
      return;
    }

    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AcceptInvitationPage(token: token),
      ),
    );

    if (accepted == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    final name = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final displayName = _truncateName(name.isEmpty ? 'Doctor' : name);
    final invitationItems = _pendingInvitations
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    String readStat(List<String> keys, {String fallback = '0'}) {
      final stats = _stats;
      if (stats == null) return fallback;
      for (final key in keys) {
        final value = stats[key];
        if (value != null) return value.toString();
      }
      return fallback;
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Medical Professional Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(
            'Welcome, $displayName',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted),
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
          else ...[
            if (invitationItems.isNotEmpty) ...[
              _PendingInvitationsCard(
                invitations: invitationItems,
                onReview: _reviewInvitation,
              ),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final cards = [
                  _KpiCard(
                    title: "Today's Visits",
                    value: readStat(const ['todayVisits', 'today_visits']),
                    icon: Icons.event_available_outlined,
                    color: const Color(0xFF3DD598),
                  ),
                  _KpiCard(
                    title: 'Pending Consults',
                    value: _pending.length.toString(),
                    icon: Icons.medical_services_outlined,
                    color: const Color(0xFFFFB74D),
                  ),
                  _KpiCard(
                    title: 'Critical Cases',
                    value: readStat(const ['criticalCases', 'critical_cases']),
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFE06C75),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;
                final left = PatientRegistrationCard(
                    api: _api, onPatientRegistered: _load);
                final right = Column(
                  children: [
                    _PatientListCard(patients: _patients),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
          ],
        ],
      ),
    );
  }

  String _truncateName(String value) {
    final text = value.trim();
    if (text.length <= 7) return text;
    return '${text.substring(0, 7)}...';
  }
}

class _PendingInvitationsCard extends StatelessWidget {
  const _PendingInvitationsCard({
    required this.invitations,
    required this.onReview,
  });

  final List<Map<String, dynamic>> invitations;
  final ValueChanged<Map<String, dynamic>> onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBCC8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, color: AppTheme.deepBlue),
              const SizedBox(width: 8),
              Text(
                'Pending Organization Invitations (${invitations.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...invitations.map((invitation) => _PendingInvitationRow(
                invitation: invitation,
                onReview: () => onReview(invitation),
              )),
        ],
      ),
    );
  }
}

class _PendingInvitationRow extends StatelessWidget {
  const _PendingInvitationRow({
    required this.invitation,
    required this.onReview,
  });

  final Map<String, dynamic> invitation;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final orgName = _readText(
      invitation,
      const ['organization_name', 'organizationName', 'organization'],
      fallback: 'Organization',
    );
    final role = _readText(invitation, const ['role'], fallback: 'member');
    final expires = _formatDate(
      invitation['expires_at'] ?? invitation['expiresAt'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orgName,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  _roleLabel(role),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  'Expires on $expires',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onReview,
            child: const Text('Review & Accept'),
          ),
        ],
      ),
    );
  }
}

String _readText(
  Map<String, dynamic> source,
  List<String> keys, {
  required String fallback,
}) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

String _roleLabel(String role) {
  final text = role.trim();
  if (text.isEmpty) return 'Member';
  final words = text.split(RegExp(r'[_\s]+'));
  return words
      .where((word) => word.isNotEmpty)
      .map((word) =>
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

String _formatDate(dynamic value) {
  if (value == null) return 'N/A';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();

  const monthNames = [
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
  final local = parsed.toLocal();
  final month = monthNames[local.month - 1];
  return '$month ${local.day}, ${local.year}';
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientListCard extends StatelessWidget {
  const _PatientListCard({required this.patients});

  final List<dynamic> patients;

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
          Text('Patient Management',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by Patient ID, name, or phone...',
              prefixIcon: const Icon(Icons.search_rounded),
              fillColor: AppTheme.background,
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          if (patients.isEmpty)
            Text('No patients found.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textMuted))
          else
            Column(
              children: patients
                  .whereType<Map<String, dynamic>>()
                  .take(5)
                  .map((patient) => _PatientRow(patient: patient))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});

  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final fullName = patient['fullName'] ?? patient['full_name'] ?? 'Patient';
    final patientId = patient['patientId'] ?? patient['patient_id'] ?? 'N/A';
    final age = patient['age']?.toString() ?? 'N/A';
    final gender = patient['gender']?.toString() ?? 'N/A';
    final phone = patient['phone']?.toString() ?? 'N/A';

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
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.skyBlue.withOpacity(0.2),
            child: Text(
              _initials(fullName.toString()),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.deepBlue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '$age years  -  $gender  -  $phone',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(patientId.toString(),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.deepBlue)),
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

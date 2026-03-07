import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../data/healthreach_api.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    this.onOpenOrganizationRequested,
  });

  final VoidCallback? onOpenOrganizationRequested;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _api = HealthReachApi();
  final _searchController = TextEditingController();

  bool _loading = true;
  bool _savingAppointment = false;
  String? _error;

  Map<String, dynamic> _bootstrap = const {};
  Map<String, dynamic> _user = const {};
  Map<String, dynamic> _organization = const {};
  Map<String, dynamic> _stats = const {};
  Map<String, dynamic> _inventory = const {};
  Map<String, dynamic> _labStats = const {};
  Map<String, dynamic> _license = const {};

  int _unreadCount = 0;

  List<Map<String, dynamic>> _pendingInvitations = const [];
  List<Map<String, dynamic>> _appointments = const [];
  List<Map<String, dynamic>> _orgUsers = const [];
  List<Map<String, dynamic>> _notifications = const [];

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

    final errors = <String>[];

    Future<Map<String, dynamic>> safeMap(
      Future<Map<String, dynamic>> Function() fn,
      String label,
    ) async {
      try {
        return await fn();
      } catch (error) {
        errors.add('$label: ${_errorText(error)}');
        return <String, dynamic>{};
      }
    }

    Future<List<Map<String, dynamic>>> safeList(
      Future<List<dynamic>> Function() fn,
      String label,
    ) async {
      try {
        final items = await fn();
        return items.whereType<Map>().map((item) {
          return Map<String, dynamic>.from(
            item.map((k, v) => MapEntry(k.toString(), v)),
          );
        }).toList();
      } catch (error) {
        errors.add('$label: ${_errorText(error)}');
        return <Map<String, dynamic>>[];
      }
    }

    final bootstrap = await safeMap(
      _api.getOrganizationBootstrapStatus,
      'Unable to load setup status',
    );
    final user = await safeMap(_api.getCurrentUser, 'Unable to load user');
    final organization =
        await safeMap(_api.getMyOrganization, 'Unable to load organization');
    final stats =
        await safeMap(_api.getDashboardStats, 'Unable to load dashboard stats');
    Map<String, dynamic> labStats = const {};
    try {
      labStats = await _api.getLabIntegrationStats();
    } catch (_) {
      // Lab stats endpoint may be unavailable for some admin contexts.
      labStats = const {};
    }
    final inventory =
        await safeMap(_api.getInventoryStats, 'Unable to load inventory stats');
    final notifications = await safeList(
      () => _api.getNotifications(limit: 20),
      'Unable to load notifications',
    );
    final pendingInvitations = await safeList(
      () => _api.getMyPendingInvitations(),
      'Unable to load pending invitations',
    );
    final appointments = await safeList(
      () => _api.getAppointmentRequests(status: 'pending'),
      'Unable to load pending appointments',
    );

    final unread = await safeMap(
      _api.getUnreadNotificationCount,
      'Unable to load unread count',
    );
    final unreadCount = int.tryParse(unread['count']?.toString() ?? '0') ?? 0;

    Map<String, dynamic> license = const {};
    List<Map<String, dynamic>> orgUsers = const [];
    final orgId = _text(organization['id']);
    if (orgId.isNotEmpty) {
      license = await safeMap(() => _api.getOrganizationLicense(orgId),
          'Unable to load organization license');
      orgUsers = await safeList(
        () => _api.getOrganizationUsers(orgId),
        'Unable to load organization users',
      );
    }

    if (!mounted) return;
    setState(() {
      _bootstrap = bootstrap;
      _user = user;
      _organization = organization;
      _stats = stats;
      _labStats = labStats;
      _inventory = inventory;
      _notifications = notifications;
      _pendingInvitations = pendingInvitations;
      _appointments = appointments;
      _license = license;
      _orgUsers = orgUsers;
      _unreadCount = unreadCount;
      _error = _resolveDisplayError(
        errors,
        user: user,
        bootstrap: bootstrap,
        organization: organization,
      );
      _loading = false;
    });
  }

  Future<void> _updateAppointment(
      Map<String, dynamic> row, String status) async {
    if (_savingAppointment) return;
    final id = _text(row['id']);
    if (id.isEmpty) return;

    setState(() => _savingAppointment = true);
    try {
      await _api.updateAppointmentRequest(id, payload: {'status': status});
      await _load();
    } finally {
      if (mounted) {
        setState(() => _savingAppointment = false);
      }
    }
  }

  Future<void> _markNotificationRead(Map<String, dynamic> row) async {
    final id = _text(row['id']);
    if (id.isEmpty) return;
    await _api.markNotificationRead(id);
    if (!mounted) return;
    setState(() {
      _notifications = _notifications.map((item) {
        if (_text(item['id']) != id) return item;
        final updated = Map<String, dynamic>.from(item);
        updated['read'] = true;
        updated['isRead'] = true;
        return updated;
      }).toList();
      if (_unreadCount > 0) _unreadCount -= 1;
    });
  }

  Future<void> _markAllRead() async {
    await _api.markAllNotificationsRead();
    if (!mounted) return;
    setState(() {
      _notifications = _notifications.map((item) {
        final updated = Map<String, dynamic>.from(item);
        updated['read'] = true;
        updated['isRead'] = true;
        return updated;
      }).toList();
      _unreadCount = 0;
    });
  }

  Future<void> _openNotifications() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Notifications',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: _notifications.isEmpty ? null : _markAllRead,
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
                if (_notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No notifications found.'),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final row = _notifications[index];
                        final title =
                            _text(row['title'], fallback: 'Notification');
                        final message = _text(row['message'], fallback: '--');
                        final read = _isRead(row);
                        return ListTile(
                          dense: true,
                          title: Text(title),
                          subtitle: Text(message),
                          trailing: read
                              ? null
                              : TextButton(
                                  onPressed: () => _markNotificationRead(row),
                                  child: const Text('Read'),
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openOrganizationSettings() async {
    final openInShell = widget.onOpenOrganizationRequested;
    if (openInShell != null) {
      openInShell();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = AuthScope.of(context).user;
    final displayName = _displayName(
      firstName: authUser?.firstName,
      lastName: authUser?.lastName,
      email: authUser?.email,
    );
    final needsOrganizationSetup = _needsOrganizationSetup(
      user: _user,
      bootstrap: _bootstrap,
      organization: _organization,
    );
    final headerActionLabel =
        needsOrganizationSetup ? 'Create Organization' : 'Open Organization';
    final orgName = _text(
      _organization['name'],
      fallback: needsOrganizationSetup ? 'No Organization Yet' : 'Organization',
    );

    final activePatients = _readNum(_stats, const ['activePatients']);
    final visitsToday = _readNum(_stats, const ['todayVisits']);
    final upcomingConsults = _readNum(_stats, const ['upcomingConsultations']);
    final criticalCases = _readNum(_stats, const ['criticalCases']);

    final labAlerts = (_labStats['recentTests'] is List)
        ? (_labStats['recentTests'] as List).length
        : _readNum(_labStats, const ['alerts']);

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 640 ? 12.0 : 24.0;
          final compactHeader = constraints.maxWidth < 860;

          final notificationButton = Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE06C75),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              24,
            ),
            children: [
              if (compactHeader)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Dashboard',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome, $displayName | $orgName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openOrganizationSettings,
                            icon: const Icon(Icons.settings_outlined),
                            label: Text(headerActionLabel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        notificationButton,
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Dashboard',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome, $displayName | $orgName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    notificationButton,
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _openOrganizationSettings,
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(
                        needsOrganizationSetup
                            ? 'Create Organization'
                            : 'Organization Settings',
                      ),
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFE06C75)),
                    ),
                  ),
                if (needsOrganizationSetup) ...[
                  _buildOrganizationSetupCard(),
                ] else ...[
                  if (_pendingInvitations.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBECBFF)),
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final compactInvitation = box.maxWidth < 520;
                          if (compactInvitation) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.mail_outline_rounded,
                                        color: AppTheme.deepBlue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Pending Organization Invitations (${_pendingInvitations.length})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _openOrganizationSettings,
                                  child: const Text('Review'),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              const Icon(Icons.mail_outline_rounded,
                                  color: AppTheme.deepBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pending Organization Invitations (${_pendingInvitations.length})',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              TextButton(
                                onPressed: _openOrganizationSettings,
                                child: const Text('Review'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  _MetricsGrid(
                    metrics: [
                      _MetricData('Total Patients', activePatients,
                          Icons.people_outline, const Color(0xFF3A7BD5)),
                      _MetricData(
                          'Visits Today',
                          visitsToday,
                          Icons.monitor_heart_outlined,
                          const Color(0xFF22C55E)),
                      _MetricData('Active Staff', _orgUsers.length,
                          Icons.shield_outlined, const Color(0xFFA855F7)),
                      _MetricData('Lab Alerts', labAlerts,
                          Icons.warning_amber_rounded, const Color(0xFFF97316)),
                      _MetricData('Pending Appointments', _appointments.length,
                          Icons.event_outlined, const Color(0xFFEF4444)),
                      _MetricData('Upcoming Consultations', upcomingConsults,
                          Icons.trending_up_rounded, const Color(0xFF14B8A6)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Action Queue',
                    child: Column(
                      children: [
                        _QueueGroup(
                          title: 'Pending Appointments',
                          icon: Icons.event_outlined,
                          initiallyExpanded: true,
                          child: _appointments.isEmpty
                              ? const Text('No pending requests')
                              : Column(
                                  children: _appointments
                                      .take(5)
                                      .map((row) => _AppointmentActionRow(
                                            row: row,
                                            disabled: _savingAppointment,
                                            onApprove: () => _updateAppointment(
                                                row, 'approved'),
                                            onReject: () => _updateAppointment(
                                                row, 'rejected'),
                                          ))
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 10),
                        _QueueGroup(
                          title: 'Inventory Alerts',
                          icon: Icons.inventory_2_outlined,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip('Low Stock: ${_readNum(_inventory, const [
                                    'lowStock'
                                  ])}'),
                              _chip(
                                  'Expiring Soon: ${_readNum(_inventory, const [
                                    'expiringSoon'
                                  ])}'),
                              _chip(
                                  'Out Of Stock: ${_readNum(_inventory, const [
                                    'outOfStock'
                                  ])}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Staff Management',
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final users = _filteredUsers().take(8).toList();
                        final isCompact = box.maxWidth < 760;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Search by name or email...',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (users.isEmpty)
                              const Text('No staff found.')
                            else if (isCompact)
                              Column(
                                children: users
                                    .map(
                                      (row) => Container(
                                        width: double.infinity,
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.background,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppTheme.border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _userName(row),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                                _statusPill(_text(
                                                  row['status'],
                                                  fallback: 'active',
                                                )),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _text(row['email'],
                                                  fallback: '-'),
                                              style: const TextStyle(
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _humanize(_text(
                                                row['orgRole'] ??
                                                    row['org_role'] ??
                                                    row['role'],
                                                fallback: '-',
                                              )),
                                              style: const TextStyle(
                                                color: AppTheme.deepBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Name')),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Role')),
                                    DataColumn(label: Text('Status')),
                                  ],
                                  rows: users.map((row) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(_userName(row))),
                                        DataCell(Text(_text(row['email'],
                                            fallback: '-'))),
                                        DataCell(Text(_humanize(_text(
                                            row['orgRole'] ??
                                                row['org_role'] ??
                                                row['role'],
                                            fallback: '-')))),
                                        DataCell(Text(_text(row['status'],
                                            fallback: 'active'))),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'License & Billing',
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final planInfo = _info(
                          'Plan',
                          _text(_license['planName'] ?? _license['plan_type'],
                              fallback: 'None'),
                        );
                        final expiresInfo = _info(
                          'Expires',
                          _date(
                              _license['expiresAt'] ?? _license['expires_at']),
                        );
                        final criticalInfo =
                            _info('Critical Cases', '$criticalCases');

                        if (box.maxWidth < 760) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              planInfo,
                              const SizedBox(height: 10),
                              expiresInfo,
                              const SizedBox(height: 10),
                              criticalInfo,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: planInfo),
                            const SizedBox(width: 10),
                            Expanded(child: expiresInfo),
                            const SizedBox(width: 10),
                            Expanded(child: criticalInfo),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filteredUsers() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _orgUsers;
    return _orgUsers.where((row) {
      final name = _userName(row).toLowerCase();
      final email = _text(row['email']).toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(text),
    );
  }

  Widget _info(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final normalized = status.trim().toLowerCase();
    final active = normalized == 'active' || normalized.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF86EFAC) : const Color(0xFFD1D5DB),
        ),
      ),
      child: Text(
        active ? 'active' : normalized,
        style: TextStyle(
          color: active ? const Color(0xFF166534) : const Color(0xFF374151),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int _readNum(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final direct = int.tryParse(source[key]?.toString() ?? '');
      if (direct != null) return direct;
      final snake = key
          .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]}')
          .toLowerCase();
      final snakeValue = int.tryParse(source[snake]?.toString() ?? '');
      if (snakeValue != null) return snakeValue;
    }
    return 0;
  }

  bool _isRead(Map<String, dynamic> row) {
    final value = row['isRead'] ?? row['read'];
    if (value is bool) return value;
    final text = value?.toString().toLowerCase() ?? '';
    return text == 'true' || text == '1';
  }

  String _displayName({
    String? firstName,
    String? lastName,
    String? email,
  }) {
    final first = _text(firstName ?? _user['firstName'] ?? _user['first_name']);
    final last = _text(lastName ?? _user['lastName'] ?? _user['last_name']);
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return _text(email ?? _user['username'] ?? _user['email'],
        fallback: 'Admin');
  }

  String _userName(Map<String, dynamic> row) {
    final first = _text(row['firstName'] ?? row['first_name']);
    final last = _text(row['lastName'] ?? row['last_name']);
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return _text(row['fullName'] ?? row['full_name'] ?? row['email'],
        fallback: 'User');
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'N/A';
    final month = <String>[
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
      'Dec'
    ][parsed.month - 1];
    return '$month ${parsed.day}, ${parsed.year}';
  }

  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _humanize(String value) {
    return value
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) =>
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _errorText(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  bool _canCreateOrganization({
    required Map<String, dynamic> user,
    required Map<String, dynamic> bootstrap,
  }) {
    return bootstrap['canCreate'] == true ||
        _text(user['role']).toLowerCase() == 'admin';
  }

  bool _needsOrganizationSetup({
    required Map<String, dynamic> user,
    required Map<String, dynamic> bootstrap,
    required Map<String, dynamic> organization,
  }) {
    final organizationsCount =
        _readNum(bootstrap, const ['organizationsCount']);
    return organization.isEmpty &&
        _canCreateOrganization(user: user, bootstrap: bootstrap) &&
        organizationsCount == 0;
  }

  String? _resolveDisplayError(
    List<String> errors, {
    required Map<String, dynamic> user,
    required Map<String, dynamic> bootstrap,
    required Map<String, dynamic> organization,
  }) {
    final sanitizedErrors = errors
        .where(
          (entry) => !entry.toLowerCase().startsWith('unable to load user'),
        )
        .toList();
    final dashboardErrors = sanitizedErrors
        .where((entry) => !_isSuppressedDashboardError(entry))
        .toList();

    if (!_needsOrganizationSetup(
      user: user,
      bootstrap: bootstrap,
      organization: organization,
    )) {
      return dashboardErrors.isEmpty ? null : dashboardErrors.first;
    }

    final visibleErrors =
        dashboardErrors.where((entry) => !_isSetupRelatedError(entry)).toList();
    return visibleErrors.isEmpty ? null : visibleErrors.first;
  }

  bool _isSuppressedDashboardError(String message) {
    final lower = message.toLowerCase();
    return lower.startsWith('unable to load ');
  }

  bool _isSetupRelatedError(String message) {
    final lower = message.toLowerCase();
    return lower.startsWith('unable to load organization') ||
        lower.startsWith('unable to load dashboard stats') ||
        lower.startsWith('unable to load inventory stats') ||
        lower.startsWith('unable to load pending appointments') ||
        lower.startsWith('unable to load pending invitations');
  }

  Widget _buildOrganizationSetupCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final content = [
            const Icon(
              Icons.business_outlined,
              color: Color(0xFFB45309),
              size: 28,
            ),
            if (!compact) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create your organization to finish admin setup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF92400E),
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This admin account is not linked to any organization yet. Open the organization screen and create one to unlock staff, billing, visits, and dashboard data.',
                    style: TextStyle(color: Color(0xFF92400E)),
                  ),
                ],
              ),
            ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openOrganizationSettings,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Create Organization'),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              ...content,
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openOrganizationSettings,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Create Organization'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200 ? 3 : (width > 900 ? 2 : 1);
        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.9,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Icon(metric.icon, color: metric.color),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(metric.title,
                          style: const TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 2),
                      Text('${metric.value}',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.title, this.value, this.icon, this.color);

  final String title;
  final Object value;
  final IconData icon;
  final Color color;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _QueueGroup extends StatelessWidget {
  const _QueueGroup({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: AppTheme.deepBlue),
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [child],
      ),
    );
  }
}

class _AppointmentActionRow extends StatelessWidget {
  const _AppointmentActionRow({
    required this.row,
    required this.onApprove,
    required this.onReject,
    required this.disabled,
  });

  final Map<String, dynamic> row;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final patient = _pick(const ['patientName', 'patient_name', 'name'],
        fallback: 'Patient');
    final reason = _pick(const ['reason', 'description', 'chiefComplaint'],
        fallback: '--');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(reason, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
              onPressed: disabled ? null : onReject,
              child: const Text('Reject')),
          const SizedBox(width: 6),
          ElevatedButton(
              onPressed: disabled ? null : onApprove,
              child: const Text('Approve')),
        ],
      ),
    );
  }

  String _pick(List<String> keys, {required String fallback}) {
    for (final key in keys) {
      final text = row[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }
}

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../data/healthreach_api.dart';
import '../../widgets/app_select.dart';

class AdminOrganizationPage extends StatefulWidget {
  const AdminOrganizationPage({super.key});

  @override
  State<AdminOrganizationPage> createState() => _AdminOrganizationPageState();
}

class _AdminOrganizationPageState extends State<AdminOrganizationPage> {
  final _api = HealthReachApi();

  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _loading = true;
  bool _savingSettings = false;
  String? _error;

  int _activeTab = 0;
  String _roleFilter = 'all';

  Map<String, dynamic> _bootstrap = const {};
  Map<String, dynamic> _organization = const {};
  Map<String, dynamic> _license = const {};
  Map<String, dynamic> _auditStats = const {};

  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _invitations = const [];
  List<Map<String, dynamic>> _labIntegrations = const [];
  List<Map<String, dynamic>> _auditLogs = const [];
  List<Map<String, dynamic>> _licensePlans = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
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

    final currentUser =
        await safeMap(_api.getCurrentUser, 'Unable to load user');
    final isAdminUser = _text(currentUser['role']).toLowerCase() == 'admin';
    final bootstrap = await safeMap(
      _api.getOrganizationBootstrapStatus,
      'Unable to load bootstrap status',
    );
    final organizations =
        await safeList(_api.getOrganizations, 'Unable to load organizations');

    var organization = await safeMap(
      _api.getMyOrganization,
      'Unable to load organization context',
    );

    if (organization.isEmpty && organizations.isNotEmpty) {
      organization = organizations.first;
    }

    final orgId = _text(organization['id']);

    List<Map<String, dynamic>> users = const [];
    List<Map<String, dynamic>> invitations = const [];
    List<Map<String, dynamic>> labIntegrations = const [];
    List<Map<String, dynamic>> auditLogs = const [];
    List<Map<String, dynamic>> licensePlans = const [];

    Map<String, dynamic> license = const {};
    Map<String, dynamic> auditStats = const {};

    if (orgId.isNotEmpty) {
      users = await safeList(
        () => _api.getOrganizationUsers(orgId),
        'Unable to load organization users',
      );
      invitations = _dedupeInvitations(
        await safeList(_api.getInvitations, 'Unable to load invitations'),
      );
      labIntegrations = await safeList(
        _api.getLabIntegrations,
        'Unable to load lab integrations',
      );
      try {
        final logs = await _api.getAuditLogs(limit: 40);
        auditLogs = logs.whereType<Map>().map((item) {
          return Map<String, dynamic>.from(
            item.map((k, v) => MapEntry(k.toString(), v)),
          );
        }).toList();
      } catch (_) {
        auditLogs = const [];
      }
      licensePlans =
          await safeList(_api.getLicensePlans, 'Unable to load license plans');

      license = await safeMap(
        () => _api.getOrganizationLicense(orgId),
        'Unable to load organization license',
      );
      try {
        auditStats = await _api.getAuditLogStats();
      } catch (_) {
        auditStats = const {};
      }
    }

    if (!mounted) return;
    setState(() {
      _bootstrap = bootstrap;
      _organization = organization;
      _users = users;
      _invitations = invitations;
      _labIntegrations = labIntegrations;
      _auditLogs = auditLogs;
      _licensePlans = licensePlans;
      _license = license;
      _auditStats = auditStats;
      _error = _resolveDisplayError(
        errors,
        bootstrap: bootstrap,
        organization: organization,
        organizations: organizations,
        isAdminUser: isAdminUser,
      );
      _loading = false;
    });

    _syncSettingsControllers();
  }

  void _syncSettingsControllers() {
    _nameController.text = _text(_organization['name']);
    _typeController.text = _text(_organization['type']);
    _emailController.text = _text(_organization['email']);
    _phoneController.text = _text(_organization['phone']);
    _addressController.text = _text(_organization['address']);
    _websiteController.text = _text(_organization['website']);
  }

  String get _orgId => _text(_organization['id']);

  Future<void> _saveSettings() async {
    if (_savingSettings) return;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _typeController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'website': _websiteController.text.trim(),
    };

    setState(() => _savingSettings = true);

    try {
      if (_orgId.isEmpty) {
        await _api.createOrganization(payload);
      } else {
        await _api.updateOrganization(_orgId, payload);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization settings updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _savingSettings = false);
      }
    }
  }

  Future<void> _updateOrgUserRole(
    Map<String, dynamic> row,
    String role,
  ) async {
    final userId = _text(row['userId'] ?? row['user_id'] ?? row['id']);
    if (_orgId.isEmpty || userId.isEmpty) return;

    await _api.updateOrganizationUser(
      orgId: _orgId,
      userId: userId,
      payload: {'orgRole': role},
    );
    await _load();
  }

  Future<void> _removeOrgUser(Map<String, dynamic> row) async {
    final userId = _text(row['userId'] ?? row['user_id'] ?? row['id']);
    if (_orgId.isEmpty || userId.isEmpty) return;

    await _api.deleteOrganizationUser(orgId: _orgId, userId: userId);
    await _load();
  }

  Future<void> _openInviteDialog() async {
    List<Map<String, dynamic>> candidates = const [];
    try {
      final raw = await _api.getInvitationCandidates();
      candidates = raw.whereType<Map>().map((item) {
        return Map<String, dynamic>.from(
          item.map((k, v) => MapEntry(k.toString(), v)),
        );
      }).toList();
    } catch (_) {
      // Candidate list is optional for invite flow.
    }

    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _InviteDialog(candidates: candidates),
    );
    if (result == null) return;

    await _api.createInvitation(
      email: result['email'] ?? '',
      firstName: result['firstName'],
      lastName: result['lastName'],
      role: result['role'] ?? 'medical_professional',
    );
    await _load();
  }

  Future<void> _openAddUserDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _AddUserDialog(),
    );
    if (result == null || _orgId.isEmpty) return;

    final createdUser = await _api.createUser({
      'firstName': result['firstName'] ?? '',
      'lastName': result['lastName'] ?? '',
      'email': result['email'] ?? '',
      'role': result['role'] ?? 'medical_professional',
    });

    final createdUserId = _text(createdUser['id']);
    if (createdUserId.isNotEmpty) {
      await _api.addOrganizationUser(
        orgId: _orgId,
        userId: createdUserId,
        orgRole: result['orgRole'] ?? 'medical_professional',
      );
    }

    await _load();
  }

  Future<void> _resendInvitation(Map<String, dynamic> row) async {
    final id = _text(row['id']);
    if (id.isEmpty) return;
    await _api.resendInvitation(id);
    await _load();
  }

  Future<void> _deleteInvitation(Map<String, dynamic> row) async {
    final id = _text(row['id']);
    if (id.isEmpty) return;
    await _api.deleteInvitation(id);
    await _load();
  }

  Future<void> _openLabDialog([Map<String, dynamic>? existing]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _LabIntegrationDialog(existing: existing),
    );
    if (result == null) return;

    final id = _text(existing?['id']);
    if (id.isEmpty) {
      await _api.createLabIntegration(result);
    } else {
      await _api.updateLabIntegration(id, result);
    }

    await _load();
  }

  Future<void> _deleteLabIntegration(Map<String, dynamic> row) async {
    final id = _text(row['id']);
    if (id.isEmpty) return;
    await _api.deleteLabIntegration(id);
    await _load();
  }

  Future<void> _subscribePlan(Map<String, dynamic> row) async {
    if (_orgId.isEmpty) return;

    final priceId = _text(row['priceId'] ?? row['price_id']);
    if (priceId.isEmpty) return;

    final response = await _api.subscribeOrganization(
      orgId: _orgId,
      priceId: priceId,
      planType: _text(row['planType'] ?? row['plan_type'], fallback: 'monthly'),
      userLimit: int.tryParse(
              _text(row['userLimit'] ?? row['user_limit'], fallback: '10')) ??
          10,
    );

    if (!mounted) return;
    final url = _text(response['url'], fallback: 'Checkout URL generated.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final setupRequired = _needsOrganizationSetup;
    final orgName = _text(
      _organization['name'],
      fallback: setupRequired ? 'Set Up Your Organization' : 'Organization',
    );
    final orgType = _text(
      _organization['type'],
      fallback: setupRequired
          ? 'Create an organization to unlock admin features.'
          : 'Organization',
    );
    final hasLicense = _license.isNotEmpty && _orgId.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 640 ? 12.0 : 24.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              24,
            ),
            children: [
              LayoutBuilder(
                builder: (context, headerConstraints) {
                  final badge = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: setupRequired
                          ? const Color(0xFFFFFBEB)
                          : hasLicense
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      setupRequired
                          ? 'SETUP REQUIRED'
                          : hasLicense
                              ? 'LICENSE ACTIVE'
                              : 'NO LICENSE',
                      style: TextStyle(
                        color: setupRequired
                            ? const Color(0xFF92400E)
                            : hasLicense
                                ? const Color(0xFF166534)
                                : const Color(0xFF991B1B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );

                  if (headerConstraints.maxWidth < 900) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orgName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          orgType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 10),
                        badge,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orgName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              orgType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      badge,
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFBCFE8)),
                    ),
                    child: Text(
                      _error!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFE06C75)),
                    ),
                  ),
                if (setupRequired) ...[
                  _buildSetupNotice(),
                  const SizedBox(height: 14),
                  _buildSettingsTab(setupMode: true),
                ] else ...[
                  LayoutBuilder(
                    builder: (context, cardsConstraints) {
                      final cards = [
                        _statCard(
                          icon: Icons.people_outline,
                          title: '${_users.length}',
                          subtitle: 'Active Staff',
                        ),
                        _statCard(
                          icon: Icons.credit_card,
                          title: _text(
                              _license['planName'] ?? _license['plan_type'],
                              fallback: 'None'),
                          subtitle: 'Current Plan',
                        ),
                        _statCard(
                          icon: Icons.calendar_month_outlined,
                          title: _date(
                              _license['expiresAt'] ?? _license['expires_at']),
                          subtitle: 'License Expires',
                        ),
                      ];

                      if (cardsConstraints.maxWidth >= 900) {
                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[1]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[2]),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 10),
                          cards[1],
                          const SizedBox(height: 10),
                          cards[2],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _tabs(),
                  const SizedBox(height: 12),
                  if (_activeTab == 0) _buildUsersTab(),
                  if (_activeTab == 1) _buildLabTab(),
                  if (_activeTab == 2) _buildAuditTab(),
                  if (_activeTab == 3) _buildBillingTab(),
                  if (_activeTab == 4) _buildSettingsTab(),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    final filtered = _users.where((row) {
      if (_roleFilter == 'all') return true;
      final role = _normalizeOrgRole(
        _text(row['orgRole'] ?? row['org_role'] ?? row['role']),
      );
      return role == _roleFilter;
    }).toList();

    return _card(
      title: 'Organization Users',
      subtitle: 'Manage users in your organization.',
      actions: [
        OutlinedButton.icon(
          onPressed: _openAddUserDialog,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add User Directly'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _openInviteDialog,
          icon: const Icon(Icons.person_add_alt_rounded),
          label: const Text('Send Invitation'),
        ),
      ],
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Filter by role:'),
              AppDropdownButton<String>(
                value: _roleFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Roles')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                      value: 'medical_professional',
                      child: Text('Medical Professional')),
                  DropdownMenuItem(
                      value: 'institutional_partner',
                      child: Text('Institutional Partner')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _roleFilter = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const Text('No users found.')
          else
            Column(
              children: filtered.map((row) {
                final orgRole = _normalizeOrgRole(_text(
                  row['orgRole'] ?? row['org_role'],
                  fallback: 'medical_professional',
                ));
                final roleItems = _roleDropdownItems(orgRole);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 760) {
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_userName(row),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(_text(row['email'], fallback: '-'),
                                      style: const TextStyle(
                                          color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            AppDropdownButton<String>(
                              value: orgRole,
                              items: roleItems,
                              onChanged: (value) {
                                if (value == null) return;
                                _updateOrgUserRole(row, value);
                              },
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _removeOrgUser(row),
                              child: const Text('Remove'),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName(row),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(_text(row['email'], fallback: '-'),
                              style:
                                  const TextStyle(color: AppTheme.textMuted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppDropdownButton<String>(
                                value: orgRole,
                                items: roleItems,
                                onChanged: (value) {
                                  if (value == null) return;
                                  _updateOrgUserRole(row, value);
                                },
                              ),
                              OutlinedButton(
                                onPressed: () => _removeOrgUser(row),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          _card(
            title: 'Pending Invitations',
            subtitle: 'Invitations sent but not yet accepted.',
            child: _invitations.isEmpty
                ? const Text('No pending invitations.')
                : Column(
                    children: _invitations.map((row) {
                      final email = _text(row['email'], fallback: 'Unknown');
                      final expires =
                          _date(row['expires_at'] ?? row['expiresAt']);
                      return ListTile(
                        dense: true,
                        title: Text(email),
                        subtitle: Text('Expires $expires'),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            IconButton(
                              onPressed: () => _resendInvitation(row),
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                            IconButton(
                              onPressed: () => _deleteInvitation(row),
                              icon: const Icon(Icons.cancel_outlined),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabTab() {
    return _card(
      title: 'Lab Systems',
      subtitle: 'Manage lab integration endpoints.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openLabDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Integration'),
        ),
      ],
      child: _labIntegrations.isEmpty
          ? const Text('No lab integrations configured.')
          : Column(
              children: _labIntegrations.map((row) {
                final name = _text(row['name'], fallback: 'Integration');
                final isActive =
                    (row['isActive'] == true || row['is_active'] == true);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          final updated = Map<String, dynamic>.from(row);
                          updated['isActive'] = value;
                          _openLabDialog(updated);
                        },
                      ),
                      IconButton(
                        onPressed: () => _openLabDialog(row),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _deleteLabIntegration(row),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAuditTab() {
    return _card(
      title: 'Audit Logs',
      subtitle: 'Recent organization activity.',
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            await _api.exportAuditLogs(format: 'csv');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audit log export requested.')),
            );
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Total: ${_readNum(_auditStats, const ['total'])}'),
              _pill('Creates: ${_readNum(_auditStats, const ['create'])}'),
              _pill('Updates: ${_readNum(_auditStats, const ['update'])}'),
              _pill('Deletes: ${_readNum(_auditStats, const ['delete'])}'),
            ],
          ),
          const SizedBox(height: 10),
          if (_auditLogs.isEmpty)
            const Text('No audit logs found.')
          else
            Column(
              children: _auditLogs.take(25).map((row) {
                final action = _text(row['action'], fallback: '-');
                final entity = _text(row['entityType'] ?? row['entity_type'],
                    fallback: '-');
                final at = _date(row['createdAt'] ?? row['created_at']);
                return ListTile(
                  dense: true,
                  title: Text('${_humanize(action)} - ${_humanize(entity)}'),
                  subtitle: Text(at),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return _card(
      title: 'Billing',
      subtitle: 'License and subscription plans.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _license.isEmpty
                ? 'No active license found.'
                : 'Current plan: ${_text(_license['planName'] ?? _license['plan_type'], fallback: 'Plan')}',
          ),
          const SizedBox(height: 10),
          if (_licensePlans.isEmpty)
            const Text('No plans available.')
          else
            Column(
              children: _licensePlans.map((row) {
                final title = _text(
                    row['name'] ?? row['planType'] ?? row['plan_type'],
                    fallback: 'Plan');
                final amount = _text(row['amount'], fallback: '-');
                final userLimit =
                    _text(row['userLimit'] ?? row['user_limit'], fallback: '-');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
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
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text('Amount: $amount | Seats: $userLimit',
                                style:
                                    const TextStyle(color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _subscribePlan(row),
                        child: const Text('Subscribe'),
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

  Widget _buildSettingsTab({bool setupMode = false}) {
    final canCreate = _canCreateOrganization;

    return _card(
      title: 'Organization Settings',
      subtitle: setupMode
          ? 'Create the first organization for this admin account.'
          : 'Manage organization details.',
      child: Column(
        children: [
          if (setupMode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBECBFF)),
              ),
              child: const Text(
                'Enter the organization name and type, then tap Create Organization. The current admin account will be linked automatically.',
                style: TextStyle(color: AppTheme.deepBlue),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _field('Organization Name', _nameController),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field('Type', _typeController)),
              const SizedBox(width: 10),
              Expanded(child: _field('Phone', _phoneController)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field('Email', _emailController)),
              const SizedBox(width: 10),
              Expanded(child: _field('Website', _websiteController)),
            ],
          ),
          const SizedBox(height: 10),
          _field('Address', _addressController),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!setupMode) ...[
                OutlinedButton(
                  onPressed: _syncSettingsControllers,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 10),
              ],
              ElevatedButton(
                onPressed: (_orgId.isNotEmpty || canCreate) && !_savingSettings
                    ? _saveSettings
                    : null,
                child: Text(
                  _savingSettings
                      ? (setupMode ? 'Creating...' : 'Saving...')
                      : (setupMode ? 'Create Organization' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    const tabs = [
      'Users',
      'Lab Systems',
      'Audit Logs',
      'Billing',
      'Settings',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(tabs.length, (index) {
        final selected = index == _activeTab;
        return InkWell(
          onTap: () => setState(() => _activeTab = index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEFF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFFBECBFF) : AppTheme.border,
              ),
            ),
            child: Text(
              tabs[index],
              style: TextStyle(
                color: selected ? AppTheme.deepBlue : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.deepBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    String? subtitle,
    List<Widget> actions = const [],
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: AppTheme.textMuted)),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ],
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: Theme.of(context).textTheme.titleLarge),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style:
                                    const TextStyle(color: AppTheme.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ],
              const SizedBox(height: 10),
              child,
            ],
          );
        },
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(text),
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

  String _userName(Map<String, dynamic> row) {
    final first = _text(row['firstName'] ?? row['first_name']);
    final last = _text(row['lastName'] ?? row['last_name']);
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return _text(row['fullName'] ?? row['full_name'] ?? row['email'],
        fallback: 'User');
  }

  List<Map<String, dynamic>> _dedupeInvitations(
    List<Map<String, dynamic>> rows,
  ) {
    final map = <String, Map<String, dynamic>>{};

    DateTime? eventDate(Map<String, dynamic> row) {
      return DateTime.tryParse(
        _text(
          row['updatedAt'] ??
              row['updated_at'] ??
              row['createdAt'] ??
              row['created_at'],
        ),
      );
    }

    for (final row in rows) {
      final token = _text(row['token']);
      final id = _text(row['id']);
      final email = _text(row['email']).toLowerCase();
      final role = _normalizeOrgRole(
        _text(row['role'] ?? row['orgRole'] ?? row['org_role']),
      );
      final expires = _text(row['expiresAt'] ?? row['expires_at']);

      final key = token.isNotEmpty
          ? 'token:$token'
          : (id.isNotEmpty ? 'id:$id' : 'fallback:$email|$role|$expires');

      final existing = map[key];
      if (existing == null) {
        map[key] = row;
        continue;
      }

      final currentDate = eventDate(row);
      final previousDate = eventDate(existing);
      if (currentDate != null &&
          (previousDate == null || currentDate.isAfter(previousDate))) {
        map[key] = row;
      }
    }

    final pendingOnly = map.values.where((row) {
      final status = _text(row['status']).toLowerCase();
      if (status.isEmpty) return true;
      return status == 'pending' || status == 'sent';
    }).toList();

    pendingOnly.sort((a, b) {
      final bDate = DateTime.tryParse(_text(b['expiresAt'] ?? b['expires_at']));
      final aDate = DateTime.tryParse(_text(a['expiresAt'] ?? a['expires_at']));
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return pendingOnly;
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
    final text = value.trim();
    if (text.isEmpty) return '-';
    return text
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) =>
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _normalizeOrgRole(String value) {
    final role = value.trim().toLowerCase();
    if (role == 'org_admin') return 'admin';
    if (role == 'org_medical_professional') return 'medical_professional';
    if (role == 'org_institutional_partner') return 'institutional_partner';
    if (role.isEmpty) return 'medical_professional';
    return role;
  }

  List<DropdownMenuItem<String>> _roleDropdownItems(String currentRole) {
    const defaults = [
      'admin',
      'medical_professional',
      'institutional_partner',
    ];

    final values = <String>{...defaults};
    values.add(currentRole);

    return values.map((role) {
      return DropdownMenuItem(
        value: role,
        child: Text(_humanize(role)),
      );
    }).toList();
  }

  String _errorText(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  bool get _canCreateOrganization {
    return _bootstrap['canCreate'] == true ||
        AuthScope.of(context).user?.role == 'admin';
  }

  bool get _needsOrganizationSetup {
    final organizationsCount =
        _readNum(_bootstrap, const ['organizationsCount']);
    return _organization.isEmpty &&
        _canCreateOrganization &&
        organizationsCount == 0;
  }

  String? _resolveDisplayError(
    List<String> errors, {
    required Map<String, dynamic> bootstrap,
    required Map<String, dynamic> organization,
    required List<Map<String, dynamic>> organizations,
    required bool isAdminUser,
  }) {
    final sanitizedErrors = errors
        .where(
          (entry) => !entry.toLowerCase().startsWith('unable to load user'),
        )
        .toList();

    final canCreate = bootstrap['canCreate'] == true || isAdminUser;
    final knownOrganizations = organization.isNotEmpty ||
        organizations.isNotEmpty ||
        _readNum(bootstrap, const ['organizationsCount']) > 0;
    final setupRequired = !knownOrganizations && canCreate;

    if (!setupRequired) {
      return sanitizedErrors.isEmpty ? null : sanitizedErrors.first;
    }

    final visibleErrors =
        sanitizedErrors.where((entry) => !_isSetupRelatedError(entry)).toList();
    return visibleErrors.isEmpty ? null : visibleErrors.first;
  }

  bool _isSetupRelatedError(String message) {
    final lower = message.toLowerCase();
    return lower.startsWith('unable to load organizations') ||
        lower.startsWith('unable to load organization context') ||
        lower.startsWith('unable to load bootstrap status');
  }

  Widget _buildSetupNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB45309),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No organization is linked to this admin account yet. Create one below to activate organization users, billing, invitations, and settings.',
              style: TextStyle(color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteDialog extends StatefulWidget {
  const _InviteDialog({required this.candidates});

  final List<Map<String, dynamic>> candidates;

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String _role = 'medical_professional';
  String? _selectedCandidateEmail;

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite New User'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.candidates.isNotEmpty) ...[
              AppDropdownFormField<String>(
                value: _selectedCandidateEmail,
                decoration: const InputDecoration(labelText: 'Select User'),
                items: widget.candidates.map((candidate) {
                  final email = candidate['email']?.toString().trim() ?? '';
                  final name = _candidateName(candidate);
                  final label = name.isEmpty ? email : '$name ($email)';
                  return DropdownMenuItem<String>(
                    value: email,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final candidate = widget.candidates.firstWhere(
                    (item) => (item['email']?.toString().trim() ?? '') == value,
                    orElse: () => const <String, dynamic>{},
                  );
                  setState(() {
                    _selectedCandidateEmail = value;
                    _email.text = value;
                    final first = candidate['firstName']?.toString().trim() ??
                        candidate['first_name']?.toString().trim() ??
                        '';
                    final last = candidate['lastName']?.toString().trim() ??
                        candidate['last_name']?.toString().trim() ??
                        '';
                    if (first.isNotEmpty) _firstName.text = first;
                    if (last.isNotEmpty) _lastName.text = last;
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 8),
            AppDropdownFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Invite Role'),
              items: const [
                DropdownMenuItem(
                  value: 'medical_professional',
                  child: Text('Medical Professional'),
                ),
                DropdownMenuItem(
                  value: 'institutional_partner',
                  child: Text('Institutional Partner'),
                ),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'email': _email.text.trim(),
              'firstName': _firstName.text.trim(),
              'lastName': _lastName.text.trim(),
              'role': _role,
            });
          },
          child: const Text('Send Invitation'),
        ),
      ],
    );
  }

  String _candidateName(Map<String, dynamic> row) {
    final first = row['firstName']?.toString().trim() ??
        row['first_name']?.toString().trim() ??
        '';
    final last = row['lastName']?.toString().trim() ??
        row['last_name']?.toString().trim() ??
        '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return row['name']?.toString().trim() ??
        row['fullName']?.toString().trim() ??
        '';
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String _role = 'medical_professional';
  String _orgRole = 'medical_professional';

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add User Directly'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'First Name')),
            const SizedBox(height: 8),
            TextField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Last Name')),
            const SizedBox(height: 8),
            AppDropdownFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'User Role'),
              items: const [
                DropdownMenuItem(
                    value: 'medical_professional',
                    child: Text('Medical Professional')),
                DropdownMenuItem(
                    value: 'institutional_partner',
                    child: Text('Institutional Partner')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = value);
              },
            ),
            const SizedBox(height: 8),
            AppDropdownFormField<String>(
              value: _orgRole,
              decoration: const InputDecoration(labelText: 'Org Role'),
              items: const [
                DropdownMenuItem(
                    value: 'medical_professional',
                    child: Text('Medical Professional')),
                DropdownMenuItem(
                    value: 'institutional_partner',
                    child: Text('Institutional Partner')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _orgRole = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'email': _email.text.trim(),
              'firstName': _firstName.text.trim(),
              'lastName': _lastName.text.trim(),
              'role': _role,
              'orgRole': _orgRole,
            });
          },
          child: const Text('Add User'),
        ),
      ],
    );
  }
}

class _LabIntegrationDialog extends StatefulWidget {
  const _LabIntegrationDialog({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_LabIntegrationDialog> createState() => _LabIntegrationDialogState();
}

class _LabIntegrationDialogState extends State<_LabIntegrationDialog> {
  late final TextEditingController _name;
  late final TextEditingController _endpoint;
  late final TextEditingController _apiKey;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _name =
        TextEditingController(text: widget.existing?['name']?.toString() ?? '');
    _endpoint = TextEditingController(
        text: widget.existing?['endpoint']?.toString() ?? '');
    _apiKey = TextEditingController(
        text: widget.existing?['apiKey']?.toString() ?? '');
    _isActive = widget.existing?['isActive'] == true ||
        widget.existing?['is_active'] == true;
  }

  @override
  void dispose() {
    _name.dispose();
    _endpoint.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'Add Lab Integration'
          : 'Edit Lab Integration'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(
                controller: _endpoint,
                decoration: const InputDecoration(labelText: 'Endpoint URL')),
            const SizedBox(height: 8),
            TextField(
                controller: _apiKey,
                decoration: const InputDecoration(labelText: 'API Key')),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isActive,
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'name': _name.text.trim(),
              'endpoint': _endpoint.text.trim(),
              'apiKey': _apiKey.text.trim(),
              'isActive': _isActive,
            });
          },
          child: Text(widget.existing == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

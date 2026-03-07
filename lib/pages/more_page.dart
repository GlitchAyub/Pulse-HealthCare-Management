import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/auth_scope.dart';
import '../data/healthreach_api.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _organization;

  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  Future<void> _loadOrganization() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getMyOrganization();
      if (!mounted) return;
      setState(() {
        _organization = data;
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
    final textTheme = Theme.of(context).textTheme;
    final authController = AuthScope.of(context);
    final user = authController.user;
    final name = _displayName(user?.firstName, user?.lastName, user?.email);

    final items = const [
      _MoreItem('Profile', Icons.person_outline_rounded),
      _MoreItem('Medical Records', Icons.folder_open_rounded),
      _MoreItem('Notifications', Icons.notifications_none_rounded),
      _MoreItem('Settings', Icons.settings_outlined),
      _MoreItem('Support', Icons.support_agent_rounded),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadOrganization,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('More',
                  style: textTheme.titleLarge
                      ?.copyWith(color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.softBlue,
                      child: Icon(Icons.person, color: AppTheme.deepBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: textTheme.titleSmall),
                          Text(
                            user?.role.replaceAll('_', ' ') ?? 'Member',
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Organization', style: textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: LinearProgressIndicator(),
                      )
                    else if (_error != null)
                      Text(
                        _error!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFFE06C75)),
                      )
                    else if (_organization == null || _organization!.isEmpty)
                      Text(
                        'No organization linked.',
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppTheme.textMuted),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Name',
                            value: _organization?['name']?.toString() ?? '-',
                          ),
                          _InfoRow(
                            label: 'Plan',
                            value: _organization?['plan_type']?.toString() ??
                                _organization?['planType']?.toString() ??
                                '-',
                          ),
                          _InfoRow(
                            label: 'Status',
                            value: _organization?['license_status']
                                    ?.toString() ??
                                _organization?['licenseStatus']?.toString() ??
                                '-',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...items.map((item) => _MoreTile(item: item)).toList(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: authController.isBusy
                      ? null
                      : () async {
                          await authController.logout();
                        },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.deepBlue,
                    side: const BorderSide(color: AppTheme.border),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayName(String? first, String? last, String? email) {
    final full = '${first ?? ''} ${last ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    if (email != null && email.isNotEmpty) return email;
    return 'Member';
  }
}

class _MoreItem {
  const _MoreItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.item});
  final _MoreItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.label, style: textTheme.bodyLarge),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

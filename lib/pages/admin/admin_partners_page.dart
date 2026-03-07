import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';

class AdminPartnersPage extends StatefulWidget {
  const AdminPartnersPage({super.key});

  @override
  State<AdminPartnersPage> createState() => _AdminPartnersPageState();
}

class _AdminPartnersPageState extends State<AdminPartnersPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  List<dynamic> _partners = const [];

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

    try {
      final partners = await _api.getPartnerPermissions();
      if (!mounted) return;
      setState(() {
        _partners = partners;
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
                    Text('Partner Permissions',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Configure data access for institutional partners',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textMuted)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Partners'),
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
          else if (_partners.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  const Icon(Icons.group_outlined,
                      size: 40, color: AppTheme.textMuted),
                  const SizedBox(height: 8),
                  Text('No Institutional Partners',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppTheme.textPrimary)),
                  Text(
                      'There are no institutional partners in your organization yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Add Partners'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _partners
                  .whereType<Map<String, dynamic>>()
                  .map((partner) => _PartnerRow(partner: partner))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({required this.partner});

  final Map<String, dynamic> partner;

  @override
  Widget build(BuildContext context) {
    final name =
        '${partner['first_name'] ?? partner['firstName'] ?? ''} ${partner['last_name'] ?? partner['lastName'] ?? ''}'
            .trim();
    final email = partner['email']?.toString() ?? '-';

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
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.softBlue,
            child: Icon(Icons.person, color: AppTheme.deepBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Partner' : name,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                Text(email,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }
}

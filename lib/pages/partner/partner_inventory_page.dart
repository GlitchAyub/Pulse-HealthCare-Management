import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';
import '../invitations/accept_invitation_page.dart';

class PartnerInventoryPage extends StatefulWidget {
  const PartnerInventoryPage({super.key});

  @override
  State<PartnerInventoryPage> createState() => _PartnerInventoryPageState();
}

class _PartnerInventoryPageState extends State<PartnerInventoryPage> {
  final _api = HealthReachApi();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _organization = const {};
  Map<String, dynamic> _stats = const {};
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _pendingInvitations = const [];

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

    Future<Map<String, dynamic>> safeMap(
      Future<Map<String, dynamic>> Function() fn, {
      String? softError,
    }) async {
      try {
        return await fn();
      } on ApiException catch (error) {
        if (!_isSoftError(error) && loadError == null) {
          loadError = softError ?? error.message;
        }
        return <String, dynamic>{};
      } catch (error) {
        loadError ??= error.toString();
        return <String, dynamic>{};
      }
    }

    Future<List<Map<String, dynamic>>> safeList(
      Future<List<dynamic>> Function() fn, {
      String? softError,
    }) async {
      try {
        final items = await fn();
        return items.whereType<Map>().map((item) {
          return Map<String, dynamic>.from(
            item.map((key, value) => MapEntry(key.toString(), value)),
          );
        }).toList();
      } on ApiException catch (error) {
        if (!_isSoftError(error) && loadError == null) {
          loadError = softError ?? error.message;
        }
        return const <Map<String, dynamic>>[];
      } catch (error) {
        loadError ??= error.toString();
        return const <Map<String, dynamic>>[];
      }
    }

    final organization = await safeMap(_api.getMyOrganization);
    final pendingInvitations = await safeList(_api.getMyPendingInvitations);

    Map<String, dynamic> stats = const {};
    List<Map<String, dynamic>> items = const [];

    final orgId = _readText(organization, const ['id'], fallback: '');

    if (orgId.isNotEmpty) {
      stats = await safeMap(
        _api.getInventoryStats,
        softError:
            'Inventory access is restricted for your account. Contact your admin for access.',
      );
      items = await safeList(
        _api.getInventory,
        softError:
            'Inventory access is restricted for your account. Contact your admin for access.',
      );
    }

    if (!mounted) return;
    setState(() {
      _organization = organization;
      _stats = stats;
      _items = items;
      _pendingInvitations = pendingInvitations;
      _error = loadError;
      _loading = false;
    });
  }

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

  bool _isSoftError(ApiException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == 401 ||
        error.statusCode == 403 ||
        error.statusCode == 404 ||
        error.statusCode == 405 ||
        error.statusCode == 501 ||
        message.contains('returned html instead of json');
  }

  @override
  Widget build(BuildContext context) {
    final hasOrganization =
        _readText(_organization, const ['id'], fallback: '').isNotEmpty;
    final organizationName =
        _readText(_organization, const ['name'], fallback: 'Not linked');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Inventory',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Review organization inventory access and stock information.',
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
          else ...[
            if (_pendingInvitations.isNotEmpty) ...[
              _PendingInvitationsCard(
                invitations: _pendingInvitations,
                onReview: _reviewInvitation,
              ),
              const SizedBox(height: 16),
            ],
            _PartnerInventoryStatusCard(
              title: hasOrganization
                  ? 'Organization Linked'
                  : 'Organization Access Required',
              message: hasOrganization
                  ? 'You are linked to $organizationName. Inventory is shown below when your account has access.'
                  : "You can't add inventory until you are linked to an organization. Contact your admin to invite you.",
              tone: hasOrganization
                  ? const Color(0xFFEAF3FF)
                  : const Color(0xFFFFF7E6),
              border: hasOrganization
                  ? const Color(0xFFB9D3FF)
                  : const Color(0xFFECC76A),
              icon: hasOrganization
                  ? Icons.apartment_outlined
                  : Icons.info_outline_rounded,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _PartnerInventoryStatusCard(
                title: 'Inventory Notice',
                message: _error!,
                tone: const Color(0xFFFFF1F2),
                border: const Color(0xFFFBCFE8),
                icon: Icons.warning_amber_rounded,
              ),
            ],
            if (hasOrganization && _stats.isNotEmpty) ...[
              const SizedBox(height: 16),
              _StatsSection(stats: _stats),
            ],
            if (hasOrganization) ...[
              const SizedBox(height: 16),
              _InventoryListCard(items: _items),
            ],
          ],
        ],
      ),
    );
  }
}

class _PartnerInventoryStatusCard extends StatelessWidget {
  const _PartnerInventoryStatusCard({
    required this.title,
    required this.message,
    required this.tone,
    required this.border,
    required this.icon,
  });

  final String title;
  final String message;
  final Color tone;
  final Color border;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.deepBlue),
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
                const SizedBox(height: 4),
                Text(
                  message,
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

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatTile(
        label: 'Total Items',
        value: _readStat(stats, const ['totalItems']),
        icon: Icons.inventory_2_outlined,
      ),
      _StatTile(
        label: 'Low Stock',
        value: _readStat(stats, const ['lowStock']),
        icon: Icons.trending_down_rounded,
      ),
      _StatTile(
        label: 'Expiring Soon',
        value: _readStat(stats, const ['expiringSoon']),
        icon: Icons.schedule_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        if (compact) {
          return Column(
            children: cards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card,
                    ))
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
              color: AppTheme.skyBlue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryListCard extends StatelessWidget {
  const _InventoryListCard({required this.items});

  final List<Map<String, dynamic>> items;

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
            'Inventory Items',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Read-only inventory snapshot for your organization.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No inventory items found.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted),
            )
          else
            Column(
              children: items
                  .take(12)
                  .map((item) => _InventoryRow(item: item))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = _readText(
      item,
      const ['medicationName', 'medication_name'],
      fallback: 'Medication',
    );
    final category = _readText(item, const ['category'], fallback: 'other');
    final qty = _readText(
      item,
      const ['quantityInStock', 'quantity_in_stock', 'quantity'],
      fallback: '0',
    );

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
          const Icon(Icons.medication_outlined, color: AppTheme.deepBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  _humanize(category),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            qty,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppTheme.deepBlue),
          ),
        ],
      ),
    );
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
              Expanded(
                child: Text(
                  'Pending Organization Invitations (${invitations.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...invitations.map(
            (invitation) => _PendingInvitationRow(
              invitation: invitation,
              onReview: () => onReview(invitation),
            ),
          ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final details = Column(
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
          );

          final button = ElevatedButton(
            onPressed: onReview,
            child: const Text('Review & Accept'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 8),
              button,
            ],
          );
        },
      ),
    );
  }
}

String _readStat(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value != null) return value.toString();
  }
  return '0';
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
  final words = text.split(RegExp(r'[_\\s]+'));
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

String _humanize(String value) {
  final text = value.trim();
  if (text.isEmpty) return '-';
  return text
      .split(RegExp(r'[_\\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) =>
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

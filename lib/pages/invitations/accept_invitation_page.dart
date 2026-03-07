import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';

class AcceptInvitationPage extends StatefulWidget {
  const AcceptInvitationPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<AcceptInvitationPage> createState() => _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends State<AcceptInvitationPage> {
  final _api = HealthReachApi();

  bool _loading = true;
  bool _accepting = false;
  String? _error;
  Map<String, dynamic>? _invitation;

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final invitation = await _api.getInvitationByToken(widget.token);
      if (!mounted) return;
      setState(() {
        _invitation = invitation;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _acceptInvitation() async {
    setState(() {
      _accepting = true;
      _error = null;
    });

    try {
      await _api.acceptInvitation(widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation accepted successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _accepting = false;
      });
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final invitation = _invitation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Invitation'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : invitation == null
                        ? _ErrorView(
                            message: _error ?? 'Unable to load invitation.',
                            onRetry: _loadInvitation,
                          )
                        : _InvitationDetails(
                            invitation: invitation,
                            accepting: _accepting,
                            error: _error,
                            onDecline: () => Navigator.of(context).pop(false),
                            onAccept: _acceptInvitation,
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitationDetails extends StatelessWidget {
  const _InvitationDetails({
    required this.invitation,
    required this.accepting,
    required this.error,
    required this.onDecline,
    required this.onAccept,
  });

  final Map<String, dynamic> invitation;
  final bool accepting;
  final String? error;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final organization = _readText(
      invitation,
      const ['organization_name', 'organizationName', 'organization'],
      fallback: 'Organization',
    );
    final role = _readText(invitation, const ['role'], fallback: 'Member');
    final invitee = _readText(
      invitation,
      const ['name', 'fullName', 'email', 'username'],
      fallback: 'Not provided',
    );
    final expires =
        _formatDate(invitation['expires_at'] ?? invitation['expiresAt']);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFDDEAFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: AppTheme.deepBlue,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "You're Invited!",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'You have been invited to join an organization on HealthReach.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _InfoRow(label: 'Organization', value: organization),
              _InfoRow(label: 'Your Role', value: _roleLabel(role)),
              _InfoRow(label: 'Name', value: invitee),
              _InfoRow(label: 'Expires', value: expires, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFECC76A)),
          ),
          child: Text(
            'Accepting this invitation will update your role and add you to this organization.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF9A6A00)),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFFE06C75)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: accepting ? null : onDecline,
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: accepting ? null : onAccept,
                child: accepting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Accept Invitation'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: const Color(0xFFE06C75)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
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
  final words = role.split(RegExp(r'[_\s]+'));
  final result = words
      .where((word) => word.isNotEmpty)
      .map((word) =>
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
  return result.isEmpty ? 'Member' : result;
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

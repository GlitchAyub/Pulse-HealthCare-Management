import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';
import '../../widgets/app_select.dart';
import '../invitations/accept_invitation_page.dart';

class PartnerDashboardPage extends StatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;
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

    try {
      final stats = await _api.getDashboardStats();
      final pendingInvitations = await _api.getMyPendingInvitations();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _pendingInvitations = pendingInvitations;
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
    final invitationItems = _pendingInvitations
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final totalPatients = _stats?['activePatients'] ??
        _stats?['active_patients'] ??
        _stats?['totalPatients'] ??
        _stats?['total_patients'] ??
        0;
    final totalVisits = _stats?['totalVisits'] ??
        _stats?['total_visits'] ??
        _stats?['visits'] ??
        0;
    final activeConsults = _stats?['upcomingConsultations'] ??
        _stats?['upcoming_consultations'] ??
        _stats?['activeConsultations'] ??
        _stats?['active_consultations'] ??
        0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Partner Organization Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text('Institutional Partner - Aggregated Health Statistics',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB9D3FF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.deepBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy Protected',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppTheme.textPrimary)),
                      Text(
                        'All data shown is aggregated and anonymized. Individual patient information is not accessible.',
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
              padding: const EdgeInsets.only(bottom: 16),
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
                  _StatCard(
                    title: 'Total Patients',
                    value: totalPatients.toString(),
                    subtitle: 'Registered in system',
                    icon: Icons.people_outline,
                  ),
                  _StatCard(
                    title: 'Total Visits',
                    value: totalVisits.toString(),
                    subtitle: 'Medical consultations',
                    icon: Icons.monitor_heart_outlined,
                  ),
                  _StatCard(
                    title: 'Active Consultations',
                    value: activeConsults.toString(),
                    subtitle: 'Currently scheduled',
                    icon: Icons.videocam_outlined,
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
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                final exportType = SizedBox(
                  width: compact ? 104 : null,
                  child: AppDropdownButton<String>(
                    value: 'CSV',
                    items: const [
                      DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                      DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                    ],
                    onChanged: (_) {},
                    isExpanded: compact,
                  ),
                );
                final exportButton = OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined),
                  label: Text(compact ? 'Export' : 'Export Data'),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _ChipTab(label: 'Analytics', selected: true),
                          _ChipTab(label: 'Trends', selected: false),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          exportType,
                          exportButton,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    const _ChipTab(label: 'Analytics', selected: true),
                    const SizedBox(width: 8),
                    const _ChipTab(label: 'Trends', selected: false),
                    const Spacer(),
                    exportType,
                    const SizedBox(width: 8),
                    exportButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final cards = [
                  _MiniMetricCard(
                      title: 'Total Patients', value: totalPatients),
                  _MiniMetricCard(title: 'Total Visits', value: totalVisits),
                  _MiniMetricCard(
                      title: 'Active Consultations', value: activeConsults),
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
                final weeklyCard = _ChartCard(
                  title: 'Weekly Visit Volume',
                  child: const _BarChart(
                    data: [
                      _BarData('Mon', 12),
                      _BarData('Tue', 18),
                      _BarData('Wed', 15),
                      _BarData('Thu', 22),
                      _BarData('Fri', 18),
                      _BarData('Sat', 8),
                      _BarData('Sun', 5),
                    ],
                  ),
                );
                final pieCard = _ChartCard(
                  title: 'Condition Distribution',
                  child: const _PieChart(
                    segments: [
                      _PieSegment('Hypertension', 35, Color(0xFF2D65F2)),
                      _PieSegment('Diabetes', 25, Color(0xFF1B9E4B)),
                      _PieSegment('Respiratory', 20, Color(0xFFF0670C)),
                      _PieSegment('Maternal', 15, Color(0xFF8A57FF)),
                      _PieSegment('Other', 5, Color(0xFF20B6E8)),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: weeklyCard),
                      const SizedBox(width: 12),
                      Expanded(child: pieCard),
                    ],
                  );
                }
                return Column(
                  children: [
                    weeklyCard,
                    const SizedBox(height: 12),
                    pieCard,
                  ],
                );
              },
            ),
          ],
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppTheme.textPrimary),
                ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
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
          Expanded(
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
                        .titleMedium
                        ?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          Icon(icon, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _ChipTab extends StatelessWidget {
  const _ChipTab({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.background : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppTheme.textPrimary)),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({required this.title, required this.value});

  final String title;
  final Object value;

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
      child: Column(
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Text(value.toString(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BarData {
  const _BarData(this.label, this.value);

  final String label;
  final double value;
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});

  final List<_BarData> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data
        .map((d) => d.value)
        .fold<double>(0, (prev, value) => value > prev ? value : prev);

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data
            .map(
              (item) => Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 140,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 26,
                          height:
                              maxValue == 0 ? 0 : (item.value / maxValue) * 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D65F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.label,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppTheme.textMuted)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PieSegment {
  const _PieSegment(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.segments});

  final List<_PieSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, seg) => sum + seg.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 380;
        final legend = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: segments
              .map(
                (seg) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: seg.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${seg.label} ${seg.value.toInt()}%',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _PiePainter(segments: segments, total: total),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: legend),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _PiePainter(segments: segments, total: total),
              ),
            ),
            const SizedBox(height: 16),
            legend,
          ],
        );
      },
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.segments, required this.total});

  final List<_PieSegment> segments;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    var startAngle = -1.5708;

    for (final seg in segments) {
      final sweep = (seg.value / total) * 6.28318;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweep, true, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

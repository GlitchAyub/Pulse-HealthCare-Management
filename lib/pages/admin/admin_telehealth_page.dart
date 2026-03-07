import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class AdminTelehealthPage extends StatelessWidget {
  const AdminTelehealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Advanced Telemedicine Platform',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppTheme.textPrimary)),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Start Demo Video Call'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final cards = const [
              _InfoCard(
                title: 'HD Video Calls',
                subtitle: 'Crystal clear video consultations with quality monitoring',
                icon: Icons.videocam_outlined,
              ),
              _InfoCard(
                title: 'Call Recording',
                subtitle: 'Secure recording with patient consent management',
                icon: Icons.mic_none_outlined,
              ),
              _InfoCard(
                title: 'File Sharing',
                subtitle: 'Share documents, images, and reports during calls',
                icon: Icons.folder_open_outlined,
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
        const SizedBox(height: 20),
        _Section(
          title: 'Telemedicine',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2ECC71)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No active consultation',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppTheme.textPrimary)),
                      Text('Ready to connect when needed',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Start Call'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final sections = const [
              _Section(
                title: 'Recording Features',
                child: _FeatureList(items: [
                  'Patient Consent Management',
                  'Audio Level Monitoring',
                  'Automatic Download',
                ]),
              ),
              _Section(
                title: 'File Sharing Capabilities',
                child: _FeatureList(items: [
                  'Multiple File Types',
                  'Patient Privacy Controls',
                  'Real-time Sharing',
                ]),
              ),
            ];

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: sections[0]),
                  const SizedBox(width: 12),
                  Expanded(child: sections[1]),
                ],
              );
            }

            return Column(
              children: sections
                  .map((section) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: section,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

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
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
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
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

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

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppTheme.deepBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textPrimary)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

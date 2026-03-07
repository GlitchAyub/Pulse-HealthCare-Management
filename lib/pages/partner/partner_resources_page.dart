import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/healthreach_api.dart';

class PartnerResourcesPage extends StatefulWidget {
  const PartnerResourcesPage({super.key});

  @override
  State<PartnerResourcesPage> createState() => _PartnerResourcesPageState();
}

class _PartnerResourcesPageState extends State<PartnerResourcesPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  List<dynamic> _resources = const [];

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
      final resources = await _api.getHealthResources();
      if (!mounted) return;
      setState(() {
        _resources = resources;
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
          Text('Health Education',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final cards = const [
                _CategoryCard(
                  title: 'Mental Health',
                  subtitle: 'Resources for mental well-being and support',
                  color: Color(0xFFEFE8FF),
                  icon: Icons.psychology_outlined,
                ),
                _CategoryCard(
                  title: 'Public Health',
                  subtitle: 'Community health information and prevention',
                  color: Color(0xFFE8F2FF),
                  icon: Icons.public_outlined,
                ),
                _CategoryCard(
                  title: 'Preventive Strategies',
                  subtitle: 'Prevention methods and early detection',
                  color: Color(0xFFE6FFF2),
                  icon: Icons.shield_outlined,
                ),
                _CategoryCard(
                  title: 'Physical Activities',
                  subtitle: 'Exercise guidance and wellness tips',
                  color: Color(0xFFFFF0E5),
                  icon: Icons.favorite_border,
                ),
                _CategoryCard(
                  title: 'Senior Citizens',
                  subtitle: 'Elderly care and aging resources',
                  color: Color(0xFFFFF7E2),
                  icon: Icons.elderly_outlined,
                ),
                _CategoryCard(
                  title: 'Maternal & Infant Health',
                  subtitle: 'Pregnancy care and infant health resources',
                  color: Color(0xFFFFEAF2),
                  icon: Icons.child_friendly_outlined,
                ),
              ];

              if (isWide) {
                return GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: cards,
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
          Container(
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
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        color: AppTheme.deepBlue),
                    const SizedBox(width: 8),
                    Text('Health Education',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search health topics...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: AppTheme.background,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Text(
                    _error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(0xFFE06C75)),
                  )
                else if (_resources.isEmpty)
                  Text('No resources available.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted))
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final cards = _resources
                          .whereType<Map<String, dynamic>>()
                          .map((resource) => _ResourceCard(resource: resource))
                          .toList();

                      if (isWide) {
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.4,
                          children: cards,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.deepBlue),
          ),
          const SizedBox(width: 12),
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

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});

  final Map<String, dynamic> resource;

  @override
  Widget build(BuildContext context) {
    final title = resource['title']?.toString() ?? 'Health Resource';
    final description = resource['description']?.toString() ?? '';
    final downloads =
        (resource['downloadCount'] ?? resource['download_count'])?.toString() ??
            '0';
    final language = resource['language']?.toString() ?? 'en';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.article_outlined,
                color: AppTheme.deepBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppTheme.textPrimary)),
                Text(description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Text('$downloads downloads  -  $language',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('View')),
        ],
      ),
    );
  }
}

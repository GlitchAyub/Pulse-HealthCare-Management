import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/api_mappers.dart';
import '../data/healthreach_api.dart';
import '../models/doctor.dart';
import '../widgets/doctor_card.dart';
import '../widgets/info_banner.dart';
import '../widgets/responsive.dart';
import '../widgets/search_field.dart';
import '../widgets/section_header.dart';

class SpecialistsPage extends StatefulWidget {
  const SpecialistsPage({super.key});

  @override
  State<SpecialistsPage> createState() => _SpecialistsPageState();
}

class _SpecialistsPageState extends State<SpecialistsPage> {
  final _api = HealthReachApi();
  bool _loading = true;
  String? _error;
  List<Doctor> _doctors = const [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final org = await _api.getMyOrganization();
      final orgId = org['id']?.toString();
      if (orgId != null && orgId.isNotEmpty) {
        final users = await _api.getOrganizationUsers(orgId);
        final doctors = users
            .whereType<Map<String, dynamic>>()
            .where(_isMedicalUser)
            .map(doctorFromOrgUser)
            .toList();
        if (!mounted) return;
        setState(() {
          _doctors = doctors;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _doctors = const [];
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

  bool _isMedicalUser(Map<String, dynamic> user) {
    final role = user['role']?.toString() ?? '';
    final orgRole = (user['org_role'] ?? user['orgRole'] ?? '').toString();
    return role.contains('medical') || orgRole.contains('medical');
  }

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Cardiology', 'Neurology', 'Pediatrics'];

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final horizontalPadding = isWide ? 28.0 : 16.0;
          final crossAxisCount = crossAxisCountFor(constraints.maxWidth);

          return RefreshIndicator(
            onRefresh: _loadDoctors,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 16, horizontalPadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Top Specialists',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppTheme.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite_border_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SearchField(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final selected = index == 0;
                        return ChoiceChip(
                          label: Text(filters[index]),
                          selected: selected,
                          onSelected: (_) {},
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: filters.length,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const InfoBanner(
                    title: 'Health Support Anytime',
                    subtitle: 'Connect with our expert medical team instantly.',
                    ctaLabel: 'View All',
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Available Specialists',
                    actionLabel: 'See all',
                  ),
                  const SizedBox(height: 12),
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
                  else if (_doctors.isEmpty)
                    Text(
                      'No specialists available yet.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textMuted),
                    )
                  else
                    GridView.builder(
                      itemCount: _doctors.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                      ),
                      itemBuilder: (context, index) {
                        return DoctorCard(doctor: _doctors[index]);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

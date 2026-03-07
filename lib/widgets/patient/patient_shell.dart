import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../pages/patient/patient_dashboard_page.dart';
import '../../pages/patient/patient_education_page.dart';
import '../../pages/patient/patient_medications_page.dart';
import '../../pages/patient/patient_telehealth_page.dart';
import '../../pages/patient/patient_visits_page.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _selectedIndex = 0;
  int _bottomIndex = 0;
  bool _collapsed = false;
  bool _loggingOut = false;

  late final List<_PatientNavItem> _items = [
    _PatientNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      page: const PatientDashboardPage(),
    ),
    _PatientNavItem(
      label: 'My Visits',
      icon: Icons.assignment_outlined,
      page: const PatientVisitsPage(),
    ),
    _PatientNavItem(
      label: 'Telehealth',
      icon: Icons.videocam_outlined,
      page: const PatientTelehealthPage(),
    ),
    _PatientNavItem(
      label: 'Medications',
      icon: Icons.medical_services_outlined,
      page: const PatientMedicationsPage(),
    ),
    _PatientNavItem(
      label: 'Education',
      icon: Icons.school_outlined,
      page: const PatientEducationPage(),
    ),
  ];

  void _setIndex(int index) {
    setState(() {
      _selectedIndex = index;
      if (index < 4) {
        _bottomIndex = index;
      }
    });
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await AuthScope.of(context).logout();
    if (!mounted) return;
    setState(() => _loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    final displayName =
        _displayName(user?.firstName, user?.lastName, user?.email);
    final truncatedName = _truncateName(displayName);
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: _PatientSidebar(
                  items: _items,
                  selectedIndex: _selectedIndex,
                  collapsed: false,
                  onToggle: null,
                  onSelect: _setIndex,
                  loggingOut: _loggingOut,
                  onLogout: _logout,
                ),
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            _PatientSidebar(
              items: _items,
              selectedIndex: _selectedIndex,
              collapsed: _collapsed,
              onToggle: () => setState(() => _collapsed = !_collapsed),
              onSelect: _setIndex,
              loggingOut: _loggingOut,
              onLogout: _logout,
            ),
          Expanded(
            child: Column(
              children: [
                _PatientTopBar(
                  title: _items[_selectedIndex].label,
                  userName: truncatedName,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _items.map((item) => item.page).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (index) => _setIndex(index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined), label: 'My Visits'),
          NavigationDestination(
              icon: Icon(Icons.videocam_outlined), label: 'Telehealth'),
          NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              label: 'Medications'),
        ],
      ),
    );
  }

  String _displayName(String? first, String? last, String? email) {
    final full = '${first ?? ''} ${last ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    if (email != null && email.isNotEmpty) return email;
    return 'Patient';
  }
}

class _PatientNavItem {
  const _PatientNavItem({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}

class _PatientSidebar extends StatelessWidget {
  const _PatientSidebar({
    required this.items,
    required this.selectedIndex,
    required this.collapsed,
    required this.onToggle,
    required this.onSelect,
    required this.loggingOut,
    required this.onLogout,
  });

  final List<_PatientNavItem> items;
  final int selectedIndex;
  final bool collapsed;
  final VoidCallback? onToggle;
  final ValueChanged<int> onSelect;
  final bool loggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 82.0 : 240.0;
    final user = AuthScope.of(context).user;
    final fullName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final name = _truncateName(fullName.isEmpty ? 'Patient' : fullName);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppTheme.border),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: AppTheme.deepBlue),
                  if (!collapsed) ...[
                    const SizedBox(width: 8),
                    Text('HealthReach',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppTheme.textPrimary)),
                  ],
                  const Spacer(),
                  if (onToggle != null)
                    IconButton(
                      icon: Icon(
                        collapsed
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                      ),
                      onPressed: onToggle,
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return InkWell(
                    onTap: () => onSelect(index),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.skyBlue.withOpacity(0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon,
                              color: selected
                                  ? AppTheme.deepBlue
                                  : AppTheme.textMuted),
                          if (!collapsed) ...[
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: selected
                                        ? AppTheme.deepBlue
                                        : AppTheme.textMuted,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemCount: items.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.softBlue,
                        child: Icon(Icons.person, color: AppTheme.deepBlue),
                      ),
                      if (!collapsed) ...[
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
                              Text('Patient',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loggingOut ? null : onLogout,
                      icon: loggingOut
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: Text(collapsed ? '' : 'Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE06C75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _truncateName(String value) {
  final text = value.trim();
  if (text.length <= 7) return text;
  return '${text.substring(0, 7)}...';
}

class _PatientTopBar extends StatelessWidget {
  const _PatientTopBar({
    required this.title,
    required this.userName,
  });

  final String title;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 1000;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          if (isNarrow)
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.textPrimary),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.softBlue,
                  child: Icon(Icons.person, size: 16, color: AppTheme.deepBlue),
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

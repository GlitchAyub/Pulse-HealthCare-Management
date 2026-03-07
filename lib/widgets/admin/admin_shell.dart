import 'package:flutter/material.dart';
import 'package:pulse/pages/admin/admin_inventory_page.dart';
import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../pages/admin/admin_dashboard_page.dart';
import '../../pages/admin/admin_messages_page.dart';
import '../../pages/admin/admin_organization_page.dart';
import '../../pages/admin/admin_partners_page.dart';
import '../../pages/admin/admin_patients_page.dart';
import '../../pages/admin/admin_telehealth_page.dart';
import '../../pages/admin/admin_visits_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const int _organizationIndex = 5;

  int _selectedIndex = 0;
  int _bottomIndex = 0;
  bool _collapsed = false;
  bool _loggingOut = false;

  late final List<_AdminNavItem> _items = [
    _AdminNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      page: AdminDashboardPage(
        onOpenOrganizationRequested: () => _setIndex(_organizationIndex),
      ),
    ),
    _AdminNavItem(
      label: 'Patients',
      icon: Icons.people_outline,
      page: AdminPatientsPage(),
    ),
    _AdminNavItem(
      label: 'Visits',
      icon: Icons.assignment_outlined,
      page: AdminVisitsPage(),
    ),
    _AdminNavItem(
      label: 'Telehealth',
      icon: Icons.videocam_outlined,
      page: AdminTelehealthPage(),
    ),
    _AdminNavItem(
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
      page: AdminMessagesPage(),
    ),
    _AdminNavItem(
      label: 'Organization',
      icon: Icons.settings_outlined,
      page: AdminOrganizationPage(),
    ),
    _AdminNavItem(
      label: 'Partners',
      icon: Icons.shield_outlined,
      page: AdminPartnersPage(),
    ),
    _AdminNavItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      page: AdminInventoryPage(),
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
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: _AdminSidebar(
                  items: _items,
                  selectedIndex: _selectedIndex,
                  collapsed: false,
                  onToggle: null,
                  loggingOut: _loggingOut,
                  onLogout: _logout,
                  onSelect: (index) {
                    Navigator.of(context).pop();
                    if (_selectedIndex == index) return;
                    Future<void>.delayed(Duration.zero, () {
                      if (!mounted) return;
                      _setIndex(index);
                    });
                  },
                ),
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            _AdminSidebar(
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
                _AdminTopBar(
                  title: _items[_selectedIndex].label,
                  userName: displayName,
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
              icon: Icon(Icons.people_outline), label: 'Patients'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined), label: 'Visits'),
          NavigationDestination(
              icon: Icon(Icons.videocam_outlined), label: 'Telehealth'),
        ],
      ),
    );
  }

  String _displayName(String? first, String? last, String? email) {
    final full = '${first ?? ''} ${last ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    if (email != null && email.isNotEmpty) return email;
    return 'Admin';
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.items,
    required this.selectedIndex,
    required this.collapsed,
    required this.onToggle,
    required this.onSelect,
    required this.loggingOut,
    required this.onLogout,
  });

  final List<_AdminNavItem> items;
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
    final name = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

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
                                name.isEmpty ? 'Admin' : name,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: AppTheme.textPrimary),
                              ),
                              Text('Admin',
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

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
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

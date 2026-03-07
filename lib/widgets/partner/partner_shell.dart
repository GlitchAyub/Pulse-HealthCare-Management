import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/auth_scope.dart';
import '../../data/healthreach_api.dart';
import '../../pages/partner/partner_dashboard_page.dart';
import '../../pages/partner/partner_inventory_page.dart';
import '../../pages/partner/partner_resources_page.dart';

class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  final _api = HealthReachApi();

  int _selectedIndex = 0;
  int _bottomIndex = 0;
  bool _collapsed = false;
  int _pendingInvitationCount = 0;
  bool _loggingOut = false;

  late final List<_PartnerNavItem> _items = [
    _PartnerNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      page: const PartnerDashboardPage(),
    ),
    _PartnerNavItem(
      label: 'Resources',
      icon: Icons.menu_book_outlined,
      page: const PartnerResourcesPage(),
    ),
    _PartnerNavItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      page: const PartnerInventoryPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingInvitationCount();
  }

  void _setIndex(int index) {
    setState(() {
      _selectedIndex = index;
      if (index < 3) {
        _bottomIndex = index;
      }
    });
    _loadPendingInvitationCount();
  }

  Future<void> _loadPendingInvitationCount() async {
    try {
      final pendingInvitations = await _api.getMyPendingInvitations();
      if (!mounted) return;
      setState(() {
        _pendingInvitationCount = pendingInvitations.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingInvitationCount = 0;
      });
    }
  }

  void _handleNotificationTap() {
    _setIndex(0);
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
                child: _PartnerSidebar(
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
            _PartnerSidebar(
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
                _PartnerTopBar(
                  title: _items[_selectedIndex].label,
                  userName: truncatedName,
                  pendingInvitationCount: _pendingInvitationCount,
                  onNotificationsPressed: _handleNotificationTap,
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
              icon: Icon(Icons.menu_book_outlined), label: 'Resources'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
        ],
      ),
    );
  }

  String _displayName(String? first, String? last, String? email) {
    final full = '${first ?? ''} ${last ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    if (email != null && email.isNotEmpty) return email;
    return 'Partner';
  }
}

class _PartnerNavItem {
  const _PartnerNavItem({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}

class _PartnerSidebar extends StatelessWidget {
  const _PartnerSidebar({
    required this.items,
    required this.selectedIndex,
    required this.collapsed,
    required this.onToggle,
    required this.onSelect,
    required this.loggingOut,
    required this.onLogout,
  });

  final List<_PartnerNavItem> items;
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
    final name = _truncateName(fullName.isEmpty ? 'Partner' : fullName);

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
                            ? AppTheme.skyBlue.withValues(alpha: 0.16)
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
                              Text('Partner',
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

class _PartnerTopBar extends StatelessWidget {
  const _PartnerTopBar({
    required this.title,
    required this.userName,
    required this.pendingInvitationCount,
    required this.onNotificationsPressed,
  });

  final String title;
  final String userName;
  final int pendingInvitationCount;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 1000;
    final compactProfile = MediaQuery.of(context).size.width < 560;
    final horizontalPadding = compactProfile ? 12.0 : 20.0;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onNotificationsPressed,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (pendingInvitationCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE06C75),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        pendingInvitationCount > 99
                            ? '99+'
                            : '$pendingInvitationCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: compactProfile ? 4 : 12),
          Container(
            constraints:
                compactProfile ? null : const BoxConstraints(maxWidth: 132),
            padding: EdgeInsets.symmetric(
              horizontal: compactProfile ? 8 : 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.softBlue,
                  child: Icon(Icons.person, size: 16, color: AppTheme.deepBlue),
                ),
                if (!compactProfile) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _truncateName(String value) {
  final text = value.trim();
  if (text.length <= 7) return text;
  return '${text.substring(0, 7)}...';
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.tabletMaxWidth) {
          return _DesktopShell(child: child);
        }
        if (constraints.maxWidth >= AppDimensions.mobileMaxWidth) {
          return _TabletShell(child: child);
        }
        return _MobileShell(child: child);
      },
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _navigate(context, i),
        destinations: _destinations,
      ),
    );
  }
}

// ── Tablet ────────────────────────────────────────────────────────────────────

class _TabletShell extends StatelessWidget {
  final Widget child;
  const _TabletShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => _navigate(context, i),
            labelType: NavigationRailLabelType.selected,
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          _Sidebar(
              selectedIndex: selectedIndex,
              onTap: (i) => _navigate(context, i)),
          // Divider
          Container(width: 1, color: AppColors.grey200),
          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: ClipRect(child: child),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _Sidebar({required this.selectedIndex, required this.onTap});

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Inicio'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Transacciones'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Reportes'),
    _NavItem(Icons.savings_outlined, Icons.savings, 'Metas'),
    _NavItem(Icons.handshake_outlined, Icons.handshake, 'Deudas'),
    _NavItem(Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/LogoFintrack.png',
                  width: 36,
                  height: 36,
                ),
                const SizedBox(width: 10),
                const Text(
                  'FinTrack',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.grey100),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'MENÚ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey400,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Nav items
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final isSelected = selectedIndex == i;
            return _SidebarItem(
              icon: isSelected ? item.activeIcon : item.icon,
              label: item.label,
              isSelected: isSelected,
              onTap: () => onTap(i),
            );
          }),

          const Spacer(),

          // Version
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'FinTrack v1.0',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey300, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.grey500,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.grey600,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ── Shared helpers ────────────────────────────────────────────────────────────

const _navRoutes = ['/', '/transactions', '/reports', '/goals', '/debts', '/profile'];

int _indexFromLocation(String location) {
  for (int i = 0; i < _navRoutes.length; i++) {
    if (location == _navRoutes[i] ||
        location.startsWith('${_navRoutes[i]}/')) {
      return i;
    }
  }
  return 0;
}

void _navigate(BuildContext context, int index) {
  context.go(_navRoutes[index]);
}

const _destinations = [
  NavigationDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    label: 'Inicio',
  ),
  NavigationDestination(
    icon: Icon(Icons.receipt_long_outlined),
    selectedIcon: Icon(Icons.receipt_long),
    label: 'Transacciones',
  ),
  NavigationDestination(
    icon: Icon(Icons.bar_chart_outlined),
    selectedIcon: Icon(Icons.bar_chart),
    label: 'Reportes',
  ),
  NavigationDestination(
    icon: Icon(Icons.savings_outlined),
    selectedIcon: Icon(Icons.savings),
    label: 'Metas',
  ),
  NavigationDestination(
    icon: Icon(Icons.handshake_outlined),
    selectedIcon: Icon(Icons.handshake),
    label: 'Deudas',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline),
    selectedIcon: Icon(Icons.person),
    label: 'Perfil',
  ),
];

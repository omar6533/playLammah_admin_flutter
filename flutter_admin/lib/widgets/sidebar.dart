import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Sidebar extends StatelessWidget {
  final String currentPage;
  final Function(String) onPageChange;

  const Sidebar({
    required this.currentPage,
    required this.onPageChange,
    super.key,
  });

  static const _items = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard', page: 'dashboard'),
    (icon: Icons.people_rounded, label: 'Users', page: 'users'),
    (icon: Icons.gamepad_rounded, label: 'Games', page: 'games'),
    (icon: Icons.category_rounded, label: 'Categories', page: 'categories'),
    (icon: Icons.quiz_rounded, label: 'Questions', page: 'questions'),
    (icon: Icons.payment_rounded, label: 'Payments', page: 'payments'),
    (icon: Icons.settings_rounded, label: 'Settings', page: 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // ── Logo area ──────────────────────────────────────────────────────
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          //   child: Column(
          //     children: [
          //       Image.asset(
          //         'assets/images/logo_full.png',
          //         height: 44,
          //         fit: BoxFit.contain,
          //         errorBuilder: (_, __, ___) => const Text(
          //           'PlayLammah',
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontSize: 20,
          //             fontWeight: FontWeight.w800,
          //           ),
          //         ),
          //       ),
          //       const SizedBox(height: 6),
          //       Container(
          //         padding:
          //             const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          //         decoration: BoxDecoration(
          //           color: Colors.white.withValues(alpha: 0.12),
          //           borderRadius: BorderRadius.circular(20),
          //         ),
          //         child: const Text(
          //           'Admin Panel',
          //           style: TextStyle(
          //             color: Colors.white70,
          //             fontSize: 11,
          //             fontWeight: FontWeight.w500,
          //             letterSpacing: 0.5,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          Divider(
            color: AppColors.sidebarDivider,
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 8),
          // ── Nav items ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: _items
                  .map((item) => _NavItem(
                        icon: item.icon,
                        label: item.label,
                        page: item.page,
                        isActive: currentPage == item.page,
                        onTap: () => onPageChange(item.page),
                      ))
                  .toList(),
            ),
          ),
          // ── Footer ─────────────────────────────────────────────────────────
          Divider(color: AppColors.sidebarDivider, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white70, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String page;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive ? AppColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.sidebarHover,
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.white60,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
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

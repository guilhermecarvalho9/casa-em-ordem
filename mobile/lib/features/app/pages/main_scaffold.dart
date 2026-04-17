import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../app/providers/app_provider.dart';
import '../../dashboard/pages/dashboard_page.dart';
import '../../members/pages/members_page.dart';
import '../../tasks/pages/tasks_page.dart';
import '../../bills/pages/bills_page.dart';
import '../../shopping/pages/shopping_page.dart';
import '../../passwords/pages/passwords_page.dart';
import '../../damaged/pages/damaged_page.dart';
import '../../events/pages/events_page.dart';
import '../../rules/pages/rules_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../address/pages/address_page.dart';
import '../../settings/pages/settings_page.dart';
import '../../qrcode/pages/qrcode_page.dart';
import '../../inventory/pages/inventory_page.dart';
import '../../nf/pages/nf_page.dart';
import '../../../shared/widgets/ad_banner.dart';

final currentPageProvider = StateProvider<String>((ref) => 'dashboard');

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final appState = ref.watch(appProvider);
    final t = (String key) => AppTranslations.translate(appState.language, key);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
        title: Text(
          t('nav.$currentPage'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.foregroundDark : AppColors.foreground,
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          _buildThemeToggle(ref, isDark),
          _buildLanguageToggle(ref, appState.language, isDark),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      drawer: _AppDrawer(currentPage: currentPage),
      body: _buildPage(currentPage),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }

  Widget _buildPage(String page) {
    switch (page) {
      case 'dashboard': return const DashboardPage();
      case 'profile': return const ProfilePage();
      case 'address': return const AddressPage();
      case 'members': return const MembersPage();
      case 'tasks': return const TasksPage();
      case 'events': return const EventsPage();
      case 'rules': return const RulesPage();
      case 'bills': return const BillsPage();
      case 'shopping': return const ShoppingPage();
      case 'passwords': return const PasswordsPage();
      case 'damaged': return const DamagedPage();
      case 'qrcode': return const QRCodePage();
      case 'inventory': return const InventoryPage();
      case 'nf': return const NfPage();
      case 'settings': return const SettingsPage();
      default: return const DashboardPage();
    }
  }

  Widget _buildThemeToggle(WidgetRef ref, bool isDark) {
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
        size: 22,
      ),
      onPressed: () => ref.read(appProvider.notifier).setDarkMode(!isDark),
    );
  }

  Widget _buildLanguageToggle(WidgetRef ref, String lang, bool isDark) {
    return GestureDetector(
      onTap: () => ref.read(appProvider.notifier).setLanguage(lang == 'pt' ? 'en' : 'pt'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.secondaryDark : AppColors.secondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Text(
          lang.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.foregroundDark : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  final String currentPage;
  const _AppDrawer({required this.currentPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final t = (String key) => AppTranslations.translate(appState.language, key);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      _NavItem('dashboard', Icons.dashboard_rounded, t('nav.dashboard')),
      _NavItem('profile', Icons.person_rounded, t('nav.profile')),
      _NavItem('address', Icons.location_on_rounded, t('nav.address')),
      _NavItem('members', Icons.people_rounded, t('nav.members')),
      _NavItem('tasks', Icons.check_circle_rounded, t('nav.tasks')),
      _NavItem('events', Icons.event_rounded, t('nav.events')),
      _NavItem('rules', Icons.gavel_rounded, t('nav.rules')),
      _NavItem('bills', Icons.receipt_long_rounded, t('nav.bills')),
      _NavItem('shopping', Icons.shopping_cart_rounded, t('nav.shopping')),
      _NavItem('passwords', Icons.lock_rounded, t('nav.passwords')),
      _NavItem('damaged', Icons.warning_rounded, t('nav.damaged')),
      _NavItem('inventory', Icons.inventory_2_rounded, t('nav.inventory')),
      _NavItem('qrcode', Icons.qr_code_rounded, t('nav.qrcode')),
      _NavItem('nf', Icons.receipt_long_rounded, t('nav.nf')),
    ];

    return Drawer(
      backgroundColor: isDark ? AppColors.sidebarBgDark : AppColors.sidebarBg,
      width: 280,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.sidebarBgDark : AppColors.sidebarBg,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo-homio-fundo-transparente.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('app.title'),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                        ),
                      ),
                      if (authState.currentHouse != null)
                        Text(
                          authState.currentHouse!.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: navItems.map((item) {
                final isActive = currentPage == item.key;
                return _DrawerNavItem(
                  item: item,
                  isActive: isActive,
                  isDark: isDark,
                  onTap: () {
                    ref.read(currentPageProvider.notifier).state = item.key;
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),

          // Bottom section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
            ),
            child: Column(
              children: [
                _DrawerNavItem(
                  item: _NavItem('settings', Icons.settings_rounded, t('nav.settings')),
                  isActive: currentPage == 'settings',
                  isDark: isDark,
                  onTap: () {
                    ref.read(currentPageProvider.notifier).state = 'settings';
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 4),
                // User info + logout
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: _UserAvatar(
                    name: authState.profile?.name ?? '',
                    color: authState.profile?.color ?? '#2A9D90',
                  ),
                  title: Text(
                    authState.profile?.name ?? '',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    authState.user?.email ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForeground,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).signOut();
                    },
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          size: 20,
          color: isActive
              ? Colors.white
              : (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
        ),
        title: Text(
          item.label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.foregroundDark : AppColors.foreground),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String color;

  const _UserAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    Color avatarColor;
    try {
      avatarColor = Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (_) {
      avatarColor = AppColors.primary;
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: avatarColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _NavItem {
  final String key;
  final IconData icon;
  final String label;

  const _NavItem(this.key, this.icon, this.label);
}

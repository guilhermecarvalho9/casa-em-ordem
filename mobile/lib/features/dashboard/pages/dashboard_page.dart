import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../bills/providers/bills_provider.dart';
import '../../shopping/providers/shopping_provider.dart';
import '../../app/pages/main_scaffold.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final t = (String key) => AppTranslations.translate(appState.language, key);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final members = ref.watch(membersProvider);
    final tasks = ref.watch(tasksProvider);
    final bills = ref.watch(billsProvider);
    final shopping = ref.watch(shoppingProvider);

    final pendingTasks = tasks.valueOrNull?.where((t) => !t.completed).length ?? 0;
    final pendingBills = bills.valueOrNull?.where((b) => !b.paid).length ?? 0;
    final shoppingToBuy = shopping.valueOrNull?.where((s) => !s.bought).length ?? 0;
    final membersCount = members.valueOrNull?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF3BB5A8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t('dashboard.welcome')},',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.profile?.name ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.currentHouse?.name ?? '',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            t('dashboard.summary'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.foregroundDark : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              _StatCard(
                title: t('dashboard.tasks'),
                value: pendingTasks.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.primary,
                isDark: isDark,
                onTap: () => ref.read(currentPageProvider.notifier).state = 'tasks',
              ),
              _StatCard(
                title: t('dashboard.bills'),
                value: pendingBills.toString(),
                icon: Icons.receipt_long_rounded,
                color: AppColors.accent,
                isDark: isDark,
                onTap: () => ref.read(currentPageProvider.notifier).state = 'bills',
              ),
              _StatCard(
                title: t('dashboard.shopping'),
                value: shoppingToBuy.toString(),
                icon: Icons.shopping_cart_rounded,
                color: AppColors.success,
                isDark: isDark,
                onTap: () => ref.read(currentPageProvider.notifier).state = 'shopping',
              ),
              _StatCard(
                title: t('dashboard.members'),
                value: membersCount.toString(),
                icon: Icons.people_rounded,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () => ref.read(currentPageProvider.notifier).state = 'members',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent tasks
          if (tasks.valueOrNull?.isNotEmpty == true) ...[
            _SectionHeader(
              title: t('dashboard.recentTasks'),
              seeAllLabel: t('common.seeAll'),
              onSeeAll: () => ref.read(currentPageProvider.notifier).state = 'tasks',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ...tasks.valueOrNull!
                .where((t) => !t.completed)
                .take(3)
                .map((task) => _TaskPreviewCard(task: task, isDark: isDark)),
            const SizedBox(height: 20),
          ],

          // Recent bills
          if (bills.valueOrNull?.isNotEmpty == true) ...[
            _SectionHeader(
              title: t('dashboard.pendingBills'),
              seeAllLabel: t('common.seeAll'),
              onSeeAll: () => ref.read(currentPageProvider.notifier).state = 'bills',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ...bills.valueOrNull!
                .where((b) => !b.paid)
                .take(3)
                .map((bill) => _BillPreviewCard(bill: bill, isDark: isDark)),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String seeAllLabel;
  final VoidCallback? onSeeAll;
  final bool isDark;

  const _SectionHeader({required this.title, this.seeAllLabel = 'Ver todos', this.onSeeAll, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.foregroundDark : AppColors.foreground,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              seeAllLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskPreviewCard extends StatelessWidget {
  final dynamic task;
  final bool isDark;

  const _TaskPreviewCard({required this.task, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title as String,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (task.dueDate != null)
            Text(
              task.dueTime != null
                  ? '${_formatDate(task.dueDate as String)} ${task.dueTime}'
                  : _formatDate(task.dueDate as String),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}';
    } catch (_) {
      return date;
    }
  }
}

class _BillPreviewCard extends StatelessWidget {
  final dynamic bill;
  final bool isDark;

  const _BillPreviewCard({required this.bill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bill.title as String,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'R\$ ${(bill.amount as double).toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

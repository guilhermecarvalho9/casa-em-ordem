import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/house_notification.dart';
import '../../../shared/providers/notifications_provider.dart';
import '../../../shared/services/house_notification_service.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsPage(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final uid = auth.user?.uid ?? '';
    final houseId = auth.currentHouse?.id ?? '';
    final notifsAsync = ref.watch(notificationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Notificações',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                    ),
                  ),
                  const Spacer(),
                  if ((notifsAsync.valueOrNull?.isNotEmpty ?? false))
                    TextButton(
                      onPressed: () {
                        for (final n in notifsAsync.valueOrNull ?? []) {
                          HouseNotificationService.markSeen(houseId, n.id, uid);
                        }
                      },
                      child: Text(
                        'Marcar todas como lidas',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notifsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (notifs) => notifs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 48,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForeground),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhuma notificação nova',
                              style: GoogleFonts.inter(
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 72,
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                        itemBuilder: (_, i) => _NotifTile(
                          notif: notifs[i],
                          isDark: isDark,
                          onTap: () => HouseNotificationService.markSeen(
                              houseId, notifs[i].id, uid),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final HouseNotification notif;
  final bool isDark;
  final VoidCallback onTap;

  const _NotifTile({
    required this.notif,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon {
    switch (notif.type) {
      case 'event_added': return Icons.event_rounded;
      case 'bill_added': return Icons.receipt_long_rounded;
      case 'bill_split': return Icons.call_split_rounded;
      case 'shopping_added': return Icons.shopping_cart_rounded;
      case 'inventory_added': return Icons.inventory_2_rounded;
      case 'task_done': return Icons.check_circle_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color get _color {
    switch (notif.type) {
      case 'event_added': return Colors.purple;
      case 'bill_added': return Colors.orange;
      case 'bill_split': return Colors.red;
      case 'shopping_added': return Colors.green;
      case 'inventory_added': return Colors.blue;
      case 'task_done': return AppColors.primary;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd/MM HH:mm').format(notif.createdAt);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_icon, color: _color, size: 20),
      ),
      title: Text(
        notif.title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.foregroundDark : AppColors.foreground,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notif.body,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeStr,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

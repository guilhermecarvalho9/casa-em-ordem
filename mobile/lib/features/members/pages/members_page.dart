import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/member_avatar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final membersAsync = ref.watch(membersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);
    final isAdmin = authState.houseMembership?.isAdmin == true;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (members) => members.isEmpty
            ? EmptyState(
                icon: Icons.people_outline_rounded,
                message: t('members.noMembers'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final isCurrentUser = members[i].userId == authState.user?.uid;
                  final canManage = isAdmin && !isCurrentUser;
                  return _MemberCard(
                    member: members[i],
                    isDark: isDark,
                    isCurrentUser: isCurrentUser,
                    t: t,
                    onDelete: canManage
                        ? () => _confirmDelete(context, ref, members[i], t)
                        : null,
                    onChangeRole: canManage
                        ? () => _showChangeRole(context, ref, members[i], t, isDark)
                        : null,
                    onSetExpiry: canManage
                        ? () => _showSetExpiry(context, ref, members[i], t, isDark)
                        : null,
                  );
                },
              ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showInviteCode(context, authState.currentHouse?.inviteCode ?? '', isDark, t),
              child: const Icon(Icons.share_rounded),
            )
          : null,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, MemberModel member, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.confirm')),
        content: Text('${t('members.removeConfirm')} ${member.name}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(membersProvider.notifier).removeMember(member.id);
            },
            child: Text(t('common.delete'), style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showChangeRole(BuildContext context, WidgetRef ref, MemberModel member,
      String Function(String) t, bool isDark) {
    const roles = ['admin', 'owner', 'member', 'guest'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('members.changeRole'),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) {
            final isSelected = member.role == role;
            return ListTile(
              title: Text(t('members.role.$role'), style: GoogleFonts.inter(fontSize: 14)),
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.mutedForeground,
                size: 20,
              ),
              dense: true,
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(membersProvider.notifier).updateRole(member.id, role);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
        ],
      ),
    );
  }

  Future<void> _showSetExpiry(BuildContext context, WidgetRef ref, MemberModel member,
      String Function(String) t, bool isDark) async {
    DateTime initial = DateTime.now().add(const Duration(days: 7));
    if (member.expiresAt != null) {
      try {
        initial = DateTime.parse(member.expiresAt!);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: t('members.setExpiry'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    final dateStr = picked.toIso8601String().split('T').first;
    await ref.read(membersProvider.notifier).setExpiry(member.id, dateStr);
  }

  void _showInviteCode(BuildContext context, String code, bool isDark, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('members.inviteTitle'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t('members.inviteShare'), style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                code,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.close'))),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final bool isDark;
  final bool isCurrentUser;
  final String Function(String) t;
  final VoidCallback? onDelete;
  final VoidCallback? onChangeRole;
  final VoidCallback? onSetExpiry;

  const _MemberCard({
    required this.member,
    required this.isDark,
    required this.isCurrentUser,
    required this.t,
    this.onDelete,
    this.onChangeRole,
    this.onSetExpiry,
  });

  BadgeType _badgeType(String role) {
    switch (role) {
      case 'admin': return BadgeType.success;
      case 'owner': return BadgeType.warning;
      case 'guest': return BadgeType.muted;
      default: return BadgeType.info;
    }
  }

  bool get _isExpired {
    if (member.expiresAt == null) return false;
    try {
      final d = DateTime.parse(member.expiresAt!);
      return DateTime.now().isAfter(DateTime(d.year, d.month, d.day, 23, 59, 59));
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '-';
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = _isExpired;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expired
              ? AppColors.destructive.withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : AppColors.border),
        ),
      ),
      child: Row(
        children: [
          MemberAvatar(name: member.name, color: member.color, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      StatusBadge(label: t('members.you'), type: BadgeType.info),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(
                      label: t('members.role.${member.role}'),
                      type: _badgeType(member.role),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${t('members.entry')}: ${_formatDate(member.entryDate)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                if (member.expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: expired ? AppColors.destructive : AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${expired ? t('members.expired') : t('members.expiresOn')}: ${_formatDate(member.expiresAt!)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: expired ? AppColors.destructive : AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onChangeRole != null)
            IconButton(
              icon: Icon(Icons.manage_accounts_outlined,
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground, size: 20),
              onPressed: onChangeRole,
              visualDensity: VisualDensity.compact,
            ),
          if (onSetExpiry != null)
            IconButton(
              icon: Icon(
                member.expiresAt != null ? Icons.event_busy_rounded : Icons.event_available_rounded,
                color: member.expiresAt != null
                    ? (expired ? AppColors.destructive : AppColors.accent)
                    : (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                size: 20,
              ),
              onPressed: onSetExpiry,
              visualDensity: VisualDensity.compact,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.destructive, size: 20),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

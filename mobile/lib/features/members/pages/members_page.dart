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
import '../../pro/providers/pro_provider.dart';
import '../../pro/pages/pro_paywall_page.dart';
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
    final isPro = ref.watch(proProvider).valueOrNull ?? false;

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
                    onTap: () => _showMemberProfile(context, ref, members[i], isAdmin, isCurrentUser, t, isDark),
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
              onPressed: () {
                final memberCount = membersAsync.valueOrNull?.length ?? 0;
                if (!isPro && memberCount >= 3) {
                  _showProGate(context, t, isDark);
                } else {
                  _showInviteCode(context, authState.currentHouse?.inviteCode ?? '', isDark, t);
                }
              },
              child: const Icon(Icons.share_rounded),
            )
          : null,
    );
  }

  void _showMemberProfile(
    BuildContext context,
    WidgetRef ref,
    MemberModel member,
    bool isAdmin,
    bool isCurrentUser,
    String Function(String) t,
    bool isDark,
  ) {
    final phoneCtrl = TextEditingController(text: member.phone ?? '');
    final emergencyContactCtrl = TextEditingController(text: member.emergencyContact ?? '');
    final emergencyPhoneCtrl = TextEditingController(text: member.emergencyPhone ?? '');
    bool editingContact = false;

    String formatDate(String date) {
      if (date.isEmpty) return '-';
      try {
        final d = DateTime.parse(date);
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      } catch (_) {
        return date;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState2) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(child: MemberAvatar(name: member.name, color: member.color, radius: 36)),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  member.name,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 20,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: StatusBadge(
                  label: t('members.role.${member.role}'),
                  type: member.isAdmin ? BadgeType.success : BadgeType.info,
                ),
              ),
              const SizedBox(height: 20),
              // Info rows
              _ProfileInfoRow(
                icon: Icons.calendar_today_outlined,
                label: t('members.entry'),
                value: formatDate(member.entryDate),
                isDark: isDark,
              ),
              if (member.expiresAt != null)
                _ProfileInfoRow(
                  icon: Icons.timer_outlined,
                  label: t('members.expiresOn'),
                  value: formatDate(member.expiresAt!),
                  isDark: isDark,
                  valueColor: AppColors.destructive,
                ),
              const Divider(height: 24),
              // Contact info section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t('members.contact'),
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                  if (isAdmin || isCurrentUser)
                    TextButton(
                      onPressed: () async {
                        if (editingContact) {
                          await ref.read(membersProvider.notifier).updateMemberContact(
                            member.id,
                            phone: phoneCtrl.text.trim(),
                            emergencyContact: emergencyContactCtrl.text.trim(),
                            emergencyPhone: emergencyPhoneCtrl.text.trim(),
                          );
                          setState2(() => editingContact = false);
                        } else {
                          setState2(() => editingContact = true);
                        }
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: Text(editingContact ? t('common.save') : t('common.edit'),
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (editingContact) ...[
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: t('members.phone'),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emergencyContactCtrl,
                  decoration: InputDecoration(
                    labelText: t('members.emergencyContact'),
                    prefixIcon: const Icon(Icons.person_pin_outlined, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emergencyPhoneCtrl,
                  decoration: InputDecoration(
                    labelText: t('members.emergencyPhone'),
                    prefixIcon: const Icon(Icons.emergency_outlined, size: 18),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ] else ...[
                _ProfileInfoRow(
                  icon: Icons.phone_outlined,
                  label: t('members.phone'),
                  value: member.phone ?? '-',
                  isDark: isDark,
                ),
                _ProfileInfoRow(
                  icon: Icons.person_pin_outlined,
                  label: t('members.emergencyContact'),
                  value: member.emergencyContact ?? '-',
                  isDark: isDark,
                ),
                _ProfileInfoRow(
                  icon: Icons.emergency_outlined,
                  label: t('members.emergencyPhone'),
                  value: member.emergencyPhone ?? '-',
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ),
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

  void _showProGate(BuildContext context, String Function(String) t, bool isDark) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProPaywallPage()),
    );
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
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onChangeRole;
  final VoidCallback? onSetExpiry;

  const _MemberCard({
    required this.member,
    required this.isDark,
    required this.isCurrentUser,
    required this.t,
    this.onTap,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
    ));
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16,
              color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: valueColor ?? (isDark ? AppColors.foregroundDark : AppColors.foreground))),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/member_avatar.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameCtrl;
  bool _editing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _nameCtrl = TextEditingController(text: profile?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final profile = authState.profile;
    final house = authState.currentHouse;
    final membership = authState.houseMembership;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                children: [
                  profile != null
                      ? MemberAvatar(name: profile.name, color: profile.color, radius: 40)
                      : CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                        ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.name ?? '',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 20,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authState.user?.email ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                  ),
                  if (membership != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: membership.isAdmin
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        membership.isAdmin ? t('members.admin') : t('members.member'),
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: membership.isAdmin ? AppColors.primary : (isDark ? AppColors.foregroundDark : AppColors.foreground)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Edit name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('profile.info'),
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600, fontSize: 15,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                      TextButton(
                        onPressed: _editing
                            ? () async {
                                setState(() => _loading = true);
                                await ref.read(authProvider.notifier).updateProfile(
                                  name: _nameCtrl.text.trim(),
                                );
                                setState(() { _loading = false; _editing = false; });
                              }
                            : () => setState(() => _editing = true),
                        child: Text(_editing ? t('common.save') : t('common.edit'),
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_editing)
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(labelText: t('profile.name')),
                    )
                  else
                    _InfoRow(
                      label: t('profile.name'),
                      value: profile?.name ?? '-',
                      isDark: isDark,
                    ),
                  if (_loading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // House info
            if (house != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('profile.house'),
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600, fontSize: 15,
                            color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                    const SizedBox(height: 12),
                    _InfoRow(label: t('common.name'), value: house.name, isDark: isDark),
                    if (house.address != null) ...[
                      const Divider(height: 20),
                      _InfoRow(label: t('address.title'), value: house.address!, isDark: isDark),
                    ],
                    const Divider(height: 20),
                    _InfoRow(label: t('members.inviteCode'), value: house.inviteCode, isDark: isDark),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
        ),
      ],
    );
  }
}

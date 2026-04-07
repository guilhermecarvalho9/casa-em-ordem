import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance
          _SectionTitle(title: t('settings.appearance'), isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                label: t('settings.darkMode'),
                value: appState.darkMode,
                isDark: isDark,
                onChanged: (v) => ref.read(appProvider.notifier).setDarkMode(v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Language
          _SectionTitle(title: t('settings.language'), isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              _RadioTile(
                icon: Icons.language_outlined,
                label: 'Português (BR)',
                value: 'pt',
                groupValue: appState.language,
                isDark: isDark,
                onChanged: (v) => ref.read(appProvider.notifier).setLanguage(v!),
              ),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
              _RadioTile(
                icon: Icons.language_outlined,
                label: 'English',
                value: 'en',
                groupValue: appState.language,
                isDark: isDark,
                onChanged: (v) => ref.read(appProvider.notifier).setLanguage(v!),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // House invite code
          if (authState.currentHouse != null) ...[
            _SectionTitle(title: t('settings.inviteCode'), isDark: isDark),
            const SizedBox(height: 8),
            _SettingsCard(
              isDark: isDark,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.key_rounded, color: AppColors.accent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authState.currentHouse!.inviteCode,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 20,
                              letterSpacing: 3,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: authState.currentHouse!.inviteCode,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('settings.codeCopied')),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Account
          _SectionTitle(title: t('settings.account'), isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.destructive, size: 18),
                ),
                title: Text(t('auth.logout'),
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: AppColors.destructive)),
                onTap: () => _confirmLogout(context, ref, t),
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('auth.logout')),
        content: Text(t('auth.logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            child: Text(t('auth.logout'),
                style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600, fontSize: 13,
            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground));
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      dense: true,
    );
  }
}

class _RadioTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String groupValue;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _RadioTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      secondary: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      dense: true,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../permissions/pages/permissions_page.dart';
import '../../pro/providers/pro_provider.dart';
import '../../pro/pages/pro_paywall_page.dart';

const _androidPackageId = 'br.com.hg2tecnologia.homio';
const _iosAppStoreId = '6775571787';

const _appVersion = '1.0.0';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final isPro = ref.watch(proProvider).valueOrNull ?? false;
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
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
              _SwitchTile(
                icon: Icons.notifications_outlined,
                label: t('settings.notifications'),
                value: appState.notifications,
                isDark: isDark,
                onChanged: (v) => ref.read(appProvider.notifier).setNotifications(v),
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

          // Join another house
          _SectionTitle(title: 'Entrar em outra casa', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home_work_outlined, color: AppColors.primary, size: 18),
                ),
                title: Text('Entrar em outra casa',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                subtitle: Text('Use um código de convite',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                dense: true,
                onTap: () => _showJoinHouseDialog(context, ref, t, isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Permissions (admin only)
          if (authState.houseMembership?.isAdmin == true) ...[
            _SectionTitle(title: t('settings.management'), isDark: isDark),
            const SizedBox(height: 8),
            _SettingsCard(
              isDark: isDark,
              children: [
                ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_person_outlined, color: AppColors.primary, size: 18),
                  ),
                  title: Text(t('permissions.title'),
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                  subtitle: Text(t('permissions.subtitle'),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  dense: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PermissionsPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Subscription
          _SectionTitle(title: 'Assinatura', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFFFFB800), size: 18),
                ),
                title: Text(
                  isPro ? 'Homio PRO ativo' : 'Plano Free',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPro
                        ? const Color(0xFFFFB800)
                        : (isDark ? AppColors.foregroundDark : AppColors.foreground),
                  ),
                ),
                subtitle: Text(
                  isPro
                      ? 'Sem anúncios • Membros ilimitados'
                      : 'Máx. 2 membros • Com anúncios',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                  ),
                ),
                trailing: isPro
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PRO',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFB800),
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_right_rounded, size: 18),
                dense: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProPaywallPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rate app
          _SectionTitle(title: 'Apoie o Homio', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                ),
                title: Text('Avaliar o Homio',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                subtitle: Text('Conte o que achou do app',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                dense: true,
                onTap: () => _showRatingDialog(context, t, isDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: AppColors.destructive, size: 18),
                ),
                title: Text(t('settings.deleteAccount'),
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: AppColors.destructive)),
                onTap: () => _confirmDeleteAccount(context, ref, t),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // App version footer
          Center(
            child: Text(
              'Homio v$_appVersion',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String Function(String) t, bool isDark) {
    int selectedStars = 0;
    bool submitted = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState2) {
          if (submitted) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    selectedStars >= 4
                        ? 'Obrigado! 🎉\nRedirecionando para a loja...'
                        : 'Obrigado pelo feedback!\nVamos continuar melhorando.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: Text('Avaliar o Homio',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Como você avalia o Homio?',
                    style: GoogleFonts.inter(fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState2(() => selectedStars = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                if (selectedStars > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    selectedStars >= 4 ? 'Que ótimo! 😊' : 'Obrigado pelo seu feedback!',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t('common.cancel')),
              ),
              if (selectedStars > 0)
                TextButton(
                  onPressed: () async {
                    setState2(() => submitted = true);
                    if (selectedStars >= 4) {
                      await Future.delayed(const Duration(milliseconds: 800));
                      if (ctx.mounted) Navigator.pop(ctx);
                      final Uri storeUri;
                      if (defaultTargetPlatform == TargetPlatform.iOS && _iosAppStoreId.isNotEmpty) {
                        storeUri = Uri.parse('itms-apps://itunes.apple.com/app/id$_iosAppStoreId?action=write-review');
                      } else {
                        storeUri = Uri.parse('https://play.google.com/store/apps/details?id=$_androidPackageId');
                      }
                      launchUrl(storeUri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    'Enviar',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showJoinHouseDialog(BuildContext context, WidgetRef ref, String Function(String) t, bool isDark) {
    final codeCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState2) => AlertDialog(
          title: Text('Entrar em outra casa',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Digite o código de convite da casa que deseja entrar.',
                  style: GoogleFonts.inter(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código de convite',
                  prefixIcon: Icon(Icons.key_rounded, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE53E3E))),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
            TextButton(
              onPressed: loading ? null : () async {
                if (codeCtrl.text.trim().isEmpty) return;
                setState2(() { loading = true; error = null; });
                final result = await ref.read(authProvider.notifier).joinHouse(codeCtrl.text.trim());
                if (result != null) {
                  setState2(() { loading = false; error = result; });
                } else {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref, String Function(String) t) {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('settings.deleteAccount'),
            style: const TextStyle(color: AppColors.destructive)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('settings.deleteAccountWarning'),
                style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t('auth.password'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              if (passwordCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              final error = await ref
                  .read(authProvider.notifier)
                  .deleteAccount(passwordCtrl.text);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(t('settings.deleteAccount'),
                style: const TextStyle(color: AppColors.destructive)),
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

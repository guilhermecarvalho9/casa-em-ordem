import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/password_model.dart';
import '../providers/passwords_provider.dart';

class PasswordsPage extends ConsumerStatefulWidget {
  const PasswordsPage({super.key});

  @override
  ConsumerState<PasswordsPage> createState() => _PasswordsPageState();
}

class _PasswordsPageState extends ConsumerState<PasswordsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final passwordsAsync = ref.watch(passwordsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final wifi = passwordsAsync.valueOrNull?.where((p) => p.category == 'wifi').toList() ?? [];
    final streaming = passwordsAsync.valueOrNull?.where((p) => p.category == 'streaming').toList() ?? [];
    final other = passwordsAsync.valueOrNull?.where((p) => p.category == 'other').toList() ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          Container(
            color: isDark ? AppColors.cardDark : AppColors.card,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: t('passwords.wifi')),
                Tab(text: t('passwords.streaming')),
                Tab(text: t('passwords.other')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PasswordList(passwords: wifi, isDark: isDark, t: t),
                _PasswordList(passwords: streaming, isDark: isDark, t: t),
                _PasswordList(passwords: other, isDark: isDark, t: t),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPassword(context, isDark, t),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddPassword(BuildContext context, bool isDark, String Function(String) t) {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String selectedCategory = 'other';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final authState = ref.read(authProvider);
        return StatefulBuilder(
          builder: (_, setState2) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('passwords.add'),
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600, fontSize: 18,
                          color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: t('common.name')),
                    validator: (v) => v?.isEmpty == true ? t('common.required') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: valueCtrl,
                    decoration: InputDecoration(labelText: t('passwords.value')),
                    validator: (v) => v?.isEmpty == true ? t('common.required') : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: t('passwords.category')),
                    items: [
                      DropdownMenuItem(value: 'wifi', child: Text(t('passwords.wifi'))),
                      DropdownMenuItem(value: 'streaming', child: Text(t('passwords.streaming'))),
                      DropdownMenuItem(value: 'other', child: Text(t('passwords.other'))),
                    ],
                    onChanged: (v) => setState2(() => selectedCategory = v ?? 'other'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await ref.read(passwordsProvider.notifier).addPassword(
                          name: nameCtrl.text.trim(),
                          value: valueCtrl.text.trim(),
                          category: selectedCategory,
                          createdBy: authState.user?.uid ?? '',
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(t('common.save')),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordList extends ConsumerWidget {
  final List<PasswordModel> passwords;
  final bool isDark;
  final String Function(String) t;

  const _PasswordList({required this.passwords, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (passwords.isEmpty) {
      return EmptyState(icon: Icons.lock_outline_rounded, message: t('passwords.noPasswords'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: passwords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _PasswordCard(
        password: passwords[i],
        isDark: isDark,
        t: t,
        onDelete: () => ref.read(passwordsProvider.notifier).deletePassword(passwords[i].id),
      ),
    );
  }
}

class _PasswordCard extends StatefulWidget {
  final PasswordModel password;
  final bool isDark;
  final String Function(String) t;
  final VoidCallback onDelete;

  const _PasswordCard({
    required this.password,
    required this.isDark,
    required this.t,
    required this.onDelete,
  });

  @override
  State<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<_PasswordCard> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.password.category == 'wifi'
        ? Icons.wifi_rounded
        : widget.password.category == 'streaming'
            ? Icons.play_circle_outline_rounded
            : Icons.key_rounded;
    final color = widget.password.category == 'wifi'
        ? AppColors.primary
        : widget.password.category == 'streaming'
            ? AppColors.accent
            : const Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.password.name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14,
                        color: widget.isDark ? AppColors.foregroundDark : AppColors.foreground)),
                const SizedBox(height: 2),
                Text(
                  _visible ? widget.password.value : '••••••••',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: widget.isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: widget.isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
            onPressed: () => setState(() => _visible = !_visible),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.password.value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(widget.t('passwords.copied')),
                    duration: const Duration(seconds: 2)),
              );
            },
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
            onPressed: widget.onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

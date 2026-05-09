import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../app/providers/app_provider.dart';
import '../models/permissions_model.dart';
import '../providers/permissions_provider.dart';

class PermissionsPage extends ConsumerStatefulWidget {
  const PermissionsPage({super.key});

  @override
  ConsumerState<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<PermissionsPage> {
  late PermissionsModel _local;
  bool _saving = false;

  static const _roles = ['owner', 'member', 'guest'];

  static const _sections = [
    _Section('tasks',     ['tasks.add', 'tasks.complete', 'tasks.delete']),
    _Section('bills',     ['bills.add', 'bills.markPaid', 'bills.delete']),
    _Section('events',    ['events.add', 'events.edit', 'events.delete']),
    _Section('inventory', ['inventory.add', 'inventory.edit', 'inventory.delete']),
    _Section('shopping',  ['shopping.add', 'shopping.delete']),
    _Section('rules',     ['rules.add', 'rules.delete']),
    _Section('damaged',   ['damaged.add', 'damaged.delete']),
  ];

  @override
  void initState() {
    super.initState();
    _local = ref.read(permissionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(t('permissions.title'),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(t),
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : Text(t('common.save'),
                    style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              t('permissions.description'),
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppColors.foregroundDark : AppColors.foreground),
            ),
          ),
          // Role legend
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(child: Text(t('permissions.action'), style: _labelStyle(isDark))),
              ..._roles.map((r) => SizedBox(
                    width: 52,
                    child: Center(
                      child: Text(t('members.role.$r'),
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 4),
          ..._sections.map((section) => _buildSection(section, isDark, t)),
        ],
      ),
    );
  }

  Widget _buildSection(_Section section, bool isDark, String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          t('permissions.${section.key}'),
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600, fontSize: 13,
              color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          child: Column(
            children: section.actions.map((action) {
              final roles = _local.rolesFor(action);
              final actionKey = action.split('.').last;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(t('permissions.action.$actionKey'),
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                        ),
                        // Admin always on (not toggleable)
                        SizedBox(
                          width: 52,
                          child: Center(
                            child: Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                        ),
                        ..._roles.map((role) {
                          final enabled = roles.contains(role);
                          return SizedBox(
                            width: 52,
                            child: Center(
                              child: GestureDetector(
                                onTap: () => _toggle(action, role, roles),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: enabled ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: enabled ? AppColors.primary
                                          : (isDark ? AppColors.borderDark : AppColors.border),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: enabled
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 12)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  if (action != section.actions.last)
                    Divider(height: 1,
                        color: isDark ? AppColors.borderDark : AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _toggle(String action, String role, List<String> current) {
    setState(() {
      List<String> updated;
      if (current.contains(role)) {
        updated = current.where((r) => r != role).toList();
      } else {
        updated = [...current, role];
      }
      // always keep admin
      if (!updated.contains('admin')) updated.add('admin');
      _local = _local.withAction(action, updated);
    });
  }

  Future<void> _save(String Function(String) t) async {
    setState(() => _saving = true);
    final error = await ref.read(permissionsProvider.notifier).save(_local);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? t('permissions.saved')),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
    if (error == null) Navigator.pop(context);
  }

  TextStyle _labelStyle(bool isDark) => GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground);
}

class _Section {
  final String key;
  final List<String> actions;
  const _Section(this.key, this.actions);
}

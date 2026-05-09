import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../permissions/providers/permissions_provider.dart';
import '../models/rule_model.dart';
import '../providers/rules_provider.dart';

class RulesPage extends ConsumerStatefulWidget {
  const RulesPage({super.key});

  @override
  ConsumerState<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends ConsumerState<RulesPage> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final rulesAsync = ref.watch(rulesProvider);
    final perms = ref.watch(permissionsProvider);
    final myRole = ref.watch(authProvider).houseMembership?.role ?? 'guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final rules = rulesAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (_) => rules.isEmpty
            ? EmptyState(icon: Icons.rule_outlined, message: t('rules.noRules'))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.read(rulesProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _RuleCard(
                    rule: rules[i],
                    isDark: isDark,
                    t: t,
                    onEdit: perms.can('rules.add', myRole)
                        ? () => _showRuleForm(context, isDark, t, editing: rules[i]) : null,
                    onDelete: perms.can('rules.delete', myRole)
                        ? () => _confirmDelete(context, ref, rules[i], t) : null,
                  ),
                ),
              ),
      ),
      floatingActionButton: perms.can('rules.add', myRole)
          ? FloatingActionButton(
              onPressed: () => _showRuleForm(context, isDark, t),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, RuleModel rule, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.confirm')),
        content: Text('${t('common.deleteConfirm')} "${rule.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(rulesProvider.notifier).deleteRule(rule.id);
            },
            child: Text(t('common.delete'), style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showRuleForm(BuildContext context, bool isDark, String Function(String) t, {RuleModel? editing}) {
    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final authState = ref.read(authProvider);
        return Padding(
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
                Text(
                  editing == null ? t('rules.add') : t('common.edit'),
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, fontSize: 18,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: t('common.title')),
                  validator: (v) => v?.isEmpty == true ? t('common.required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: t('common.description')),
                  maxLines: 3,
                  validator: (v) => v?.isEmpty == true ? t('common.required') : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (editing == null) {
                        await ref.read(rulesProvider.notifier).addRule(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          createdBy: authState.user?.uid ?? '',
                        );
                      } else {
                        await ref.read(rulesProvider.notifier).updateRule(
                          ruleId: editing.id,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(t('common.save')),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RuleCard extends StatelessWidget {
  final RuleModel rule;
  final bool isDark;
  final String Function(String) t;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RuleCard({
    required this.rule,
    required this.isDark,
    required this.t,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rule_rounded, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 14,
                          color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                  if (rule.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(rule.description,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 17,
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 17, color: AppColors.destructive),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rule.title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(rule.description,
            style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

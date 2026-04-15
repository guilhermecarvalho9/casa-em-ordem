import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
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
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _RuleCard(
                  rule: rules[i],
                  isDark: isDark,
                  onDelete: () => ref.read(rulesProvider.notifier).deleteRule(rules[i].id),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRule(context, isDark, t),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddRule(BuildContext context, bool isDark, String Function(String) t) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
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
                Text(t('rules.add'),
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 18,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: t('common.title')),
                  validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: t('common.description')),
                  maxLines: 3,
                  validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await ref.read(rulesProvider.notifier).addRule(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
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
        );
      },
    );
  }
}

class _RuleCard extends StatelessWidget {
  final RuleModel rule;
  final bool isDark;
  final VoidCallback onDelete;

  const _RuleCard({required this.rule, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                          color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

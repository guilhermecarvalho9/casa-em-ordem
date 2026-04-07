import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/member_avatar.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../models/task_model.dart';
import '../providers/tasks_provider.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final pending = tasksAsync.valueOrNull?.where((t) => !t.completed).toList() ?? [];
    final completed = tasksAsync.valueOrNull?.where((t) => t.completed).toList() ?? [];

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
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(text: '${t('tasks.pending')} (${pending.length})'),
                Tab(text: '${t('tasks.completed')} (${completed.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(tasks: pending, isDark: isDark, t: t),
                _TaskList(tasks: completed, isDark: isDark, t: t),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context, isDark, t),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddTask(BuildContext context, bool isDark, String Function(String) t) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedAssignee;
    String? selectedRecurring;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final members = ref.read(membersProvider).valueOrNull ?? [];
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
                Text(t('tasks.add'), style: GoogleFonts.plusJakartaSans(
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
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                if (members.isNotEmpty)
                  StatefulBuilder(builder: (_, setState2) => DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: t('tasks.assignedTo')),
                    items: members.map((m) => DropdownMenuItem(
                      value: m.userId,
                      child: Text(m.name),
                    )).toList(),
                    onChanged: (v) => setState2(() => selectedAssignee = v),
                  )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await ref.read(tasksProvider.notifier).addTask(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        assignedTo: selectedAssignee,
                        recurring: selectedRecurring,
                        createdBy: authState.user?.id ?? '',
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

class _TaskList extends ConsumerWidget {
  final List<TaskModel> tasks;
  final bool isDark;
  final String Function(String) t;

  const _TaskList({required this.tasks, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle_outline_rounded,
        message: t('tasks.noTasks'),
      );
    }

    final members = ref.watch(membersProvider).valueOrNull ?? [];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final task = tasks[i];
        final assignee = members.where((m) => m.userId == task.assignedTo).firstOrNull;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(tasksProvider.notifier)
                    .toggleComplete(task.id, !task.completed),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: task.completed ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: task.completed ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border),
                      width: 1.5,
                    ),
                  ),
                  child: task.completed
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: task.completed
                            ? (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)
                            : (isDark ? AppColors.foregroundDark : AppColors.foreground),
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.dueDate != null || assignee != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (assignee != null) ...[
                            MemberAvatar(name: assignee.name, color: assignee.color, radius: 10),
                            const SizedBox(width: 4),
                            Text(
                              assignee.name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (task.dueDate != null)
                            Text(
                              _formatDate(task.dueDate!),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                onPressed: () => ref.read(tasksProvider.notifier).deleteTask(task.id),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date;
    }
  }
}

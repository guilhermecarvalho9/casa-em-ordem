import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/member_avatar.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../permissions/providers/permissions_provider.dart';
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
    final perms = ref.watch(permissionsProvider);
    final myRole = ref.watch(authProvider).houseMembership?.role ?? 'guest';
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
                _TaskList(
                  tasks: pending, isDark: isDark, t: t,
                  onDelete: perms.can('tasks.delete', myRole)
                      ? (task) => _confirmDelete(context, task, t) : null,
                  onTap: (task) => _showTaskDetail(context, task, isDark, t),
                ),
                _TaskList(
                  tasks: completed, isDark: isDark, t: t,
                  onDelete: perms.can('tasks.delete', myRole)
                      ? (task) => _confirmDelete(context, task, t) : null,
                  onTap: (task) => _showTaskDetail(context, task, isDark, t),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: perms.can('tasks.add', myRole)
          ? FloatingActionButton(
              onPressed: () => _showAddTask(context, isDark, t),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _confirmDelete(BuildContext context, TaskModel task, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.confirm')),
        content: Text('${t('common.deleteConfirm')} "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(tasksProvider.notifier).deleteTask(task.id);
            },
            child: Text(t('common.delete'), style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showTaskDetail(BuildContext context, TaskModel task, bool isDark, String Function(String) t) {
    final members = ref.read(membersProvider).valueOrNull ?? [];
    final assignee = members.where((m) => m.userId == task.assignedTo).firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (ctx, scrollCtrl) => StatefulBuilder(
          builder: (ctx2, setSheet) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Title row with checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (task.photoRequired && !task.completed && task.photosBefore.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t('tasks.photoRequiredWarning'))),
                                );
                                return;
                              }
                              await ref.read(tasksProvider.notifier).toggleComplete(task.id, !task.completed);
                              if (ctx2.mounted) Navigator.pop(ctx2);
                            },
                            child: Container(
                              width: 24, height: 24, margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: task.completed ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: task.completed ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border),
                                  width: 1.5,
                                ),
                              ),
                              child: task.completed
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                                decoration: task.completed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Badges row
                      Wrap(
                        spacing: 8, runSpacing: 6,
                        children: [
                          if (task.photoRequired)
                            _Badge(
                              icon: Icons.camera_alt_outlined,
                              label: t('tasks.photoRequired'),
                              color: AppColors.accent,
                            ),
                          if (task.recurring != null)
                            _Badge(
                              icon: Icons.repeat_rounded,
                              label: _recurringLabel(task.recurring!, t),
                              color: AppColors.primary,
                            ),
                          if (task.dueDate != null)
                            _Badge(
                              icon: Icons.calendar_today_outlined,
                              label: _formatDate(task.dueDate!),
                              color: AppColors.mutedForeground,
                            ),
                        ],
                      ),

                      // Description
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          task.description!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                            height: 1.5,
                          ),
                        ),
                      ],

                      // Assignee
                      if (assignee != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            MemberAvatar(name: assignee.name, color: assignee.color, radius: 14),
                            const SizedBox(width: 8),
                            Text(assignee.name,
                                style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Photos Before
                      _PhotoSection(
                        label: t('tasks.photosBefore'),
                        photos: task.photosBefore,
                        isDark: isDark,
                        onAdd: () async {
                          final file = await _pickImage();
                          if (file != null) {
                            await ref.read(tasksProvider.notifier).addPhoto(task.id, file, isBefore: true);
                            if (ctx2.mounted) Navigator.pop(ctx2);
                          }
                        },
                        onRemove: (url) async {
                          await ref.read(tasksProvider.notifier).removePhoto(task.id, url, isBefore: true);
                          if (ctx2.mounted) Navigator.pop(ctx2);
                        },
                        t: t,
                      ),
                      const SizedBox(height: 16),

                      // Photos After
                      _PhotoSection(
                        label: t('tasks.photosAfter'),
                        photos: task.photosAfter,
                        isDark: isDark,
                        onAdd: () async {
                          final file = await _pickImage();
                          if (file != null) {
                            await ref.read(tasksProvider.notifier).addPhoto(task.id, file, isBefore: false);
                            if (ctx2.mounted) Navigator.pop(ctx2);
                          }
                        },
                        onRemove: (url) async {
                          await ref.read(tasksProvider.notifier).removePhoto(task.id, url, isBefore: false);
                          if (ctx2.mounted) Navigator.pop(ctx2);
                        },
                        t: t,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<File?> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return null;
    return File(picked.path);
  }

  void _showAddTask(BuildContext context, bool isDark, String Function(String) t) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedAssignee;
    bool photoRequired = false;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String reminderType = 'none';
    final formKey = GlobalKey<FormState>();

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    String fmtTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final reminderOptions = [
      ('none', 'Sem lembrete'),
      ('dayBefore', '1 dia antes'),
      ('hourBefore', '1 hora antes'),
      ('both', 'Ambos'),
    ];

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
        final appState = ref.read(appProvider);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Form(
            key: formKey,
            child: StatefulBuilder(builder: (_, setState2) => SingleChildScrollView(
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
                    validator: (v) => v?.isEmpty == true ? t('common.required') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: t('common.description')),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  if (members.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: t('tasks.assignedTo')),
                      items: members.map((m) => DropdownMenuItem(
                        value: m.userId,
                        child: Text(m.name),
                      )).toList(),
                      onChanged: (v) => setState2(() => selectedAssignee = v),
                    ),
                  const SizedBox(height: 12),
                  // Date + Time row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text(
                            selectedDate != null ? fmtDate(selectedDate!) : 'Data (opcional)',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) setState2(() => selectedDate = picked);
                          },
                        ),
                      ),
                      if (selectedDate != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time_rounded, size: 16),
                            label: Text(
                              selectedTime != null ? fmtTime(selectedTime!) : 'Horário',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) setState2(() => selectedTime = picked);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (selectedDate != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: reminderType,
                      decoration: const InputDecoration(
                        labelText: 'Lembrete',
                        prefixIcon: Icon(Icons.notifications_outlined, size: 18),
                      ),
                      items: reminderOptions.map((o) => DropdownMenuItem(
                        value: o.$1,
                        child: Text(o.$2, style: GoogleFonts.inter(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) => setState2(() => reminderType = v ?? 'none'),
                    ),
                  ],
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t('tasks.photoRequired'),
                        style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                    value: photoRequired,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState2(() => photoRequired = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        String? dueDateStr;
                        String? dueTimeStr;
                        if (selectedDate != null) {
                          dueDateStr = '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                        }
                        if (selectedTime != null) {
                          dueTimeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                        }
                        await ref.read(tasksProvider.notifier).addTask(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          assignedTo: selectedAssignee,
                          dueDate: dueDateStr,
                          dueTime: dueTimeStr,
                          reminderType: dueDateStr != null ? reminderType : null,
                          recurring: null,
                          createdBy: authState.user?.uid ?? '',
                          photoRequired: photoRequired,
                          language: appState.language,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(t('common.save')),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )),
          ),
        );
      },
    );
  }
}

// ── _TaskList ────────────────────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  final List<TaskModel> tasks;
  final bool isDark;
  final String Function(String) t;
  final void Function(TaskModel)? onDelete;
  final void Function(TaskModel) onTap;

  const _TaskList({
    required this.tasks,
    required this.isDark,
    required this.t,
    this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle_outline_rounded,
        message: t('tasks.noTasks'),
      );
    }

    final members = ref.watch(membersProvider).valueOrNull ?? [];
    final perms = ref.watch(permissionsProvider);
    final myRole = ref.watch(authProvider).houseMembership?.role ?? 'guest';
    final canComplete = perms.can('tasks.complete', myRole);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(tasksProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final task = tasks[i];
          final assignee = members.where((m) => m.userId == task.assignedTo).firstOrNull;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(task),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: canComplete ? () => ref.read(tasksProvider.notifier)
                        .toggleComplete(task.id, !task.completed) : null,
                    child: Container(
                      width: 22, height: 22,
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
                            fontSize: 14, fontWeight: FontWeight.w500,
                            color: task.completed
                                ? (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)
                                : (isDark ? AppColors.foregroundDark : AppColors.foreground),
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.dueDate != null || assignee != null || task.photoRequired) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (assignee != null) ...[
                                MemberAvatar(name: assignee.name, color: assignee.color, radius: 10),
                                const SizedBox(width: 4),
                                Text(assignee.name, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                                const SizedBox(width: 8),
                              ],
                              if (task.dueDate != null)
                                Text(
                                  task.dueTime != null
                                      ? '${_formatDate(task.dueDate!)} ${task.dueTime}'
                                      : _formatDate(task.dueDate!),
                                  style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                                ),
                              if (task.photoRequired) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.accent),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (task.photosBefore.isNotEmpty || task.photosAfter.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.photo_library_outlined, size: 16, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                      onPressed: () => onDelete!(task),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          );
        },
      ),
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

// ── _PhotoSection ────────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.label,
    required this.photos,
    required this.isDark,
    required this.onAdd,
    required this.onRemove,
    required this.t,
  });

  final String label;
  final List<String> photos;
  final bool isDark;
  final VoidCallback onAdd;
  final void Function(String url) onRemove;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
              label: Text(t('tasks.addPhoto'), style: GoogleFonts.inter(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        if (photos.isEmpty)
          Text(t('tasks.noPhotos'),
              style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground))
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final url = photos[i];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 100, height: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 100, height: 100,
                          color: isDark ? AppColors.borderDark : AppColors.border,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 100, height: 100,
                          color: isDark ? AppColors.borderDark : AppColors.border,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: () => onRemove(url),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

String _formatDate(String date) {
  try {
    final d = DateTime.parse(date);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return date;
  }
}

String _recurringLabel(String recurring, String Function(String) t) {
  switch (recurring) {
    case 'daily': return t('tasks.recurring.daily');
    case 'weekly': return t('tasks.recurring.weekly');
    case 'monthly': return t('tasks.recurring.monthly');
    default: return recurring;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/damaged_model.dart';
import '../providers/damaged_provider.dart';

class DamagedPage extends ConsumerStatefulWidget {
  const DamagedPage({super.key});

  @override
  ConsumerState<DamagedPage> createState() => _DamagedPageState();
}

class _DamagedPageState extends ConsumerState<DamagedPage>
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
    final damagedAsync = ref.watch(damagedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final pending = damagedAsync.valueOrNull?.where((d) => d.isPending).toList() ?? [];
    final fixed = damagedAsync.valueOrNull?.where((d) => !d.isPending).toList() ?? [];

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
                Tab(text: '${t('damaged.pending')} (${pending.length})'),
                Tab(text: '${t('damaged.fixed')} (${fixed.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DamagedList(items: pending, isDark: isDark, t: t),
                _DamagedList(items: fixed, isDark: isDark, t: t),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItem(context, isDark, t),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddItem(BuildContext context, bool isDark, String Function(String) t) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    File? pickedImage;
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('damaged.add'),
                        style: GoogleFonts.plusJakartaSans(
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
                    TextFormField(
                      controller: locationCtrl,
                      decoration: InputDecoration(
                          labelText: t('damaged.location'),
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18)),
                      validator: (v) => v?.isEmpty == true ? t('common.required') : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(source: ImageSource.camera);
                        if (img != null) setState2(() => pickedImage = File(img.path));
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: Text(pickedImage != null ? t('damaged.photoAdded') : t('damaged.takePhoto')),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          await ref.read(damagedProvider.notifier).addItem(
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                            location: locationCtrl.text.trim(),
                            reportedBy: authState.user?.uid ?? '',
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
          ),
        );
      },
    );
  }
}

class _DamagedList extends ConsumerWidget {
  final List<DamagedItemModel> items;
  final bool isDark;
  final String Function(String) t;

  const _DamagedList({required this.items, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyState(icon: Icons.warning_amber_outlined, message: t('damaged.noItems'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: item.isPending
                          ? AppColors.warning.withValues(alpha: 0.12)
                          : AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.isPending ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                      color: item.isPending ? AppColors.warning : AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 14,
                                color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12,
                                color: AppColors.mutedForeground),
                            const SizedBox(width: 2),
                            Text(item.location,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: item.isPending ? t('damaged.status.pending') : t('damaged.status.fixed'),
                    type: item.isPending ? BadgeType.warning : BadgeType.success,
                  ),
                ],
              ),
              if (item.description != null) ...[
                const SizedBox(height: 8),
                Text(item.description!,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.isPending)
                    TextButton.icon(
                      onPressed: () => ref.read(damagedProvider.notifier).markFixed(item.id),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(t('damaged.markFixed')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                    onPressed: () => ref.read(damagedProvider.notifier).deleteItem(item.id),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

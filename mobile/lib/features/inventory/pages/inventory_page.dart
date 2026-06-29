import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../permissions/providers/permissions_provider.dart';
import '../models/inventory_item_model.dart';
import '../providers/inventory_provider.dart';

const _categories = ['electronics', 'furniture', 'kitchen', 'bedroom', 'bathroom', 'tools', 'other'];

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String _filterOwner = '';
  String _filterCategory = '';

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final authState = ref.watch(authProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final membersAsync = ref.watch(membersProvider);
    final perms = ref.watch(permissionsProvider);
    final myRole = authState.houseMembership?.role ?? 'guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final members = membersAsync.valueOrNull ?? [];
    final isAdmin = authState.houseMembership?.isAdmin == true ||
        authState.houseMembership?.role == 'owner';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          // Filters
          Container(
            color: isDark ? AppColors.cardDark : AppColors.card,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: _filterOwner.isEmpty
                        ? t('inventory.allOwners')
                        : (members.firstWhere(
                              (m) => m.userId == _filterOwner,
                              orElse: () => members.first,
                            ).name),
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                    onTap: () => _pickOwnerFilter(context, members, t, isDark),
                    active: _filterOwner.isNotEmpty,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterChip(
                    label: _filterCategory.isEmpty
                        ? t('inventory.allCategories')
                        : t('inventory.category.$_filterCategory'),
                    icon: Icons.category_outlined,
                    isDark: isDark,
                    onTap: () => _pickCategoryFilter(context, t, isDark),
                    active: _filterCategory.isNotEmpty,
                  ),
                ),
                if (_filterOwner.isNotEmpty || _filterCategory.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    color: AppColors.mutedForeground,
                    onPressed: () => setState(() {
                      _filterOwner = '';
                      _filterCategory = '';
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (items) {
                final filtered = items.where((item) {
                  if (_filterOwner.isNotEmpty && item.ownerId != _filterOwner) return false;
                  if (_filterCategory.isNotEmpty && item.category != _filterCategory) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: t('inventory.noItems'),
                  );
                }

                // Summary header
                final totalValue = filtered.fold<double>(0, (s, i) => s + i.value);

                return Column(
                  children: [
                    // Value summary — only shown when at least one item has a value
                    if (totalValue > 0)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filtered.length} ${t('inventory.items')}',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                            ),
                            Text(
                              'Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(totalValue)}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
                        child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _InventoryCard(
                          item: filtered[i],
                          isDark: isDark,
                          t: t,
                          canEdit: perms.can('inventory.edit', myRole) &&
                              (isAdmin || filtered[i].ownerId == authState.user?.uid),
                          onEdit: perms.can('inventory.edit', myRole)
                              ? () => _showEditItem(
                                  context, filtered[i], members, t, isDark, authState.user?.uid ?? '')
                              : null,
                          onDelete: perms.can('inventory.delete', myRole)
                              ? () => _confirmDelete(context, ref, filtered[i], t) : null,
                        ),
                      ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: perms.can('inventory.add', myRole)
          ? FloatingActionButton(
              onPressed: () => _showAddItem(context, members, t, isDark, authState.user?.uid ?? ''),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _pickOwnerFilter(BuildContext context, List members, String Function(String) t, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final items = [
          ListTile(
            leading: const Icon(Icons.people_outline_rounded),
            title: Text(t('inventory.allOwners')),
            onTap: () { setState(() => _filterOwner = ''); Navigator.pop(ctx); },
            selected: _filterOwner.isEmpty,
            selectedColor: AppColors.primary,
          ),
          ...members.map((m) => ListTile(
            title: Text(m.name),
            onTap: () { setState(() => _filterOwner = m.userId); Navigator.pop(ctx); },
            selected: _filterOwner == m.userId,
            selectedColor: AppColors.primary,
          )),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: items,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _pickCategoryFilter(BuildContext context, String Function(String) t, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final items = [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(t('inventory.allCategories')),
            onTap: () { setState(() => _filterCategory = ''); Navigator.pop(ctx); },
            selected: _filterCategory.isEmpty,
            selectedColor: AppColors.primary,
          ),
          ..._categories.map((c) => ListTile(
            leading: Icon(_categoryIcon(c)),
            title: Text(t('inventory.category.$c')),
            onTap: () { setState(() => _filterCategory = c); Navigator.pop(ctx); },
            selected: _filterCategory == c,
            selectedColor: AppColors.primary,
          )),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: items,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, InventoryItemModel item, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.confirm')),
        content: Text('${t('common.deleteConfirm')} "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(inventoryProvider.notifier).deleteItem(item.id, item.photoUrl);
            },
            child: Text(t('common.delete'), style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showAddItem(BuildContext context, List members, String Function(String) t, bool isDark, String currentUserId) {
    _showItemForm(context, members, t, isDark, currentUserId, null);
  }

  void _showEditItem(BuildContext context, InventoryItemModel item, List members,
      String Function(String) t, bool isDark, String currentUserId) {
    _showItemForm(context, members, t, isDark, currentUserId, item);
  }

  void _showItemForm(BuildContext context, List members, String Function(String) t,
      bool isDark, String currentUserId, InventoryItemModel? editing) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final valueCtrl = TextEditingController(
        text: editing != null && editing.value > 0 ? editing.value.toStringAsFixed(2) : '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');
    String selectedCategory = editing?.category ?? 'other';
    String selectedOwnerId = editing?.ownerId ?? currentUserId;
    String selectedOwnerName = editing?.ownerName ?? '';
    File? pickedPhoto;
    final formKey = GlobalKey<FormState>();

    // Set owner name from members list
    if (selectedOwnerId.isNotEmpty && selectedOwnerName.isEmpty) {
      try {
        selectedOwnerName = members.firstWhere((m) => m.userId == selectedOwnerId).name;
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
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
                  Text(
                    editing == null ? t('inventory.add') : t('common.edit'),
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 18,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                  ),
                  const SizedBox(height: 16),
                  // Photo
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 70, maxWidth: 800);
                        if (picked != null) {
                          setState2(() => pickedPhoto = File(picked.path));
                        }
                      },
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                        ),
                        child: pickedPhoto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.file(pickedPhoto!, fit: BoxFit.cover))
                            : editing?.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: CachedNetworkImage(
                                        imageUrl: editing!.photoUrl!, fit: BoxFit.cover))
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 28, color: AppColors.mutedForeground),
                                      const SizedBox(height: 4),
                                      Text(t('inventory.addPhoto'),
                                          style: GoogleFonts.inter(
                                              fontSize: 10, color: AppColors.mutedForeground),
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: t('common.name')),
                    validator: (v) => v?.isEmpty == true ? t('common.required') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: valueCtrl,
                    decoration: InputDecoration(labelText: t('inventory.value'), prefixText: 'R\$ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(labelText: t('inventory.category')),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(children: [
                              Icon(_categoryIcon(c), size: 16, color: AppColors.mutedForeground),
                              const SizedBox(width: 8),
                              Text(t('inventory.category.$c')),
                            ])))
                        .toList(),
                    onChanged: (v) => setState2(() => selectedCategory = v ?? 'other'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedOwnerId.isEmpty ? '' : selectedOwnerId,
                    decoration: InputDecoration(labelText: t('inventory.owner')),
                    items: [
                      DropdownMenuItem(value: '', child: Text(t('inventory.shared'))),
                      ...members.map((m) => DropdownMenuItem(
                          value: m.userId as String,
                          child: Text(m.name as String))),
                    ],
                    onChanged: (v) {
                      setState2(() {
                        selectedOwnerId = v ?? '';
                        selectedOwnerName = v == null || v.isEmpty
                            ? ''
                            : members.firstWhere((m) => m.userId == v).name as String;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: t('common.description')),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final value = double.tryParse(
                                valueCtrl.text.replaceAll(',', '.')) ?? 0;
                        if (editing == null) {
                          await ref.read(inventoryProvider.notifier).addItem(
                            name: nameCtrl.text.trim(),
                            category: selectedCategory,
                            value: value,
                            ownerId: selectedOwnerId,
                            ownerName: selectedOwnerName,
                            createdBy: currentUserId,
                            description: descCtrl.text.trim(),
                            photo: pickedPhoto,
                          );
                        } else {
                          await ref.read(inventoryProvider.notifier).updateItem(
                            itemId: editing.id,
                            name: nameCtrl.text.trim(),
                            category: selectedCategory,
                            value: value,
                            ownerId: selectedOwnerId,
                            ownerName: selectedOwnerName,
                            description: descCtrl.text.trim(),
                            newPhoto: pickedPhoto,
                            existingPhotoUrl: editing.photoUrl,
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
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItemModel item;
  final bool isDark;
  final String Function(String) t;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _InventoryCard({
    required this.item,
    required this.isDark,
    required this.t,
    required this.canEdit,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo or placeholder
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: SizedBox(
              width: 80,
              height: 80,
              child: item.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                          child: const Icon(Icons.image_outlined, color: AppColors.mutedForeground)),
                      errorWidget: (_, __, ___) => _iconPlaceholder(isDark),
                    )
                  : _iconPlaceholder(isDark),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusBadge(
                        label: t('inventory.category.${item.category}'),
                        type: BadgeType.info,
                      ),
                      const SizedBox(width: 6),
                      if (!item.isShared)
                        StatusBadge(label: item.ownerName, type: BadgeType.muted),
                      if (item.isShared)
                        StatusBadge(label: t('inventory.shared'), type: BadgeType.muted),
                    ],
                  ),
                  if (item.value > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(item.value),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description!,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canEdit)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18,
                      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _iconPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.secondaryDark : AppColors.secondary,
      child: Center(
        child: Icon(_categoryIcon(item.category),
            size: 28, color: AppColors.mutedForeground),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.secondaryDark : AppColors.secondary),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.primary.withValues(alpha: 0.4) : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: active ? AppColors.primary : AppColors.mutedForeground),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: active
                        ? AppColors.primary
                        : (isDark ? AppColors.foregroundDark : AppColors.foreground),
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 14,
                color: active ? AppColors.primary : AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'electronics': return Icons.devices_rounded;
    case 'furniture': return Icons.chair_rounded;
    case 'kitchen': return Icons.kitchen_rounded;
    case 'bedroom': return Icons.bed_rounded;
    case 'bathroom': return Icons.bathroom_rounded;
    case 'tools': return Icons.handyman_rounded;
    default: return Icons.inventory_2_outlined;
  }
}

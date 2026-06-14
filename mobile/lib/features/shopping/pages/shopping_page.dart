import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/member_avatar.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../../permissions/providers/permissions_provider.dart';
import '../models/shopping_model.dart';
import '../../../shared/services/interstitial_ad_service.dart';
import '../../pro/providers/pro_provider.dart';
import '../models/purchase_model.dart';
import '../providers/shopping_provider.dart';
import '../providers/purchases_provider.dart';

class ShoppingPage extends ConsumerStatefulWidget {
  const ShoppingPage({super.key});

  @override
  ConsumerState<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends ConsumerState<ShoppingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final shoppingAsync = ref.watch(shoppingProvider);
    final perms = ref.watch(permissionsProvider);
    final myRole = ref.watch(authProvider).houseMembership?.role ?? 'guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final toBuy = shoppingAsync.valueOrNull?.where((i) => !i.bought).toList() ?? [];
    final bought = shoppingAsync.valueOrNull?.where((i) => i.bought).toList() ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          Container(
            color: isDark ? AppColors.cardDark : AppColors.card,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
              indicatorColor: AppColors.primary,
              labelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: '${t('shopping.toBuy')} (${toBuy.length})'),
                Tab(text: '${t('shopping.bought')} (${bought.length})'),
                Tab(text: t('shopping.history')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ItemList(
                  items: toBuy,
                  isDark: isDark,
                  t: t,
                  onEdit: perms.can('shopping.add', myRole)
                      ? (item) => _showItemForm(context, isDark, t, editing: item) : null,
                  onDelete: perms.can('shopping.delete', myRole)
                      ? (item) => _confirmDeleteItem(context, item, t) : null,
                ),
                _BoughtList(
                  items: bought,
                  isDark: isDark,
                  t: t,
                  onEdit: perms.can('shopping.add', myRole)
                      ? (item) => _showItemForm(context, isDark, t, editing: item) : null,
                  onDelete: perms.can('shopping.delete', myRole)
                      ? (item) => _confirmDeleteItem(context, item, t) : null,
                ),
                _PurchasesList(
                  isDark: isDark,
                  t: t,
                  onEdit: (p) => _showPurchaseForm(context, isDark, t, editing: p),
                  onDelete: (p) => _confirmDeletePurchase(context, p, t),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              heroTag: 'purchase_fab',
              onPressed: () => _showPurchaseForm(context, isDark, t),
              child: const Icon(Icons.add_shopping_cart_rounded),
            )
          : (_tabController.index == 0 && perms.can('shopping.add', myRole))
              ? FloatingActionButton(
                  heroTag: 'item_fab',
                  onPressed: () => _showItemForm(context, isDark, t),
                  child: const Icon(Icons.add_rounded),
                )
              : null,
    );
  }

  void _confirmDeleteItem(
      BuildContext context, ShoppingItemModel item, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.confirm')),
        content: Text('${t('common.deleteConfirm')} "${item.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(shoppingProvider.notifier).deleteItem(item.id);
            },
            child: Text(t('common.delete'),
                style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePurchase(
      BuildContext context, PurchaseModel purchase, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.confirm')),
        content: Text(t('shopping.confirmDeletePurchase')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(purchasesProvider.notifier)
                  .deletePurchase(purchase.id);
            },
            child: Text(t('common.delete'),
                style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showItemForm(BuildContext context, bool isDark, String Function(String) t,
      {ShoppingItemModel? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ItemFormSheet(isDark: isDark, t: t, editing: editing),
    );
  }

  void _showPurchaseForm(BuildContext context, bool isDark, String Function(String) t,
      {PurchaseModel? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _PurchaseFormSheet(isDark: isDark, t: t, editing: editing),
    );
  }
}

// ── Purchase History Tab ──────────────────────────────────────────────────────

class _PurchasesList extends ConsumerWidget {
  final bool isDark;
  final String Function(String) t;
  final void Function(PurchaseModel) onEdit;
  final void Function(PurchaseModel) onDelete;

  const _PurchasesList({
    required this.isDark,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? [];

    return purchasesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (purchases) {
        if (purchases.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            message: t('shopping.noPurchases'),
          );
        }

        // Build per-person totals across all purchases
        final Map<String, double> personTotals = {};
        double grandTotal = 0;
        for (final p in purchases) {
          grandTotal += p.total;
          if (p.splitBetween.isNotEmpty) {
            final share = p.total / p.splitBetween.length;
            for (final uid in p.splitBetween) {
              personTotals[uid] = (personTotals[uid] ?? 0) + share;
            }
          }
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(purchasesProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (personTotals.isNotEmpty) ...[
                _PurchaseSummaryCard(
                  grandTotal: grandTotal,
                  count: purchases.length,
                  personTotals: personTotals,
                  members: members,
                  isDark: isDark,
                  t: t,
                ),
                const SizedBox(height: 12),
              ],
              ...purchases.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PurchaseCard(
                      purchase: p,
                      members: members,
                      isDark: isDark,
                      t: t,
                      onEdit: () => onEdit(p),
                      onDelete: () => onDelete(p),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseSummaryCard extends StatelessWidget {
  final double grandTotal;
  final int count;
  final Map<String, double> personTotals;
  final List<MemberModel> members;
  final bool isDark;
  final String Function(String) t;

  const _PurchaseSummaryCard({
    required this.grandTotal,
    required this.count,
    required this.personTotals,
    required this.members,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final nameFor = {for (final m in members) m.userId: m};

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                t('shopping.purchaseSummary'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${grandTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  Text(
                    '$count ${t('shopping.totalPurchases')}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForeground),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...personTotals.entries.map((e) {
            final member = nameFor[e.key];
            final name =
                member?.name.split(' ').first ?? e.key.substring(0, 6);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  if (member != null)
                    MemberAvatar(
                        name: member.name,
                        color: member.color,
                        avatarUrl: member.avatarUrl,
                        radius: 12)
                  else
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(name[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foreground)),
                  ),
                  Text(
                    'R\$ ${e.value.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foreground),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final PurchaseModel purchase;
  final List<MemberModel> members;
  final bool isDark;
  final String Function(String) t;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PurchaseCard({
    required this.purchase,
    required this.members,
    required this.isDark,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitMembers =
        members.where((m) => purchase.splitBetween.contains(m.userId)).toList();
    final paidByMember =
        members.where((m) => m.userId == purchase.paidBy).firstOrNull;

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.store,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.foregroundDark
                              : AppColors.foreground),
                    ),
                    Text(
                      _formatDate(purchase.date),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${purchase.total.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  if (purchase.splitBetween.length > 1)
                    Text(
                      'R\$ ${purchase.amountPerPerson.toStringAsFixed(2)}/pessoa',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForeground),
                    ),
                ],
              ),
            ],
          ),
          if (splitMembers.isNotEmpty || paidByMember != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                if (splitMembers.isNotEmpty) ...[
                  Expanded(
                    child: Row(
                      children: [
                        ...splitMembers.take(5).map((m) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: MemberAvatar(
                                  name: m.name,
                                  color: m.color,
                                  avatarUrl: m.avatarUrl,
                                  radius: 12),
                            )),
                        if (splitMembers.length > 5)
                          Text('+${splitMembers.length - 5}',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                ],
                if (paidByMember != null) ...[
                  const Icon(Icons.payment_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    paidByMember.name.split(' ').first,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForeground),
                  ),
                ],
              ],
            ),
          ],
          if (purchase.note != null && purchase.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              purchase.note!,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForeground),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForeground),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.destructive),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Purchase Form Sheet ───────────────────────────────────────────────────────

class _PurchaseFormSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final String Function(String) t;
  final PurchaseModel? editing;

  const _PurchaseFormSheet({required this.isDark, required this.t, this.editing});

  @override
  ConsumerState<_PurchaseFormSheet> createState() => _PurchaseFormSheetState();
}

class _PurchaseFormSheetState extends ConsumerState<_PurchaseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _storeCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _noteCtrl;
  DateTime? _selectedDate;
  List<String> _selectedMemberIds = [];
  String? _paidBy;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _storeCtrl = TextEditingController(text: e?.store ?? '');
    _totalCtrl = TextEditingController(
        text: e != null ? e.total.toStringAsFixed(2) : '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedDate =
        e != null ? DateTime.tryParse(e.date) : DateTime.now();
    _selectedMemberIds = e?.splitBetween.toList() ?? [];
    _paidBy = e?.paidBy;
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _totalCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final t = widget.t;
    final editing = widget.editing;
    final members = ref.watch(membersProvider).valueOrNull ?? [];
    final authState = ref.read(authProvider);

    if (_selectedMemberIds.isEmpty && editing == null && members.isNotEmpty) {
      _selectedMemberIds = members.map((m) => m.userId).toList();
    }

    final labelStyle = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
    );

    InputDecoration fieldDecor(String label) => InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 14),
          filled: true,
          fillColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                editing == null ? t('shopping.addPurchase') : t('common.edit'),
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
              ),
              const SizedBox(height: 16),

              // Store name
              TextFormField(
                controller: _storeCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: fieldDecor(t('shopping.store')),
                validator: (v) =>
                    v?.isEmpty == true ? t('common.required') : null,
              ),
              const SizedBox(height: 10),

              // Total + Date row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: fieldDecor(t('shopping.totalAmount'))
                          .copyWith(prefixText: 'R\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return t('common.required');
                        if (double.tryParse(v.replaceAll(',', '.')) == null) {
                          return t('common.required');
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 16,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForeground),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDate != null
                                  ? _displayDate(_selectedDate!)
                                  : t('shopping.purchaseDate'),
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _selectedDate != null
                                      ? (isDark
                                          ? AppColors.foregroundDark
                                          : AppColors.foreground)
                                      : (isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForeground)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Split preview
              if (_selectedMemberIds.isNotEmpty && _totalCtrl.text.isNotEmpty)
                _SplitPreview(
                  priceText: _totalCtrl.text,
                  count: _selectedMemberIds.length,
                  isDark: isDark,
                  t: t,
                ),

              // Split with members
              if (members.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(t('shopping.splitWith'), style: labelStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: Text(t('shopping.selectAll'),
                          style: GoogleFonts.inter(fontSize: 12)),
                      selected: _selectedMemberIds.length == members.length,
                      onSelected: (v) => setState(() {
                        _selectedMemberIds = v
                            ? members.map((m) => m.userId).toList()
                            : [];
                      }),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                    ),
                    ...members.map((m) => FilterChip(
                          label: Text(m.name.split(' ').first,
                              style: GoogleFonts.inter(fontSize: 12)),
                          selected: _selectedMemberIds.contains(m.userId),
                          onSelected: (v) => setState(() {
                            if (v) {
                              _selectedMemberIds = [
                                ..._selectedMemberIds,
                                m.userId
                              ];
                            } else {
                              _selectedMemberIds = _selectedMemberIds
                                  .where((id) => id != m.userId)
                                  .toList();
                            }
                          }),
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                        )),
                  ],
                ),
                const SizedBox(height: 14),

                // Paid by
                Text(t('shopping.paidByOptional'), style: labelStyle),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _paidBy,
                  decoration: fieldDecor(t('shopping.paidBy')),
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foreground),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('-',
                          style: GoogleFonts.inter(fontSize: 14)),
                    ),
                    ...members.map((m) => DropdownMenuItem<String?>(
                          value: m.userId,
                          child: Text(m.name.split(' ').first,
                              style: GoogleFonts.inter(fontSize: 14)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _paidBy = v),
                ),
              ],
              const SizedBox(height: 10),

              // Note
              TextFormField(
                controller: _noteCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration:
                    fieldDecor('${t('common.note')} (${t('common.optional')})'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (_selectedDate == null) return;
                          setState(() => _loading = true);
                          final nav = Navigator.of(context);
                          final total = double.parse(
                              _totalCtrl.text.replaceAll(',', '.'));
                          if (editing == null) {
                            await ref
                                .read(purchasesProvider.notifier)
                                .addPurchase(
                                  store: _storeCtrl.text.trim(),
                                  date: _fmtDate(_selectedDate!),
                                  total: total,
                                  splitBetween: _selectedMemberIds,
                                  paidBy: _paidBy,
                                  note: _noteCtrl.text.trim(),
                                  createdBy: authState.user?.uid ?? '',
                                );
                          } else {
                            await ref
                                .read(purchasesProvider.notifier)
                                .updatePurchase(
                                  purchaseId: editing.id,
                                  store: _storeCtrl.text.trim(),
                                  date: _fmtDate(_selectedDate!),
                                  total: total,
                                  splitBetween: _selectedMemberIds,
                                  paidBy: _paidBy,
                                  note: _noteCtrl.text.trim(),
                                );
                          }
                          if (!mounted) return;
                          nav.pop();
                        },
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(t('common.save'),
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shopping Item Form Sheet ──────────────────────────────────────────────────

class _ItemFormSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final String Function(String) t;
  final ShoppingItemModel? editing;

  const _ItemFormSheet({required this.isDark, required this.t, this.editing});

  @override
  ConsumerState<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends ConsumerState<_ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  List<String> _selectedMemberIds = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _qtyCtrl =
        TextEditingController(text: e != null ? e.quantity.toString() : '1');
    _priceCtrl = TextEditingController(
        text: e?.price != null ? e!.price!.toStringAsFixed(2) : '');
    _selectedMemberIds = e?.splitBetween.toList() ?? [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final t = widget.t;
    final editing = widget.editing;
    final members = ref.watch(membersProvider).valueOrNull ?? [];
    final authState = ref.read(authProvider);

    if (_selectedMemberIds.isEmpty && editing == null && members.isNotEmpty) {
      _selectedMemberIds = members.map((m) => m.userId).toList();
    }

    final labelStyle = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
    );

    InputDecoration fieldDecor(String label) => InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 14),
          filled: true,
          fillColor: isDark ? AppColors.secondaryDark : AppColors.secondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing == null ? t('shopping.add') : t('common.edit'),
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foreground),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: fieldDecor('Item'),
                validator: (v) =>
                    v?.isEmpty == true ? t('common.required') : null,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: fieldDecor(t('shopping.quantity')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: fieldDecor(t('shopping.price'))
                          .copyWith(prefixText: 'R\$ '),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),

              if (members.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(t('shopping.splitWith'), style: labelStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: Text(t('shopping.selectAll'),
                          style: GoogleFonts.inter(fontSize: 12)),
                      selected: _selectedMemberIds.length == members.length,
                      onSelected: (v) => setState(() {
                        _selectedMemberIds = v
                            ? members.map((m) => m.userId).toList()
                            : [];
                      }),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                    ),
                    ...members.map((m) => FilterChip(
                          label: Text(m.name.split(' ').first,
                              style: GoogleFonts.inter(fontSize: 12)),
                          selected: _selectedMemberIds.contains(m.userId),
                          onSelected: (v) => setState(() {
                            if (v) {
                              _selectedMemberIds = [
                                ..._selectedMemberIds,
                                m.userId
                              ];
                            } else {
                              _selectedMemberIds = _selectedMemberIds
                                  .where((id) => id != m.userId)
                                  .toList();
                            }
                          }),
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                        )),
                  ],
                ),
                if (_selectedMemberIds.isNotEmpty &&
                    _priceCtrl.text.isNotEmpty)
                  _SplitPreview(
                    priceText: _priceCtrl.text,
                    count: _selectedMemberIds.length,
                    isDark: isDark,
                    t: t,
                  ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          final nav = Navigator.of(context);
                          final price = double.tryParse(
                              _priceCtrl.text.replaceAll(',', '.'));
                          if (editing == null) {
                            await ref
                                .read(shoppingProvider.notifier)
                                .addItem(
                                  name: _nameCtrl.text.trim(),
                                  quantity:
                                      int.tryParse(_qtyCtrl.text) ?? 1,
                                  price: price,
                                  splitBetween: _selectedMemberIds,
                                  addedBy: authState.user?.uid ?? '',
                                );
                          } else {
                            await ref
                                .read(shoppingProvider.notifier)
                                .updateItem(
                                  itemId: editing.id,
                                  name: _nameCtrl.text.trim(),
                                  quantity:
                                      int.tryParse(_qtyCtrl.text) ?? 1,
                                  price: price,
                                  splitBetween: _selectedMemberIds,
                                );
                          }
                          if (!mounted) return;
                          final isPro = ref.read(proProvider).valueOrNull ?? false;
                          nav.pop();
                          InterstitialAdService.showIfReady(isPro: isPro);
                        },
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(t('common.save'),
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SplitPreview extends StatelessWidget {
  final String priceText;
  final int count;
  final bool isDark;
  final String Function(String) t;

  const _SplitPreview({
    required this.priceText,
    required this.count,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(priceText.replaceAll(',', '.'));
    if (price == null || price <= 0) return const SizedBox.shrink();
    final perPerson = price / count;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            'R\$ ${price.toStringAsFixed(2)} ÷ $count = R\$ ${perPerson.toStringAsFixed(2)} ${t('shopping.perPerson')}',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ItemList extends ConsumerWidget {
  final List<ShoppingItemModel> items;
  final bool isDark;
  final String Function(String) t;
  final void Function(ShoppingItemModel)? onEdit;
  final void Function(ShoppingItemModel)? onDelete;

  const _ItemList({
    required this.items,
    required this.isDark,
    required this.t,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (items.isEmpty) {
      return EmptyState(
          icon: Icons.shopping_cart_outlined, message: t('shopping.noItems'));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(shoppingProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return _ShoppingItemCard(
            item: item,
            isDark: isDark,
            t: t,
            onToggle: () => ref
                .read(shoppingProvider.notifier)
                .toggleBought(item.id, !item.bought,
                    boughtBy: authState.user?.uid),
            onEdit: onEdit != null ? () => onEdit!(item) : null,
            onDelete: onDelete != null ? () => onDelete!(item) : null,
          );
        },
      ),
    );
  }
}

class _BoughtList extends ConsumerWidget {
  final List<ShoppingItemModel> items;
  final bool isDark;
  final String Function(String) t;
  final void Function(ShoppingItemModel)? onEdit;
  final void Function(ShoppingItemModel)? onDelete;

  const _BoughtList({
    required this.items,
    required this.isDark,
    required this.t,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? [];

    if (items.isEmpty) {
      return EmptyState(
          icon: Icons.check_circle_outline, message: t('shopping.noBoughtItems'));
    }

    final Map<String, double> personTotals = {};
    double totalWithPrice = 0;

    for (final item in items) {
      if (item.price != null && item.price! > 0) {
        totalWithPrice += item.price!;
        if (item.splitBetween.isNotEmpty) {
          final share = item.price! / item.splitBetween.length;
          for (final uid in item.splitBetween) {
            personTotals[uid] = (personTotals[uid] ?? 0) + share;
          }
        }
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(shoppingProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (personTotals.isNotEmpty) ...[
            _SplitSummaryCard(
              totalWithPrice: totalWithPrice,
              personTotals: personTotals,
              members: members,
              isDark: isDark,
              t: t,
            ),
            const SizedBox(height: 12),
          ],
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ShoppingItemCard(
                  item: item,
                  isDark: isDark,
                  t: t,
                  onToggle: () => ref
                      .read(shoppingProvider.notifier)
                      .toggleBought(item.id, !item.bought,
                          boughtBy: authState.user?.uid),
                  onEdit: onEdit != null ? () => onEdit!(item) : null,
                  onDelete: onDelete != null ? () => onDelete!(item) : null,
                ),
              )),
        ],
      ),
    );
  }
}

class _SplitSummaryCard extends StatelessWidget {
  final double totalWithPrice;
  final Map<String, double> personTotals;
  final List<MemberModel> members;
  final bool isDark;
  final String Function(String) t;

  const _SplitSummaryCard({
    required this.totalWithPrice,
    required this.personTotals,
    required this.members,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final nameFor = {for (final m in members) m.userId: m.name.split(' ').first};

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                t('shopping.splitSummary'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                'R\$ ${totalWithPrice.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...personTotals.entries.map((e) {
            final name = nameFor[e.key] ?? e.key.substring(0, 6);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  _MiniAvatar(name: name),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foreground)),
                  ),
                  Text(
                    'R\$ ${e.value.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.foregroundDark
                            : AppColors.foreground),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String name;
  const _MiniAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  final ShoppingItemModel item;
  final bool isDark;
  final String Function(String) t;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ShoppingItemCard({
    required this.item,
    required this.isDark,
    required this.t,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrice = item.price != null && item.price! > 0;
    final hasSplit = item.splitBetween.isNotEmpty && hasPrice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.bought ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.bought
                      ? AppColors.success
                      : (isDark ? AppColors.borderDark : AppColors.border),
                  width: 1.5,
                ),
              ),
              child: item.bought
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: item.bought
                        ? (isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForeground)
                        : (isDark
                            ? AppColors.foregroundDark
                            : AppColors.foreground),
                    decoration:
                        item.bought ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (hasPrice) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'R\$ ${item.price!.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasSplit)
                        Text(
                          '  ÷ ${item.splitBetween.length} = R\$ ${item.pricePerPerson.toStringAsFixed(2)}/pessoa',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (item.quantity > 1) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('x${item.quantity}',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.foregroundDark
                          : AppColors.foreground)),
            ),
            const SizedBox(width: 4),
          ],
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 18,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForeground),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.destructive),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

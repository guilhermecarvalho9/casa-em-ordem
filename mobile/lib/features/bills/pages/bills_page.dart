import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../permissions/providers/permissions_provider.dart';
import '../models/bill_model.dart';
import '../providers/bills_provider.dart';

class BillsPage extends ConsumerStatefulWidget {
  const BillsPage({super.key});

  @override
  ConsumerState<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends ConsumerState<BillsPage>
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
    final billsAsync = ref.watch(billsProvider);
    final perms = ref.watch(permissionsProvider);
    final myRole = ref.watch(authProvider).houseMembership?.role ?? 'guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final pending = billsAsync.valueOrNull?.where((b) => !b.paid).toList() ?? [];
    final paid = billsAsync.valueOrNull?.where((b) => b.paid).toList() ?? [];
    final totalPending = pending.fold<double>(0, (s, b) => s + b.amount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          if (billsAsync.valueOrNull?.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFFF5A623)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('bills.total'),
                            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                        Text(
                          'R\$ ${totalPending.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${pending.length} ${t('bills.pending')}',
                          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                      Text('${paid.length} ${t('bills.paid')}',
                          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          Container(
            color: isDark ? AppColors.cardDark : AppColors.card,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(text: '${t('bills.pending')} (${pending.length})'),
                Tab(text: '${t('bills.paid')} (${paid.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BillList(
                  bills: pending,
                  isDark: isDark,
                  t: t,
                  onEdit: perms.can('bills.add', myRole)
                      ? (bill) => _showBillForm(context, isDark, t, editing: bill) : null,
                  onDelete: perms.can('bills.delete', myRole)
                      ? (bill) => _confirmDelete(context, bill, t) : null,
                  canMarkPaid: perms.can('bills.markPaid', myRole),
                ),
                _BillList(
                  bills: paid,
                  isDark: isDark,
                  t: t,
                  onEdit: perms.can('bills.add', myRole)
                      ? (bill) => _showBillForm(context, isDark, t, editing: bill) : null,
                  onDelete: perms.can('bills.delete', myRole)
                      ? (bill) => _confirmDelete(context, bill, t) : null,
                  canMarkPaid: perms.can('bills.markPaid', myRole),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: perms.can('bills.add', myRole)
          ? FloatingActionButton(
              onPressed: () => _showBillForm(context, isDark, t),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _confirmDelete(BuildContext context, BillModel bill, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.confirm')),
        content: Text('${t('common.deleteConfirm')} "${bill.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(billsProvider.notifier).deleteBill(bill.id);
            },
            child: Text(t('common.delete'), style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showBillForm(BuildContext context, bool isDark, String Function(String) t, {BillModel? editing}) {
    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final amountCtrl = TextEditingController(
        text: editing != null ? editing.amount.toStringAsFixed(2) : '');
    String selectedCategory = editing?.category ?? 'other';
    final formKey = GlobalKey<FormState>();

    DateTime initialDate = DateTime.now().add(const Duration(days: 7));
    if (editing != null) {
      final parsed = DateTime.tryParse(editing.dueDate);
      if (parsed != null) initialDate = parsed;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final members = ref.read(membersProvider).valueOrNull ?? [];
        final authState = ref.read(authProvider);
        final allMemberIds = members.map((m) => m.userId).toList();
        List<String> selectedMembers = editing?.splitBetween.isNotEmpty == true
            ? List.from(editing!.splitBetween)
            : List.from(allMemberIds);
        DateTime selectedDueDate = initialDate;

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
                    Text(
                      editing == null ? t('bills.add') : t('common.edit'),
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
                      controller: amountCtrl,
                      decoration: InputDecoration(labelText: t('bills.amount'), prefixText: 'R\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty == true ? t('common.required') : null,
                    ),
                    const SizedBox(height: 12),
                    // Date picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState2(() => selectedDueDate = picked);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: t('bills.dueDate'),
                          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        child: Text(
                          '${selectedDueDate.day.toString().padLeft(2, '0')}/${selectedDueDate.month.toString().padLeft(2, '0')}/${selectedDueDate.year}',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: t('bills.category')),
                      items: ['rent', 'utilities', 'internet', 'other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(t('bills.category.$c'))))
                          .toList(),
                      onChanged: (v) => setState2(() => selectedCategory = v ?? 'other'),
                    ),
                    const SizedBox(height: 16),
                    if (members.isNotEmpty) ...[
                      Text(t('bills.splitSelect'),
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: Text(t('bills.selectAll'),
                                style: GoogleFonts.inter(fontSize: 12)),
                            selected: selectedMembers.length == members.length,
                            onSelected: (v) => setState2(() {
                              selectedMembers = v
                                  ? members.map((m) => m.userId).toList()
                                  : [];
                            }),
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                          ),
                          ...members.map((m) => FilterChip(
                            label: Text(m.name, style: GoogleFonts.inter(fontSize: 12)),
                            selected: selectedMembers.contains(m.userId),
                            onSelected: (v) => setState2(() {
                              if (v) {
                                selectedMembers = [...selectedMembers, m.userId];
                              } else {
                                selectedMembers = selectedMembers
                                    .where((id) => id != m.userId)
                                    .toList();
                              }
                            }),
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final amount = double.tryParse(
                              amountCtrl.text.replaceAll(',', '.')) ?? 0;
                          final dueDateStr = selectedDueDate.toIso8601String().split('T').first;
                          if (editing == null) {
                            await ref.read(billsProvider.notifier).addBill(
                              title: titleCtrl.text.trim(),
                              amount: amount,
                              dueDate: dueDateStr,
                              category: selectedCategory,
                              splitBetween: selectedMembers,
                              createdBy: authState.user?.uid ?? '',
                            );
                          } else {
                            await ref.read(billsProvider.notifier).updateBill(
                              billId: editing.id,
                              title: titleCtrl.text.trim(),
                              amount: amount,
                              dueDate: dueDateStr,
                              category: selectedCategory,
                              splitBetween: selectedMembers,
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
        );
      },
    );
  }
}

class _BillList extends ConsumerWidget {
  final List<BillModel> bills;
  final bool isDark;
  final String Function(String) t;
  final void Function(BillModel)? onEdit;
  final void Function(BillModel)? onDelete;
  final bool canMarkPaid;

  const _BillList({
    required this.bills,
    required this.isDark,
    required this.t,
    this.onEdit,
    this.onDelete,
    this.canMarkPaid = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (bills.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: t('bills.noBills'),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(billsProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final bill = bills[i];
          return Container(
            padding: const EdgeInsets.all(16),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bill.title,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 14,
                                  color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                          const SizedBox(height: 2),
                          Text(
                            _categoryLabel(bill.category),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ ${bill.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 16,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                        ),
                        if (bill.splitBetween.length > 1)
                          Text(
                            'R\$ ${bill.perPerson.toStringAsFixed(2)} ${t('bills.perPerson')}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusBadge(
                      label: bill.paid ? t('bills.paid') : t('bills.pending'),
                      type: bill.paid ? BadgeType.success : BadgeType.warning,
                    ),
                    const SizedBox(width: 8),
                    if (!bill.paid) _DueDateBadge(dueDate: bill.dueDate, t: t),
                    const Spacer(),
                    if (canMarkPaid && !bill.paid)
                      TextButton(
                        onPressed: () => ref.read(billsProvider.notifier)
                            .togglePaid(bill.id, true, paidBy: authState.user?.uid, bill: bill),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: Text(t('bills.markPaid'),
                            style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      )
                    else if (canMarkPaid && bill.paid)
                      TextButton(
                        onPressed: () => ref.read(billsProvider.notifier).togglePaid(bill.id, false, bill: bill),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: Text(t('bills.markUnpaid'),
                            style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12)),
                      ),
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 18,
                            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                        onPressed: () => onEdit!(bill),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                        onPressed: () => onDelete!(bill),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'rent': return t('bills.category.rent');
      case 'utilities': return t('bills.category.utilities');
      case 'internet': return t('bills.category.internet');
      default: return t('bills.category.other');
    }
  }
}

class _DueDateBadge extends StatelessWidget {
  final String dueDate;
  final String Function(String) t;

  const _DueDateBadge({required this.dueDate, required this.t});

  @override
  Widget build(BuildContext context) {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return const SizedBox.shrink();

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(due.year, due.month, due.day);
    final diff = dueOnly.difference(todayOnly).inDays;

    Color color;
    String label;

    if (diff < 0) {
      color = AppColors.destructive;
      label = t('bills.overdue');
    } else if (diff == 0) {
      color = Colors.orange;
      label = t('bills.dueToday');
    } else if (diff <= 3) {
      color = Colors.orange;
      label = '${t('bills.dueSoon')} $diff d';
    } else {
      color = AppColors.mutedForeground;
      label = '${due.day.toString().padLeft(2, '0')}/${due.month.toString().padLeft(2, '0')}/${due.year}';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final pending = billsAsync.valueOrNull?.where((b) => !b.paid).toList() ?? [];
    final paid = billsAsync.valueOrNull?.where((b) => b.paid).toList() ?? [];
    final totalPending = pending.fold<double>(0, (s, b) => s + b.amount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          // Summary card
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
                _BillList(bills: pending, isDark: isDark, t: t),
                _BillList(bills: paid, isDark: isDark, t: t),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBill(context, isDark, t),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddBill(BuildContext context, bool isDark, String Function(String) t) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCategory = 'other';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final formKey = GlobalKey<FormState>();

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
        List<String> selectedMembers = List.from(allMemberIds);

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
                    Text(t('bills.add'),
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
                      controller: amountCtrl,
                      decoration: InputDecoration(labelText: t('bills.amount'), prefixText: 'R\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Categoria'),
                      items: ['rent', 'utilities', 'internet', 'other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(t('bills.category.$c'))))
                          .toList(),
                      onChanged: (v) => setState2(() => selectedCategory = v ?? 'other'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final amount = double.tryParse(
                              amountCtrl.text.replaceAll(',', '.')) ?? 0;
                          await ref.read(billsProvider.notifier).addBill(
                            title: titleCtrl.text.trim(),
                            amount: amount,
                            dueDate: selectedDate.toIso8601String().split('T').first,
                            category: selectedCategory,
                            splitBetween: selectedMembers,
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

  const _BillList({required this.bills, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (bills.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: t('bills.noBills'),
      );
    }

    return ListView.separated(
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
                          'R\$ ${bill.perPerson.toStringAsFixed(2)} / pessoa',
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
                  const Spacer(),
                  if (!bill.paid)
                    TextButton(
                      onPressed: () => ref.read(billsProvider.notifier)
                          .togglePaid(bill.id, true, paidBy: authState.user?.id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: Text(t('bills.markPaid'),
                          style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    )
                  else
                    TextButton(
                      onPressed: () => ref.read(billsProvider.notifier).togglePaid(bill.id, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: Text(t('bills.markUnpaid'),
                          style: GoogleFonts.inter(color: AppColors.mutedForeground, fontSize: 12)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                    onPressed: () => ref.read(billsProvider.notifier).deleteBill(bill.id),
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

  String _categoryLabel(String category) {
    switch (category) {
      case 'rent': return t('bills.category.rent');
      case 'utilities': return t('bills.category.utilities');
      case 'internet': return t('bills.category.internet');
      default: return t('bills.category.other');
    }
  }
}

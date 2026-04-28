import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../models/shopping_model.dart';
import '../providers/shopping_provider.dart';

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
    final shoppingAsync = ref.watch(shoppingProvider);
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
              unselectedLabelColor: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(text: '${t('shopping.toBuy')} (${toBuy.length})'),
                Tab(text: '${t('shopping.bought')} (${bought.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ItemList(items: toBuy, isDark: isDark, t: t),
                _BoughtList(items: bought, isDark: isDark, t: t),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddItemSheet(isDark: isDark, t: t),
    );
  }
}

// Stateful sheet so member selection state works correctly
class _AddItemSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final String Function(String) t;

  const _AddItemSheet({required this.isDark, required this.t});

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  List<String> _selectedMemberIds = [];
  bool _loading = false;

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
    final members = ref.watch(membersProvider).valueOrNull ?? [];
    final authState = ref.read(authProvider);

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
            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('shopping.add'),
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, fontSize: 18,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: fieldDecor('Item'),
                validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
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
                      decoration: fieldDecor(t('shopping.price')).copyWith(prefixText: 'R\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                              _selectedMemberIds = [..._selectedMemberIds, m.userId];
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
                if (_selectedMemberIds.isNotEmpty && _priceCtrl.text.isNotEmpty)
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          final nav = Navigator.of(context);
                          final price = double.tryParse(
                              _priceCtrl.text.replaceAll(',', '.'));
                          await ref.read(shoppingProvider.notifier).addItem(
                                name: _nameCtrl.text.trim(),
                                quantity: int.tryParse(_qtyCtrl.text) ?? 1,
                                price: price,
                                splitBetween: _selectedMemberIds,
                                addedBy: authState.user?.uid ?? '',
                              );
                          if (!mounted) return;
                          nav.pop();
                        },
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(t('common.save'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
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

  const _ItemList({required this.items, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (items.isEmpty) {
      return EmptyState(icon: Icons.shopping_cart_outlined, message: t('shopping.noItems'));
    }

    return ListView.separated(
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
              .toggleBought(item.id, !item.bought, boughtBy: authState.user?.uid),
          onDelete: () => ref.read(shoppingProvider.notifier).deleteItem(item.id),
        );
      },
    );
  }
}

class _BoughtList extends ConsumerWidget {
  final List<ShoppingItemModel> items;
  final bool isDark;
  final String Function(String) t;

  const _BoughtList({required this.items, required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? [];

    if (items.isEmpty) {
      return EmptyState(icon: Icons.check_circle_outline, message: t('shopping.noBoughtItems'));
    }

    // Build per-person split map
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

    return ListView(
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
        ...items.asMap().entries.map((entry) {
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ShoppingItemCard(
              item: item,
              isDark: isDark,
              t: t,
              onToggle: () => ref
                  .read(shoppingProvider.notifier)
                  .toggleBought(item.id, !item.bought, boughtBy: authState.user?.uid),
              onDelete: () => ref.read(shoppingProvider.notifier).deleteItem(item.id),
            ),
          );
        }),
      ],
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
              const Icon(Icons.calculate_rounded, size: 16, color: AppColors.primary),
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
                  color: AppColors.primary,
                ),
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
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                      ),
                    ),
                  ),
                  Text(
                    'R\$ ${e.value.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                    ),
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
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  final ShoppingItemModel item;
  final bool isDark;
  final String Function(String) t;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ShoppingItemCard({
    required this.item,
    required this.isDark,
    required this.t,
    required this.onToggle,
    required this.onDelete,
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
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 22, height: 22,
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
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: item.bought
                        ? (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)
                        : (isDark ? AppColors.foregroundDark : AppColors.foreground),
                    decoration: item.bought ? TextDecoration.lineThrough : null,
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
                      if (hasSplit) ...[
                        Text(
                          '  ÷ ${item.splitBetween.length} = R\$ ${item.pricePerPerson.toStringAsFixed(2)}/pessoa',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (item.quantity > 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('x${item.quantity}',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
            ),
            const SizedBox(width: 4),
          ],
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

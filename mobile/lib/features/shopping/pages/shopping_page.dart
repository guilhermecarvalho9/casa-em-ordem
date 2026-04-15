import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
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
                _ItemList(items: bought, isDark: isDark, t: t),
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
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
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
                Text(t('shopping.add'),
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 18,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: 'Item'),
                  validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qtyCtrl,
                  decoration: InputDecoration(labelText: t('shopping.quantity')),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await ref.read(shoppingProvider.notifier).addItem(
                        name: nameCtrl.text.trim(),
                        quantity: int.tryParse(qtyCtrl.text) ?? 1,
                        addedBy: authState.user?.uid ?? '',
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(shoppingProvider.notifier)
                    .toggleBought(item.id, !item.bought, boughtBy: authState.user?.uid),
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: item.bought ? AppColors.success : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.bought ? AppColors.success : (isDark ? AppColors.borderDark : AppColors.border),
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
                child: Text(
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
              ),
              if (item.quantity > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.secondaryDark : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('x${item.quantity}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                onPressed: () => ref.read(shoppingProvider.notifier).deleteItem(item.id),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }
}

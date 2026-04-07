import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_model.dart';
import '../../auth/providers/auth_provider.dart';

class BillsNotifier extends StateNotifier<AsyncValue<List<BillModel>>> {
  BillsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final data = await _supabase
          .from('bills')
          .select()
          .eq('house_id', _houseId)
          .order('due_date');
      state = AsyncValue.data(
        (data as List).map((b) => BillModel.fromMap(b)).toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> addBill({
    required String title,
    required double amount,
    required String dueDate,
    required String category,
    required List<String> splitBetween,
    required String createdBy,
  }) async {
    try {
      await _supabase.from('bills').insert({
        'house_id': _houseId,
        'title': title,
        'amount': amount,
        'due_date': dueDate,
        'category': category,
        'split_between': splitBetween,
        'paid': false,
        'created_by': createdBy,
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> togglePaid(String billId, bool paid, {String? paidBy}) async {
    try {
      await _supabase.from('bills').update({
        'paid': paid,
        'paid_by': paid ? paidBy : null,
      }).eq('id', billId);
      await load();
    } catch (_) {}
  }

  Future<String?> deleteBill(String billId) async {
    try {
      await _supabase.from('bills').delete().eq('id', billId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final billsProvider = StateNotifierProvider<BillsNotifier, AsyncValue<List<BillModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final houseId = authState.currentHouse?.id ?? '';
  return BillsNotifier(houseId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../../auth/providers/auth_provider.dart';

class BillsNotifier extends StateNotifier<AsyncValue<List<BillModel>>> {
  BillsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('bills');

  Future<void> load() async {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final snap = await _col.orderBy('dueDate').get();
      state = AsyncValue.data(
        snap.docs
            .map((d) => BillModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList(),
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
      await _col.add({
        'houseId': _houseId,
        'title': title,
        'amount': amount,
        'dueDate': dueDate,
        'category': category,
        'splitBetween': splitBetween,
        'paid': false,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> togglePaid(String billId, bool paid, {String? paidBy}) async {
    try {
      await _col.doc(billId).update({
        'paid': paid,
        'paidBy': paid ? paidBy : null,
      });
      await load();
    } catch (_) {}
  }

  Future<String?> deleteBill(String billId) async {
    try {
      await _col.doc(billId).delete();
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final billsProvider =
    StateNotifierProvider<BillsNotifier, AsyncValue<List<BillModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return BillsNotifier(houseId);
});

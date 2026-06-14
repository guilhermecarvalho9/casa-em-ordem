import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  PurchaseService._();
  static final instance = PurchaseService._();

  static const monthlyId = 'homio_pro_monthly';
  static const annualId = 'homio_pro_annual';

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  ProductDetails? _monthly;
  ProductDetails? _annual;

  ProductDetails? get monthly => _monthly;
  ProductDetails? get annual => _annual;

  String get monthlyPrice => _monthly?.price ?? 'R\$ 9,90';
  String get annualPrice => _annual?.price ?? 'R\$ 99,90';

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    final response = await _iap.queryProductDetails({monthlyId, annualId});
    for (final p in response.productDetails) {
      if (p.id == monthlyId) _monthly = p;
      if (p.id == annualId) _annual = p;
    }
  }

  void listenPurchases(String houseId) {
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen((purchases) {
      for (final p in purchases) {
        _handlePurchase(p, houseId);
      }
    });
  }

  void dispose() => _sub?.cancel();

  Future<bool> buyMonthly() => _buy(_monthly);
  Future<bool> buyAnnual() => _buy(_annual);

  Future<bool> _buy(ProductDetails? product) async {
    if (product == null) return false;
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> _handlePurchase(PurchaseDetails p, String houseId) async {
    if (p.status == PurchaseStatus.pending) return;

    if (p.status == PurchaseStatus.purchased ||
        p.status == PurchaseStatus.restored) {
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(houseId)
          .update({'isPro': true});
      await _iap.completePurchase(p);
    } else if (p.status == PurchaseStatus.error ||
        p.status == PurchaseStatus.canceled) {
      await _iap.completePurchase(p);
    }
  }
}

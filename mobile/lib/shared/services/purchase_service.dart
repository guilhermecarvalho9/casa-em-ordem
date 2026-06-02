import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  PurchaseService._();
  static final instance = PurchaseService._();

  static const _productId = 'br.com.hg2tecnologia.homio.pro.monthly';

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  bool get isAvailable => _product != null;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    final response = await _iap.queryProductDetails({_productId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }
  }

  void listenPurchases(String houseId) {
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchase(purchase, houseId);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<bool> buy() async {
    if (_product == null) return false;
    final param = PurchaseParam(productDetails: _product!);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

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

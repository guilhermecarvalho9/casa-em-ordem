import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/house_notification_service.dart';
import '../../../core/services/cloudinary_service.dart';

class InventoryNotifier extends StateNotifier<AsyncValue<List<InventoryItemModel>>> {
  InventoryNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('inventory');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('createdAt', descending: true).snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) => InventoryItemModel.fromMap(
                  d.id, _houseId, d.data() as Map<String, dynamic>))
              .toList(),
        );
      },
      onError: (e, s) => state = AsyncValue.error(e, s),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<String?> addItem({
    required String name,
    required String category,
    required double value,
    required String ownerId,
    required String ownerName,
    required String createdBy,
    String creatorName = '',
    String? description,
    File? photo,
  }) async {
    try {
      String? photoUrl;
      if (photo != null) {
        photoUrl = await _uploadPhoto(photo);
      }

      await _col.add({
        'name': name,
        'category': category,
        'value': value,
        'ownerId': ownerId,
        'ownerName': ownerName,
        if (description != null && description.isNotEmpty) 'description': description,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      HouseNotificationService.inventoryItemAdded(
        houseId: _houseId,
        createdBy: createdBy,
        creatorName: creatorName.isNotEmpty ? creatorName : ownerName,
        itemName: name,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteItem(String itemId, String? photoUrl) async {
    try {
      await _col.doc(itemId).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateItem({
    required String itemId,
    required String name,
    required String category,
    required double value,
    required String ownerId,
    required String ownerName,
    String? description,
    File? newPhoto,
    String? existingPhotoUrl,
  }) async {
    try {
      String? photoUrl = existingPhotoUrl;
      if (newPhoto != null) {
        photoUrl = await _uploadPhoto(newPhoto);
      }

      await _col.doc(itemId).update({
        'name': name,
        'category': category,
        'value': value,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'description': description ?? '',
        if (photoUrl != null) 'photoUrl': photoUrl else 'photoUrl': FieldValue.delete(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refresh() async {
    _sub?.cancel();
    _sub = null;
    _subscribe();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<String> _uploadPhoto(File photo) async {
    return CloudinaryService.uploadImage(photo);
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryItemModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return InventoryNotifier(houseId);
});

import 'package:cloud_firestore/cloud_firestore.dart';

class HouseNotificationService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _col(String houseId) =>
      _db.collection('houses').doc(houseId).collection('notifications');

  static Future<void> _write(
    String houseId, {
    required String type,
    required String title,
    required String body,
    required String createdBy,
  }) async {
    try {
      await _col(houseId).add({
        'type': type,
        'title': title,
        'body': body,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'seenBy': <String>[],
      });
    } catch (_) {}
  }

  static Future<void> eventAdded({
    required String houseId,
    required String createdBy,
    required String creatorName,
    required String eventTitle,
  }) =>
      _write(
        houseId,
        type: 'event_added',
        title: 'Novo evento na casa',
        body: '$creatorName adicionou "$eventTitle"',
        createdBy: createdBy,
      );

  static Future<void> billAdded({
    required String houseId,
    required String createdBy,
    required String creatorName,
    required String billTitle,
    required double amount,
  }) =>
      _write(
        houseId,
        type: 'bill_added',
        title: 'Nova conta adicionada',
        body: '$creatorName adicionou a conta "$billTitle"',
        createdBy: createdBy,
      );

  static Future<void> billSplitAdded({
    required String houseId,
    required String createdBy,
    required String creatorName,
    required String billTitle,
  }) =>
      _write(
        houseId,
        type: 'bill_split',
        title: 'Você foi incluído em uma conta',
        body: '$creatorName incluiu você na divisão de "$billTitle"',
        createdBy: createdBy,
      );

  static Future<void> shoppingItemAdded({
    required String houseId,
    required String createdBy,
    required String creatorName,
    required String itemName,
  }) =>
      _write(
        houseId,
        type: 'shopping_added',
        title: 'Item adicionado ao mercado',
        body: '$creatorName adicionou "$itemName" à lista',
        createdBy: createdBy,
      );

  static Future<void> inventoryItemAdded({
    required String houseId,
    required String createdBy,
    required String creatorName,
    required String itemName,
  }) =>
      _write(
        houseId,
        type: 'inventory_added',
        title: 'Novo item no inventário',
        body: '$creatorName adicionou "$itemName" ao inventário',
        createdBy: createdBy,
      );

  static Future<void> taskCompleted({
    required String houseId,
    required String completedBy,
    required String completedByName,
    required String taskTitle,
  }) =>
      _write(
        houseId,
        type: 'task_done',
        title: 'Tarefa concluída',
        body: '$completedByName concluiu "$taskTitle"',
        createdBy: completedBy,
      );

  static Future<void> markSeen(
      String houseId, String notifId, String userId) async {
    try {
      await _db
          .collection('houses')
          .doc(houseId)
          .collection('notifications')
          .doc(notifId)
          .update({
        'seenBy': FieldValue.arrayUnion([userId]),
      });
    } catch (_) {}
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/house_notification.dart';
import '../../features/auth/providers/auth_provider.dart';

final notificationsProvider =
    StreamProvider<List<HouseNotification>>((ref) {
  final auth = ref.watch(authProvider);
  final houseId = auth.currentHouse?.id;
  final uid = auth.user?.uid;

  if (houseId == null || houseId.isEmpty || uid == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('houses')
      .doc(houseId)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => HouseNotification.fromMap(
              d.id, d.data()))
          .where((n) => n.createdBy != uid && !n.seenBy.contains(uid))
          .toList());
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).valueOrNull?.length ?? 0;
});

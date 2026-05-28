import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';

/// Watches the house document for `isPro: true`.
/// When in-app purchase is implemented, set this field to true in Firestore
/// after a successful subscription.
final proProvider = StreamProvider<bool>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id;
  if (houseId == null || houseId.isEmpty) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('houses')
      .doc(houseId)
      .snapshots()
      .map((snap) => snap.data()?['isPro'] as bool? ?? false);
});

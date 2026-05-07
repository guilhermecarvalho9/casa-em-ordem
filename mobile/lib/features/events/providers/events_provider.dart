import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../../auth/providers/auth_provider.dart';

class EventsNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  EventsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('events');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('eventDate').snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) =>
                  EventModel.fromMap(d.id, d.data() as Map<String, dynamic>))
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

  Future<String?> addEvent({
    required String title,
    String? description,
    required String eventDate,
    String? eventTime,
    String? location,
    required String createdBy,
  }) async {
    try {
      await _col.add({
        'houseId': _houseId,
        'title': title,
        if (description != null) 'description': description,
        'eventDate': eventDate,
        if (eventTime != null) 'eventTime': eventTime,
        if (location != null) 'location': location,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteEvent(String eventId) async {
    try {
      await _col.doc(eventId).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final eventsProvider =
    StateNotifierProvider<EventsNotifier, AsyncValue<List<EventModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return EventsNotifier(houseId);
});

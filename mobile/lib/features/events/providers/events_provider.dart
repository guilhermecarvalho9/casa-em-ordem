import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../../auth/providers/auth_provider.dart';

class EventsNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  EventsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('events');

  Future<void> load() async {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final snap = await _col.orderBy('eventDate').get();
      state = AsyncValue.data(
        snap.docs
            .map((d) =>
                EventModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
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
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteEvent(String eventId) async {
    try {
      await _col.doc(eventId).delete();
      await load();
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

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/house_notification_service.dart';

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
        final base = snap.docs
            .map((d) => EventModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(_expand(base));
      },
      onError: (e, s) => state = AsyncValue.error(e, s),
    );
  }

  static List<EventModel> _expand(List<EventModel> base) {
    final result = <EventModel>[];
    final cutoff = DateTime.now().add(const Duration(days: 366));

    for (final e in base) {
      result.add(e);
      if (e.recurring == null) continue;

      DateTime end = cutoff;
      if (e.recurringUntil != null) {
        final parsed = DateTime.tryParse(e.recurringUntil!);
        if (parsed != null && parsed.isBefore(cutoff)) end = parsed;
      }

      DateTime cursor = DateTime.parse(e.eventDate);
      for (int i = 0; i < 366; i++) {
        cursor = _nextDate(cursor, e.recurring!);
        if (cursor.isAfter(end)) break;
        final dateStr = _fmt(cursor);
        result.add(e.asVirtualOccurrence('${e.id}_$dateStr', dateStr));
      }
    }

    return result;
  }

  static DateTime _nextDate(DateTime from, String recurring) {
    switch (recurring) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'biweekly':
        return from.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return from.add(const Duration(days: 7));
    }
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
    String? eventEndTime,
    String? location,
    required String createdBy,
    String creatorName = '',
    String? recurring,
    String? recurringUntil,
  }) async {
    try {
      await _col.add({
        'houseId': _houseId,
        'title': title,
        if (description != null) 'description': description,
        'eventDate': eventDate,
        if (eventTime != null) 'eventTime': eventTime,
        if (eventEndTime != null) 'eventEndTime': eventEndTime,
        if (location != null) 'location': location,
        'createdBy': createdBy,
        if (recurring != null) 'recurring': recurring,
        if (recurringUntil != null) 'recurringUntil': recurringUntil,
        'createdAt': FieldValue.serverTimestamp(),
      });
      HouseNotificationService.eventAdded(
        houseId: _houseId,
        createdBy: createdBy,
        creatorName: creatorName.isNotEmpty ? creatorName : 'Alguém',
        eventTitle: title,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateEvent({
    required String eventId,
    required String title,
    String? description,
    required String eventDate,
    String? eventTime,
    String? eventEndTime,
    String? location,
    String? recurring,
    String? recurringUntil,
  }) async {
    try {
      await _col.doc(eventId).update({
        'title': title,
        if (description != null) 'description': description else 'description': FieldValue.delete(),
        'eventDate': eventDate,
        if (eventTime != null) 'eventTime': eventTime else 'eventTime': FieldValue.delete(),
        if (eventEndTime != null) 'eventEndTime': eventEndTime else 'eventEndTime': FieldValue.delete(),
        if (location != null) 'location': location else 'location': FieldValue.delete(),
        if (recurring != null) 'recurring': recurring else 'recurring': FieldValue.delete(),
        if (recurringUntil != null) 'recurringUntil': recurringUntil else 'recurringUntil': FieldValue.delete(),
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

  Future<void> refresh() async {
    _sub?.cancel();
    _sub = null;
    _subscribe();
    await Future.delayed(const Duration(milliseconds: 600));
  }
}

final eventsProvider =
    StateNotifierProvider<EventsNotifier, AsyncValue<List<EventModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return EventsNotifier(houseId);
});

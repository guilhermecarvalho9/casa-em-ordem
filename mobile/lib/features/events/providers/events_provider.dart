import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../../auth/providers/auth_provider.dart';

class EventsNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  EventsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final data = await _supabase
          .from('events')
          .select()
          .eq('house_id', _houseId)
          .order('event_date');
      state = AsyncValue.data(
        (data as List).map((e) => EventModel.fromMap(e)).toList(),
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
      await _supabase.from('events').insert({
        'house_id': _houseId,
        'title': title,
        'description': description,
        'event_date': eventDate,
        'event_time': eventTime,
        'location': location,
        'created_by': createdBy,
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<EventModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final houseId = authState.currentHouse?.id ?? '';
  return EventsNotifier(houseId);
});

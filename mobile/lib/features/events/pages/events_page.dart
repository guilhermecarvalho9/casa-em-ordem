import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../app/providers/app_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final allEvents = eventsAsync.valueOrNull ?? [];
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final dayEvents = allEvents.where((e) => e.eventDate == selectedDateStr).toList();

    Map<DateTime, List<EventModel>> eventMap = {};
    for (final e in allEvents) {
      try {
        final d = DateTime.parse(e.eventDate);
        final key = DateTime(d.year, d.month, d.day);
        eventMap[key] = [...(eventMap[key] ?? []), e];
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          Container(
            color: isDark ? AppColors.cardDark : AppColors.card,
            child: TableCalendar<EventModel>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              eventLoader: (d) {
                final key = DateTime(d.year, d.month, d.day);
                return eventMap[key] ?? [];
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: GoogleFonts.inter(
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                weekendTextStyle: GoogleFonts.inter(
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, fontSize: 15,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(
                    fontSize: 12, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                weekendStyle: GoogleFonts.inter(
                    fontSize: 12, color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
              ),
            ),
          ),
          Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  DateFormat('d MMMM', appState.language == 'pt' ? 'pt_BR' : 'en_US')
                      .format(_selectedDay),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, fontSize: 15,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                  ),
                ),
                const Spacer(),
                if (dayEvents.isNotEmpty)
                  Text('${dayEvents.length} ${t('events.eventCount')}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
              ],
            ),
          ),
          Expanded(
            child: dayEvents.isEmpty
                ? EmptyState(icon: Icons.event_outlined, message: t('events.noEvents'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dayEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _EventCard(
                      event: dayEvents[i],
                      isDark: isDark,
                      onDelete: () => ref.read(eventsProvider.notifier).deleteEvent(dayEvents[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEvent(context, isDark, t),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddEvent(BuildContext context, bool isDark, String Function(String) t) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final authState = ref.read(authProvider);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('events.add'),
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 18,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: t('common.title')),
                  validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: t('common.description')),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                      labelText: t('events.location'),
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t('events.selectedDate')} ${DateFormat('dd/MM/yyyy').format(_selectedDay)}',
                  style: GoogleFonts.inter(fontSize: 12,
                      color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await ref.read(eventsProvider.notifier).addEvent(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        eventDate: DateFormat('yyyy-MM-dd').format(_selectedDay),
                        location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                        createdBy: authState.user?.uid ?? '',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(t('common.save')),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isDark;
  final VoidCallback onDelete;

  const _EventCard({required this.event, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14,
                        color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                if (event.eventTime != null)
                  Text(event.eventTime!,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                if (event.location != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12,
                          color: AppColors.mutedForeground),
                      const SizedBox(width: 2),
                      Text(event.location!,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

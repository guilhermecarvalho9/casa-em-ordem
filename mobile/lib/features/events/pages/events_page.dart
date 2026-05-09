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
import '../../permissions/providers/permissions_provider.dart';
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
    final perms = ref.watch(permissionsProvider);
    final myRole = ref.watch(authProvider).houseMembership?.role ?? 'guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String t(String key) => AppTranslations.translate(appState.language, key);

    final allEvents = eventsAsync.valueOrNull ?? [];
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final dayEvents = allEvents.where((e) => e.eventDate == selectedDateStr).toList();

    final Map<DateTime, List<EventModel>> eventMap = {};
    for (final e in allEvents) {
      try {
        final d = DateTime.parse(e.eventDate);
        final key = DateTime(d.year, d.month, d.day);
        eventMap[key] = [...(eventMap[key] ?? []), e];
      } catch (_) {}
    }

    // Base events only (for resolving virtual event edits)
    final baseEvents = allEvents.where((e) => !e.isVirtual).toList();

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
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                weekendStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
              ),
            ),
          ),
          Container(height: 1, color: isDark ? AppColors.borderDark : AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  DateFormat('d MMMM', appState.language == 'pt' ? 'pt_BR' : 'en_US')
                      .format(_selectedDay),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? AppColors.foregroundDark : AppColors.foreground,
                  ),
                ),
                const Spacer(),
                if (dayEvents.isNotEmpty)
                  Text('${dayEvents.length} ${t('events.eventCount')}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.mutedForegroundDark
                              : AppColors.mutedForeground)),
              ],
            ),
          ),
          Expanded(
            child: dayEvents.isEmpty
                ? EmptyState(icon: Icons.event_outlined, message: t('events.noEvents'))
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dayEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final event = dayEvents[i];
                        // Resolve base event for virtual occurrences
                        final editTarget = event.isVirtual
                            ? baseEvents.where((b) => b.id == event.baseId).firstOrNull ?? event
                            : event;
                        final deleteId = event.isVirtual ? (event.baseId ?? event.id) : event.id;
                        return _EventCard(
                          event: event,
                          isDark: isDark,
                          t: t,
                          onEdit: perms.can('events.edit', myRole)
                              ? () => _showEventForm(context, isDark, t, editing: editTarget) : null,
                          onDelete: perms.can('events.delete', myRole)
                              ? () => _confirmDelete(context, event, deleteId, t) : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: perms.can('events.add', myRole)
          ? FloatingActionButton(
              onPressed: () => _showEventForm(context, isDark, t),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _confirmDelete(
      BuildContext context, EventModel event, String eventId, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.confirm')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t('common.deleteConfirm')} "${event.title}"?'),
            if (event.recurring != null) ...[
              const SizedBox(height: 8),
              Text(t('events.deleteAllOccurrences'),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.destructive, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(eventsProvider.notifier).deleteEvent(eventId);
            },
            child:
                Text(t('common.delete'), style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showEventForm(BuildContext context, bool isDark, String Function(String) t,
      {EventModel? editing}) {
    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');
    final locationCtrl = TextEditingController(text: editing?.location ?? '');
    final timeCtrl = TextEditingController(text: editing?.eventTime ?? '');
    final endTimeCtrl = TextEditingController(text: editing?.eventEndTime ?? '');
    DateTime formDate = editing != null
        ? (DateTime.tryParse(editing.eventDate) ?? _selectedDay)
        : _selectedDay;
    String? formRecurring = editing?.recurring;
    DateTime? formRecurringUntil = editing?.recurringUntil != null
        ? DateTime.tryParse(editing!.recurringUntil!)
        : null;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final authState = ref.read(authProvider);
        return StatefulBuilder(
          builder: (_, setState2) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          editing == null ? t('events.add') : t('common.edit'),
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: isDark ? AppColors.foregroundDark : AppColors.foreground),
                        ),
                        if (editing != null && editing.recurring != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t('events.editAllOccurrences'),
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: InputDecoration(labelText: t('common.title')),
                      validator: (v) => v?.isEmpty == true ? t('common.required') : null,
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: timeCtrl,
                            decoration: InputDecoration(
                                labelText: t('events.time'),
                                hintText: '19:00',
                                prefixIcon: const Icon(Icons.access_time_outlined, size: 18)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: endTimeCtrl,
                            decoration: InputDecoration(
                                labelText: t('events.endTime'),
                                hintText: '21:00',
                                prefixIcon: const Icon(Icons.access_time_rounded, size: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: formDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState2(() => formDate = picked);
                      },
                      child: _DateRow(
                        label: DateFormat('dd/MM/yyyy').format(formDate),
                        icon: Icons.calendar_today_outlined,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Recurrence dropdown
                    DropdownButtonFormField<String?>(
                      value: formRecurring,
                      decoration: InputDecoration(
                        labelText: t('events.recurring'),
                        prefixIcon: const Icon(Icons.repeat_outlined, size: 18),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                            value: null, child: Text(t('events.recurringNone'))),
                        DropdownMenuItem(
                            value: 'daily', child: Text(t('events.recurringDaily'))),
                        DropdownMenuItem(
                            value: 'weekly', child: Text(t('events.recurringWeekly'))),
                        DropdownMenuItem(
                            value: 'biweekly', child: Text(t('events.recurringBiweekly'))),
                        DropdownMenuItem(
                            value: 'monthly', child: Text(t('events.recurringMonthly'))),
                        DropdownMenuItem(
                            value: 'yearly', child: Text(t('events.recurringYearly'))),
                      ],
                      onChanged: (v) => setState2(() {
                        formRecurring = v;
                        if (v == null) formRecurringUntil = null;
                      }),
                    ),
                    // Recurring Until date picker (shown only when recurring is set)
                    if (formRecurring != null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: formRecurringUntil ??
                                formDate.add(const Duration(days: 90)),
                            firstDate: formDate,
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState2(() => formRecurringUntil = picked);
                          }
                        },
                        child: _DateRow(
                          label: formRecurringUntil != null
                              ? '${t('events.recurringUntil')}: ${DateFormat('dd/MM/yyyy').format(formRecurringUntil!)}'
                              : t('events.recurringUntilNone'),
                          icon: Icons.event_repeat_outlined,
                          isDark: isDark,
                          muted: formRecurringUntil == null,
                          trailing: formRecurringUntil != null
                              ? GestureDetector(
                                  onTap: () => setState2(() => formRecurringUntil = null),
                                  child: const Icon(Icons.close,
                                      size: 16, color: AppColors.mutedForeground),
                                )
                              : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final dateStr = DateFormat('yyyy-MM-dd').format(formDate);
                          final timeStr =
                              timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim();
                          final endTimeStr =
                              endTimeCtrl.text.trim().isEmpty ? null : endTimeCtrl.text.trim();
                          final untilStr = formRecurringUntil != null
                              ? DateFormat('yyyy-MM-dd').format(formRecurringUntil!)
                              : null;
                          if (editing == null) {
                            await ref.read(eventsProvider.notifier).addEvent(
                                  title: titleCtrl.text.trim(),
                                  description: descCtrl.text.trim().isEmpty
                                      ? null
                                      : descCtrl.text.trim(),
                                  eventDate: dateStr,
                                  eventTime: timeStr,
                                  eventEndTime: endTimeStr,
                                  location: locationCtrl.text.trim().isEmpty
                                      ? null
                                      : locationCtrl.text.trim(),
                                  createdBy: authState.user?.uid ?? '',
                                  recurring: formRecurring,
                                  recurringUntil: untilStr,
                                );
                          } else {
                            await ref.read(eventsProvider.notifier).updateEvent(
                                  eventId: editing.id,
                                  title: titleCtrl.text.trim(),
                                  description: descCtrl.text.trim().isEmpty
                                      ? null
                                      : descCtrl.text.trim(),
                                  eventDate: dateStr,
                                  eventTime: timeStr,
                                  eventEndTime: endTimeStr,
                                  location: locationCtrl.text.trim().isEmpty
                                      ? null
                                      : locationCtrl.text.trim(),
                                  recurring: formRecurring,
                                  recurringUntil: untilStr,
                                );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(t('common.save')),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final bool muted;
  final Widget? trailing;

  const _DateRow({
    required this.label,
    required this.icon,
    required this.isDark,
    this.muted = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: muted ? AppColors.mutedForeground : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: muted
                      ? (isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground)
                      : (isDark ? AppColors.foregroundDark : AppColors.foreground)),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isDark;
  final String Function(String) t;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EventCard({
    required this.event,
    required this.isDark,
    required this.t,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? AppColors.foregroundDark : AppColors.foreground)),
                  if (event.eventTime != null)
                    Text(
                      event.eventEndTime != null
                          ? '${event.eventTime!} → ${event.eventEndTime!}'
                          : event.eventTime!,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  if (event.location != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.mutedForeground),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(event.location!,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForeground),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  if (event.recurring != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.repeat, size: 11, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          _recurringLabel(event.recurring),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18,
                    color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  String _recurringLabel(String? recurring) {
    switch (recurring) {
      case 'daily':
        return t('events.recurringDaily');
      case 'weekly':
        return t('events.recurringWeekly');
      case 'biweekly':
        return t('events.recurringBiweekly');
      case 'monthly':
        return t('events.recurringMonthly');
      case 'yearly':
        return t('events.recurringYearly');
      default:
        return '';
    }
  }

  void _showDetail(BuildContext context) {
    if (event.description == null || event.description!.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(event.title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.eventTime != null) ...[
              Row(children: [
                const Icon(Icons.access_time_outlined,
                    size: 14, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  event.eventEndTime != null
                      ? '${event.eventTime!} → ${event.eventEndTime!}'
                      : event.eventTime!,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500),
                ),
              ]),
              const SizedBox(height: 4),
            ],
            if (event.location != null) ...[
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Text(event.location!,
                    style:
                        GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground)),
              ]),
              const SizedBox(height: 8),
            ],
            if (event.recurring != null) ...[
              Row(children: [
                const Icon(Icons.repeat, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(_recurringLabel(event.recurring),
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 8),
            ],
            Text(event.description!, style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }
}

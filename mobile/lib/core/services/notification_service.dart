import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'bill_reminders';
  static const _channelName = 'Lembretes de contas';

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
            ),
          );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // Schedules up to 2 notifications: 1 day before (9am) + on due date (9am).
  Future<void> scheduleBillReminders({
    required String billId,
    required String billTitle,
    required String dueDate,
    String language = 'pt',
  }) async {
    if (!_initialized) await init();
    await cancelBillReminders(billId);

    final due = DateTime.tryParse(dueDate);
    if (due == null) return;

    final now = DateTime.now();
    final dueDay = DateTime(due.year, due.month, due.day, 9, 0);
    final dayBefore = dueDay.subtract(const Duration(days: 1));

    final bodyDue = language == 'pt'
        ? '"$billTitle" vence hoje!'
        : '"$billTitle" is due today!';
    final bodyBefore = language == 'pt'
        ? '"$billTitle" vence amanhã'
        : '"$billTitle" is due tomorrow';
    final titleStr = language == 'pt' ? 'Lembrete de conta' : 'Bill reminder';

    if (dayBefore.isAfter(now)) {
      await _schedule(
        id: _idBefore(billId),
        title: titleStr,
        body: bodyBefore,
        scheduledDate: dayBefore,
      );
    }

    if (dueDay.isAfter(now)) {
      await _schedule(
        id: _idDue(billId),
        title: titleStr,
        body: bodyDue,
        scheduledDate: dueDay,
      );
    }
  }

  Future<void> cancelBillReminders(String billId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_idBefore(billId));
    await _plugin.cancel(_idDue(billId));
  }

  static const _taskChannelId = 'task_reminders';
  static const _taskChannelName = 'Lembretes de tarefas';

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required String dueDate,
    String? dueTime,
    required String reminderType,
    String language = 'pt',
  }) async {
    if (!_initialized) await init();
    await cancelTaskReminder(taskId);

    if (reminderType == 'none') return;

    final due = DateTime.tryParse(dueDate);
    if (due == null) return;

    int hour = 9, minute = 0;
    if (dueTime != null && dueTime.contains(':')) {
      final parts = dueTime.split(':');
      hour = int.tryParse(parts[0]) ?? 9;
      minute = int.tryParse(parts[1]) ?? 0;
    }

    final scheduledDateTime = DateTime(due.year, due.month, due.day, hour, minute);
    final dayBeforeDateTime = scheduledDateTime.subtract(const Duration(days: 1));
    final hourBeforeDateTime = scheduledDateTime.subtract(const Duration(hours: 1));
    final now = DateTime.now();

    final titleStr = language == 'pt' ? 'Tarefa' : 'Task';
    final timeStr = dueTime ?? '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    if ((reminderType == 'dayBefore' || reminderType == 'both') && dayBeforeDateTime.isAfter(now)) {
      final body = language == 'pt'
          ? '"$taskTitle" amanhã às $timeStr'
          : '"$taskTitle" tomorrow at $timeStr';
      await _scheduleTask(id: _taskIdDay(taskId), title: titleStr, body: body, scheduledDate: dayBeforeDateTime);
    }

    if ((reminderType == 'hourBefore' || reminderType == 'both') && hourBeforeDateTime.isAfter(now)) {
      final body = language == 'pt'
          ? '"$taskTitle" em 1 hora ($timeStr)'
          : '"$taskTitle" in 1 hour ($timeStr)';
      await _scheduleTask(id: _taskIdHour(taskId), title: titleStr, body: body, scheduledDate: hourBeforeDateTime);
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_taskIdDay(taskId));
    await _plugin.cancel(_taskIdHour(taskId));
  }

  Future<void> _scheduleTask({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _taskChannelId, _taskChannelName, importance: Importance.high));
    }
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(_taskChannelId, _taskChannelName,
            importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _taskIdDay(String taskId) => (taskId.hashCode.abs() % 500000) + 1000000;
  int _taskIdHour(String taskId) => (taskId.hashCode.abs() % 500000) + 1500000;

  Future<void> rescheduleAll(
      List<({String id, String title, String dueDate})> bills,
      {String language = 'pt'}) async {
    for (final b in bills) {
      await scheduleBillReminders(
        billId: b.id,
        billTitle: b.title,
        dueDate: b.dueDate,
        language: language,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _idBefore(String billId) => billId.hashCode.abs() % 500000;
  int _idDue(String billId) => billId.hashCode.abs() % 500000 + 500000;
}

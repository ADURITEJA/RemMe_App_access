import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../models/routine_model.dart';

class RoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  RoutineService() {
    _initNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );
    
    // Request notification permissions
    await _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    // On Android, we don't need to request permission for notifications
    // as they are granted by default for apps targeting SDK < 33
    // For iOS, we need to request permissions
    if (await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false) {
      print('iOS notification permissions granted');
    } else {
      print('iOS notification permissions denied');
    }
  }

  // CRUD Operations
  Future<void> addRoutine(Routine routine) async {
    try {
      await _firestore
          .collection('routines')
          .doc(routine.id)
          .set(routine.toMap());
      if (routine.isActive) {
        await _scheduleNotification(routine);
      }
    } catch (e) {
      throw Exception('Failed to add routine: $e');
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    try {
      await _firestore
          .collection('routines')
          .doc(routine.id)
          .update(routine.toMap());
      if (routine.notificationId != null) {
        await _cancelNotification(int.parse(routine.notificationId!));
      }
      if (routine.isActive) {
        await _scheduleNotification(routine);
      }
    } catch (e) {
      throw Exception('Failed to update routine: $e');
    }
  }

  Future<void> deleteRoutine(String routineId, String? notificationId) async {
    try {
      await _firestore.collection('routines').doc(routineId).delete();
      if (notificationId != null) {
        await _cancelNotification(int.parse(notificationId));
      }
    } catch (e) {
      throw Exception('Failed to delete routine: $e');
    }
  }

  Stream<List<Routine>> getRoutinesForPatient(String patientUid) {
    return _firestore
        .collection('routines')
        .where('patientUid', isEqualTo: patientUid)
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Routine.fromJson(doc.data()))
            .toList());
  }

  // Notification Handling
  Future<void> _scheduleNotification(Routine routine) async {
    if (!routine.isActive) return;

    final now = DateTime.now();
    final time = routine.time;
    
    // Create notification details
    final androidDetails = AndroidNotificationDetails(
      'routine_channel',
      'Routine Reminders',
      channelDescription: 'Notifications for patient routines',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
    );
    
    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    for (final day in routine.days) {
      try {
        final dayIndex = _getDayOfWeek(day);
        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // Calculate the next occurrence of this day
        var daysToAdd = (dayIndex - scheduledDate.weekday + 7) % 7;
        if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
          daysToAdd = 7; // Schedule for next week if time has passed today
        }
        scheduledDate = scheduledDate.add(Duration(days: daysToAdd));

        final notificationId = '${routine.id}_${day.toLowerCase()}'.hashCode;
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
        
        // Try to schedule exact alarm first
        try {
          await _notifications.zonedSchedule(
            notificationId,
            routine.title,
            routine.description,
            tzScheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: routine.id,
          );
        } catch (e) {
          // Fallback to non-exact scheduling if exact alarms aren't permitted
          print('Error scheduling exact notification, falling back to inexact: $e');
          await _notifications.zonedSchedule(
            notificationId + 1, // Different ID to avoid conflicts
            routine.title,
            routine.description,
            tzScheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'routine_channel',
                'Routine Reminders',
                channelDescription: 'Notifications for patient routines',
                importance: Importance.high,
                priority: Priority.high,
                enableVibration: true,
                playSound: true,
              ),
              iOS: const DarwinNotificationDetails(
                sound: 'default',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: routine.id,
          );
        }
      } catch (e) {
        print('Error scheduling notification: $e');
        // If all else fails, schedule a one-time notification
        await _notifications.zonedSchedule(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          routine.title,
          routine.description,
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'routine_channel',
              'Routine Reminders',
              channelDescription: 'Notifications for patient routines',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              sound: 'default',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: routine.id,
        );
      }
    }
  }

  // Helper method to get day of week as int (1-7)
  int _getDayOfWeek(String day) {
    final index = _daysOfWeek.indexWhere((d) => d.toLowerCase() == day.toLowerCase());
    return index >= 0 ? index + 1 : 1; // Default to Monday if not found
  }

  // Cancel a notification by ID
  Future<void> _cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  // Toggle routine status and update notifications
  Future<void> toggleRoutineStatus(Routine routine) async {
    try {
      final updatedRoutine = routine.copyWith(isActive: !routine.isActive);
      await _firestore
          .collection('routines')
          .doc(routine.id)
          .update(updatedRoutine.toMap());
      
      // Cancel any existing notifications
      if (routine.notificationId != null) {
        await _cancelNotification(int.parse(routine.notificationId!));
      }
      
      // Schedule new notification if activating
      if (updatedRoutine.isActive) {
        await _scheduleNotification(updatedRoutine);
      }
      
      // Refresh the routine to ensure we have the latest data
      await _firestore
          .collection('routines')
          .doc(routine.id)
          .get()
          .then((doc) {
            if (doc.exists) {
              return Routine.fromJson(doc.data()!);
            }
            return null;
          });
    } catch (e) {
      throw Exception('Failed to toggle routine status: $e');
    }
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Inisialisasi TimeZone
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  // Fungsi untuk mengatur jadwal dari data API
  static Future<void> scheduleWatering({
    required int plantId,
    required String plantName,
    required String nextWateringStr, // Format: YYYY-MM-DD HH:MM:SS
    required int frequency,
  }) async {
    // 1. Parsing tanggal dari BE (misal: "2024-05-20 08:00:00")
    DateTime nextWateringDate = DateTime.parse(nextWateringStr);

    // Pastikan jika tanggal dari BE ternyata sudah lewat, kita jadwalkan sekarang + beberapa detik (untuk testing)
    if (nextWateringDate.isBefore(DateTime.now())) {
      nextWateringDate = DateTime.now().add(
        const Duration(seconds: 10),
      ); // Hanya untuk fallback
    }

    // 2. Jadwalkan Notifikasi di OS Lokal
    await _notificationsPlugin.zonedSchedule(
      plantId, // Gunakan plantId sebagai ID Notifikasi
      '💧 Waktunya Siram: $plantName',
      'Sudah jadwalnya! Interval penyiraman kamu adalah $frequency hari.',
      tz.TZDateTime.from(nextWateringDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'watering_channel',
          'Pengingat Siram Tanaman',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // 3. Simpan ke Log SharedPreferences
    await _saveToLog(plantId, plantName, nextWateringDate, frequency);
  }

  static Future<void> _saveToLog(
    int id,
    String plantName,
    DateTime date,
    int frequency,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('notif_logs') ?? [];

    final newLog = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': '💧 Jadwal Siram: $plantName',
      'body':
          'Notifikasi disetel pada ${date.toString().substring(0, 16)} (Interval: $frequency hari)',
      'isRead': false, // Belum dibaca
      'timestamp': DateTime.now().toIso8601String(),
    };

    logs.insert(0, jsonEncode(newLog)); // Tambahkan di atas (terbaru)
    await prefs.setStringList('notif_logs', logs);
  }
}

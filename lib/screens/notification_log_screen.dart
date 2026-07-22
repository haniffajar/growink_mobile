import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationLogScreen extends StatefulWidget {
  const NotificationLogScreen({super.key});

  @override
  State<NotificationLogScreen> createState() => _NotificationLogScreenState();
}

class _NotificationLogScreenState extends State<NotificationLogScreen> {
  List<dynamic> _logs = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // Helper untuk mengambil key SharedPreferences khusus user yang login
  Future<String?> _getStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawUid = prefs.get('uid');
    if (rawUid != null) {
      return 'notif_logs_${rawUid.toString()}';
    }
    return null;
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawUid = prefs.get('uid');
    _currentUserId = rawUid?.toString();

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      setState(() => _logs = []);
      return;
    }

    // Ambil log berdasarkan key spesifik user ID
    List<String> savedLogs =
        prefs.getStringList('notif_logs_$_currentUserId') ?? [];
    setState(() {
      _logs = savedLogs.map((log) => jsonDecode(log)).toList();
    });
  }

  Future<void> _markAsRead(int index) async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    String key = 'notif_logs_$_currentUserId';
    List<String> savedLogs = prefs.getStringList(key) ?? [];

    Map<String, dynamic> logData = jsonDecode(savedLogs[index]);
    logData['isRead'] = true; // Tandai sudah dibaca
    savedLogs[index] = jsonEncode(logData);

    await prefs.setStringList(key, savedLogs);
    _loadLogs();
  }

  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    String key = 'notif_logs_$_currentUserId';
    List<String> savedLogs = prefs.getStringList(key) ?? [];

    List<String> updatedLogs = savedLogs.map((logStr) {
      Map<String, dynamic> logData = jsonDecode(logStr);
      logData['isRead'] = true;
      return jsonEncode(logData);
    }).toList();

    await prefs.setStringList(key, updatedLogs);
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tandai semua dibaca',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(child: Text('Belum ada notifikasi.'))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isRead = log['isRead'] ?? false;

                return ListTile(
                  tileColor: isRead
                      ? Colors.transparent
                      : Colors.green.withValues(alpha: 0.1),
                  leading: const Icon(
                    Icons.notifications_active,
                    color: Colors.green,
                  ),
                  title: Text(
                    log['title'] ?? 'Notifikasi',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(log['body'] ?? ''),
                  onTap: () => _markAsRead(index),
                );
              },
            ),
    );
  }
}

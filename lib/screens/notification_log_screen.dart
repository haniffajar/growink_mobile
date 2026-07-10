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

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedLogs = prefs.getStringList('notif_logs') ?? [];
    setState(() {
      _logs = savedLogs.map((log) => jsonDecode(log)).toList();
    });
  }

  Future<void> _markAsRead(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedLogs = prefs.getStringList('notif_logs') ?? [];

    Map<String, dynamic> logData = jsonDecode(savedLogs[index]);
    logData['isRead'] = true; // Tandai sudah dibaca
    savedLogs[index] = jsonEncode(logData);

    await prefs.setStringList('notif_logs', savedLogs);
    _loadLogs();
  }

  Future<void> _markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedLogs = prefs.getStringList('notif_logs') ?? [];

    List<String> updatedLogs = savedLogs.map((logStr) {
      Map<String, dynamic> logData = jsonDecode(logStr);
      logData['isRead'] = true;
      return jsonEncode(logData);
    }).toList();

    await prefs.setStringList('notif_logs', updatedLogs);
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
                    log['title'],
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(log['body']),
                  onTap: () => _markAsRead(index), // Klik untuk read
                );
              },
            ),
    );
  }
}

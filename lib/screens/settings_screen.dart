import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  TimeOfDay? _notificationTime;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledTime = await _notificationService.getScheduledNotificationTime();
      setState(() {
        _notificationTime = scheduledTime;
        _notificationsEnabled = scheduledTime != null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      if (_notificationTime == null) {
        // Default to 8:00 PM if no time was previously set
        _notificationTime = const TimeOfDay(hour: 20, minute: 0);
      }
      await _showTimePicker();
    } else {
      await _notificationService.cancelAll();
    }
  }

  Future<void> _showTimePicker() async {
    final initialTime = _notificationTime ?? const TimeOfDay(hour: 20, minute: 0);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Color(0xFF303030),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });

      await _notificationService.scheduleDaily(
        picked,
        title: 'Expense Reminder',
        body: 'Time to check your expenses for today!',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Daily notification set for ${picked.format12Hour()}')),
      );
    } else if (_notificationsEnabled && _notificationTime == null) {
      // If the user cancels and no time was previously set, disable notifications
      setState(() {
        _notificationsEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification Settings
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Expense Reminder',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeColor: Colors.deepPurple,
                    ),
                  ],
                ),
                if (_notificationsEnabled && _notificationTime != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showTimePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.deepPurple,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _notificationTime!.format12Hour(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Theme Settings
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Switch(
                      value: true, // Always on for now
                      onChanged: null, // Disabled
                      activeColor: Colors.deepPurple,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // App Info
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Version',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Last Updated',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Account Actions
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Show backup & restore options
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup & Restore feature coming soon')),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Backup & Restore Data'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Privacy policy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy will open in browser')),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Privacy Policy'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Sign out
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign out functionality will be implemented')),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
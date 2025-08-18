import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/signalr_notification_service.dart';

class TestNotificationScreen extends ConsumerStatefulWidget {
  const TestNotificationScreen({super.key});

  @override
  ConsumerState<TestNotificationScreen> createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends ConsumerState<TestNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Test Notification';
    _messageController.text = 'This is a test notification message';
    _setupSignalRListeners();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _setupSignalRListeners() {
    final signalRService = SignalRNotificationService();
    
    signalRService.generalNotifications.listen((data) {
      _addLog('Received general notification: ${data['title']}');
      signalRService.showLocalNotification(
        title: data['title'] ?? 'Test',
        body: data['message'] ?? 'Test message',
      );
    });

    signalRService.chatNotifications.listen((data) {
      _addLog('Received chat notification: ${data['message']}');
    });

    signalRService.jobPostNotifications.listen((data) {
      _addLog('Received job post notification: ${data['message']}');
    });

    signalRService.interviewNotifications.listen((data) {
      _addLog('Received interview notification: ${data['message']}');
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      SignalRNotificationService().isConnected 
                          ? Icons.wifi 
                          : Icons.wifi_off,
                      color: SignalRNotificationService().isConnected 
                          ? Colors.green 
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      SignalRNotificationService().isConnected 
                          ? 'Connected to SignalR' 
                          : 'Disconnected from SignalR',
                      style: TextStyle(
                        color: SignalRNotificationService().isConnected 
                            ? Colors.green 
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Notification Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Test Notification',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendTestNotification,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Send Test'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sendLocalNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Local Test'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _testChatNotification,
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade700,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testJobNotification,
                          icon: const Icon(Icons.work, size: 16),
                          label: const Text('Job'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade700,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testInterviewNotification,
                          icon: const Icon(Icons.event, size: 16),
                          label: const Text('Interview'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade100,
                            foregroundColor: Colors.orange.shade700,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _clearLogs,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logs
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Notification Logs',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_logs.length} entries',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No logs yet. Send a test notification!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    log,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // final notificationService = NotificationService();
      // This would call the backend test API (when implemented)
      _addLog('Attempted to send test notification via API');
      
      // For now, just simulate a local notification
      await _sendLocalNotification();
      
    } catch (e) {
      _addLog('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendLocalNotification() async {
    final signalRService = SignalRNotificationService();
    await signalRService.showLocalNotification(
      title: _titleController.text,
      body: _messageController.text,
    );
    _addLog('Sent local notification: ${_titleController.text}');
  }

  void _testChatNotification() {
    _addLog('Simulating chat notification');
    final signalRService = SignalRNotificationService();
    signalRService.showLocalNotification(
      title: 'New Chat Message',
      body: 'You have a new message from John Doe',
    );
  }

  void _testJobNotification() {
    _addLog('Simulating job notification');
    final signalRService = SignalRNotificationService();
    signalRService.showLocalNotification(
      title: 'New Job Posted',
      body: 'A new job "Flutter Developer" has been posted',
    );
  }

  void _testInterviewNotification() {
    _addLog('Simulating interview notification');
    final signalRService = SignalRNotificationService();
    signalRService.showLocalNotification(
      title: 'Interview Scheduled',
      body: 'Your interview has been scheduled for tomorrow at 2:00 PM',
    );
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }
}

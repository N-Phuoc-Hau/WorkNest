import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/interview/screens/interview_list_screen.dart';
import '../features/notifications/screens/notification_screen.dart';
import '../features/notifications/screens/test_notification_screen.dart';

class NotificationDemoApp extends StatelessWidget {
  const NotificationDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WorkNest Notification Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DemoHomeScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/test-notifications',
      builder: (context, state) => const TestNotificationScreen(),
    ),
    GoRoute(
      path: '/interviews',
      builder: (context, state) => const InterviewListScreen(),
    ),
  ],
);

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkNest Notification Demo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Notification System Demo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Test các tính năng thông báo real-time',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDemoCard(
                        context,
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Xem tất cả thông báo',
                        color: Colors.blue,
                        onTap: () => context.go('/notifications'),
                      ),
                      
                      _buildDemoCard(
                        context,
                        icon: Icons.science,
                        title: 'Test Notifications',
                        subtitle: 'Test gửi thông báo',
                        color: Colors.orange,
                        onTap: () => context.go('/test-notifications'),
                      ),
                      
                      _buildDemoCard(
                        context,
                        icon: Icons.event,
                        title: 'Interviews',
                        subtitle: 'Lịch phỏng vấn',
                        color: Colors.green,
                        onTap: () => context.go('/interviews'),
                      ),
                      
                      _buildDemoCard(
                        context,
                        icon: Icons.chat,
                        title: 'Chat (Coming)',
                        subtitle: 'Tin nhắn real-time',
                        color: Colors.purple,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chat feature coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Các tính năng đã implement',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '✅ SignalR Hub với JWT authentication\n'
                          '✅ NotificationService với real-time delivery\n'
                          '✅ InterviewController và Interview model\n'
                          '✅ Chat notification integration\n'
                          '✅ Job posting notifications\n'
                          '✅ Interview scheduling với email\n'
                          '✅ Flutter local notifications\n'
                          '✅ Database migrations completed',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

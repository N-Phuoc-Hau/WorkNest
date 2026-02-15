import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/theme_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class WorkNestApp extends ConsumerWidget {
  const WorkNestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'WorkNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return BackButtonInterceptor(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Widget to intercept Android back button
class BackButtonInterceptor extends StatelessWidget {
  final Widget child;

  const BackButtonInterceptor({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        // Get the current router
        final router = GoRouter.of(context);
        
        // Check if we can go back in the navigation stack
        if (router.canPop()) {
          // Pop the current route
          router.pop();
        } else {
          // If we're at the root, show exit confirmation dialog
          final shouldExit = await _showExitConfirmation(context);
          if (shouldExit == true) {
            // Exit the app
            SystemNavigator.pop();
          }
        }
      },
      child: child,
    );
  }

  /// Show confirmation dialog before exiting the app
  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát ứng dụng'),
        content: const Text('Bạn có chắc chắn muốn thoát ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class AuthGuard {
  static bool requireAuth(
    BuildContext context, 
    WidgetRef ref, {
    String? message,
  }) {
    final authState = ref.read(authProvider);
    
    if (!authState.isAuthenticated) {
      _showLoginDialog(context, message: message);
      return false;
    }
    
    return true;
  }

  static void _showLoginDialog(
    BuildContext context, {
    String? message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: Text(
          message ?? 'Bạn cần đăng nhập để sử dụng tính năng này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  static void showAuthRequiredSnackbar(
    BuildContext context, {
    String? message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? 'Vui lòng đăng nhập để sử dụng tính năng này',
        ),
        action: SnackBarAction(
          label: 'Đăng nhập',
          onPressed: () => context.go('/login'),
        ),
      ),
    );
  }
}

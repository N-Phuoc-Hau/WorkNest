import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../screens/start_chat_screen.dart';

class StartChatFAB extends ConsumerWidget {
  const StartChatFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StartChatScreen(),
          ),
        );
      },
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      child: const Icon(Icons.chat),
    );
  }
} 
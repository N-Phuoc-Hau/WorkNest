import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng tuyển của tôi'),
      ),
      body: const Center(
        child: Text('My Applications Screen - Coming Soon'),
      ),
    );
  }
}

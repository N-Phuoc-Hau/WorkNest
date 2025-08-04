import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../router/app_router.dart';

class WorkNestApp extends ConsumerWidget {
  const WorkNestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'WorkNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // Force light theme với màu xanh trắng
      routerConfig: router,
    );
  }
}

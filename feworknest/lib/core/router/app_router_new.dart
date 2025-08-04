import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/applications/screens/my_applications_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/candidate/screens/candidate_home_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/favorites/screens/favorite_screen.dart';
import '../../features/job_posting/screens/create_job_screen.dart';
import '../../features/job_posting/screens/manage_jobs_screen.dart';
import '../../features/jobs/screens/job_detail_screen.dart';
import '../../features/jobs/screens/job_list_screen.dart';
import '../../features/landing/landing_page.dart';
import '../../features/navigation/layouts/mobile_layout.dart';
import '../../features/navigation/layouts/web_layout.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/recruiter/screens/recruiter_home_screen.dart';
import '../../shared/screens/company_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.uri.toString();

      // If loading, stay on current page
      if (isLoading) {
        return null;
      }

      // Public routes that don't require authentication
      final publicRoutes = [
        '/',
        '/login',
        '/register',
      ];

      // Allow job detail and company pages for everyone
      if (location.startsWith('/job-detail/') || location.startsWith('/company/')) {
        return null;
      }

      // If trying to access protected routes without login
      if (!isLoggedIn && !publicRoutes.contains(location)) {
        return '/login';
      }

      // If logged in and trying to access auth pages, redirect to appropriate home
      if (isLoggedIn && (location == '/login' || location == '/register')) {
        final user = authState.user;
        if (user?.isRecruiter == true) {
          return '/recruiter/home';
        } else {
          return '/candidate/home';
        }
      }

      return null;
    },
    routes: [
      // Public Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/job-detail/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return JobDetailScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/company/:id',
        builder: (context, state) {
          final companyId = state.pathParameters['id']!;
          return CompanyScreen(companyId: companyId);
        },
      ),

      // Candidate Routes
      GoRoute(
        path: '/candidate',
        redirect: (context, state) => '/candidate/home',
      ),
      GoRoute(
        path: '/candidate/home',
        builder: (context, state) => _buildWithLayout(
          context, 
          const CandidateHomeScreen(),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/candidate/jobs',
        builder: (context, state) => _buildWithLayout(
          context, 
          const JobListScreen(),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/candidate/favorites',
        builder: (context, state) => _buildWithLayout(
          context, 
          const FavoriteScreen(),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/candidate/applications',
        builder: (context, state) => _buildWithLayout(
          context, 
          const MyApplicationsScreen(),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/candidate/profile',
        builder: (context, state) => _buildWithLayout(
          context, 
          const ProfileScreen(),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/candidate/chat',
        builder: (context, state) => _buildWithLayout(
          context, 
          const ChatListScreen(),
          'candidate',
        ),
        routes: [
          GoRoute(
            path: ':roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return ChatScreen(roomId: roomId);
            },
          ),
        ],
      ),

      // Recruiter Routes
      GoRoute(
        path: '/recruiter',
        redirect: (context, state) => '/recruiter/home',
      ),
      GoRoute(
        path: '/recruiter/home',
        builder: (context, state) => _buildWithLayout(
          context, 
          const RecruiterHomeScreen(),
          'recruiter',
        ),
      ),
      GoRoute(
        path: '/recruiter/post-job',
        builder: (context, state) => _buildWithLayout(
          context, 
          const CreateJobScreen(),
          'recruiter',
        ),
      ),
      GoRoute(
        path: '/recruiter/jobs',
        builder: (context, state) => _buildWithLayout(
          context, 
          const ManageJobsScreen(),
          'recruiter',
        ),
      ),
      GoRoute(
        path: '/recruiter/chat',
        builder: (context, state) => _buildWithLayout(
          context, 
          const ChatListScreen(),
          'recruiter',
        ),
        routes: [
          GoRoute(
            path: ':roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return ChatScreen(roomId: roomId);
            },
          ),
        ],
      ),

      // Shared notification route
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
});

Widget _buildWithLayout(BuildContext context, Widget child, String userType) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth > 1024) {
        // Desktop/Web layout
        return WebLayout(child: child);
      } else {
        // Mobile layout
        return MobileLayout(child: child);
      }
    },
  );
}

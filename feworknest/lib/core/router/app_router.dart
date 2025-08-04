import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_companies_screen.dart';
import '../../features/admin/screens/admin_jobs_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/applications/screens/my_applications_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/candidate/screens/candidate_home_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
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
import '../../features/recruiter/screens/recruiter_applicants_screen.dart';
import '../../features/recruiter/screens/recruiter_company_screen.dart';
import '../../features/recruiter/screens/recruiter_home_screen.dart';
import '../../features/settings/screens/admin_settings_screen.dart';
import '../../features/settings/screens/candidate_settings_screen.dart';
import '../../features/settings/screens/recruiter_settings_screen.dart';
import '../../shared/screens/company_screen.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final user = authState.user;
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
        '/jobs',
        '/search',
        '/about',
        '/job-detail',
        '/company',
      ];

      // Allow job detail and company pages for everyone
      if (location.startsWith('/job-detail/') || 
          location.startsWith('/company/') ||
          location.startsWith('/jobs/')) {
        return null;
      }

      // If trying to access protected routes without login
      if (!isLoggedIn && !publicRoutes.contains(location) && !location.startsWith('/recruiter')) {
        return '/login';
      }

      // Protect recruiter routes - only allow recruiters
      if (location.startsWith('/recruiter') && (!isLoggedIn || user?.isRecruiter != true)) {
        return '/login';
      }

      // If logged in and trying to access auth pages, redirect to appropriate home
      if (isLoggedIn && (location == '/login' || location == '/register')) {
        if (user?.isRecruiter == true) {
          return '/recruiter/home';
        } else {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      // Landing Page / Home for Candidates and Guests
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      
      // Candidate Home (for logged in candidates)
      GoRoute(
        path: '/home',
        builder: (context, state) => _buildWithLayout(
          context, 
          const CandidateHomeScreen(),
          'candidate',
        ),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Candidate/Public Routes (without /candidate prefix)
      GoRoute(
        path: '/jobs',
        builder: (context, state) => _buildWithLayout(
          context, 
          const JobListScreen(),
          'candidate',
        ),
        routes: [
          GoRoute(
            path: ':id',
            redirect: (context, state) {
              final jobId = state.pathParameters['id']!;
              return '/job-detail/$jobId';
            },
          ),
        ],
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => _buildWithLayout(
          context, 
          const FavoriteScreen(),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/applications',
        builder: (context, state) => _buildWithLayout(
          context, 
          const MyApplicationsScreen(),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => _buildWithLayout(
          context, 
          const ProfileScreen(),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/chat',
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
      GoRoute(
        path: '/search',
        builder: (context, state) => _buildWithLayout(
          context, 
          const JobListScreen(), // You can create a dedicated search screen
          'candidate',
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => _buildWithLayout(
          context, 
          const LandingPage(), // You can create a dedicated about screen
          'candidate',
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => _buildWithLayout(
          context, 
          const CandidateSettingsScreen(),
          'candidate',
        ),
      ),
      
      // Job Detail and Company Routes (accessible to all)
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
        path: '/recruiter/applicants',
        builder: (context, state) => _buildWithLayout(
          context, 
          const RecruiterApplicantsScreen(),
          'recruiter',
        ),
      ),
      GoRoute(
        path: '/recruiter/company',
        builder: (context, state) => _buildWithLayout(
          context, 
          const RecruiterCompanyScreen(),
          'recruiter',
        ),
      ),
      GoRoute(
        path: '/recruiter/settings',
        builder: (context, state) => _buildWithLayout(
          context, 
          const RecruiterSettingsScreen(),
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

      // Admin Routes
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/users',
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => _buildWithLayout(
          context, 
          const AdminDashboardScreen(),
          'admin',
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => _buildWithLayout(
          context, 
          const AdminUsersScreen(),
          'admin',
        ),
      ),
      GoRoute(
        path: '/admin/jobs',
        builder: (context, state) => _buildWithLayout(
          context, 
          const AdminJobsScreen(),
          'admin',
        ),
      ),
      GoRoute(
        path: '/admin/companies',
        builder: (context, state) => _buildWithLayout(
          context, 
          const AdminCompaniesScreen(),
          'admin',
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => _buildWithLayout(
          context, 
          const AdminSettingsScreen(),
          'admin',
        ),
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

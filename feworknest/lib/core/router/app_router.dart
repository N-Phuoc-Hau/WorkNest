import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/application_model.dart';
import '../../features/admin/screens/admin_companies_screen.dart';
import '../../features/admin/screens/admin_jobs_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/applications/screens/application_detail_screen.dart';
import '../../features/applications/screens/my_applications_screen.dart';
import '../../features/auth/screens/forgot_password_screen_old.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/verify_otp_screen_old.dart';
import '../../features/candidate/screens/candidate_home_screen.dart';
import '../../features/candidate/screens/cv_analysis_screen.dart';
import '../../features/candidate/screens/following_companies_screen.dart';
import '../../features/chat/screens/chat_detail_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/favorites/screens/favorite_screen.dart';
import '../../features/interview/screens/schedule_interview_screen.dart';
import '../../features/job_posting/screens/create_job_screen.dart';
import '../../features/job_posting/screens/edit_job_screen.dart';
import '../../features/job_posting/screens/manage_jobs_screen.dart';
import '../../features/jobs/screens/job_detail_screen.dart';
import '../../features/jobs/screens/job_list_screen.dart';
import '../../features/landing/landing_page.dart';
import '../../features/navigation/layouts/mobile_layout.dart';
import '../../features/navigation/layouts/web_layout.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/recruiter/pages/recruiter_application_detail_page.dart';
import '../../features/recruiter/screens/analytics_screen.dart';
import '../../features/recruiter/screens/recruiter_applicants_screen.dart';
import '../../features/recruiter/screens/recruiter_company_screen.dart';
import '../../features/recruiter/screens/recruiter_home_screen.dart';
import '../../features/search/screens/advanced_search_screen.dart';
import '../../features/settings/screens/admin_settings_screen.dart';
import '../../features/settings/screens/candidate_settings_screen.dart';
import '../../features/settings/screens/recruiter_settings_screen.dart';
import '../../shared/screens/company_screen.dart';
import 'auth_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authRouterNotifierProvider);
  
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier, // Use listenable instead of rebuilding entire router
    redirect: (context, state) {
      // Read auth state from notifier without causing rebuild
      final isLoggedIn = authNotifier.isAuthenticated;
      final isLoading = authNotifier.isLoading;
      final user = authNotifier.user;
      final location = state.uri.toString();

      print('DEBUG Router: location=$location, isLoggedIn=$isLoggedIn, isLoading=$isLoading, user=${user?.fullName}');

      // CRITICAL: If loading, MUST stay on current page to prevent premature redirects
      if (isLoading) {
        print('DEBUG Router: Still loading, staying on current page');
        return null;
      }

      // Auth pages - these should be accessible when NOT logged in
      final authPages = ['/login', '/register', '/forgot-password', '/verify-otp', '/reset-password'];
      
      // Public routes that anyone can access
      final publicRoutes = [
        '/',
        '/jobs',
        '/search',
        '/job-detail',
        '/company',
      ];

      // Protected routes that REQUIRE authentication
      final protectedRoutes = [
        '/home',
        '/favorites',
        '/applications',
        '/profile',
        '/chat',
        '/settings',
        '/notifications',
      ];

      // PRIORITY 1: If on auth page and NOT loading
      if (authPages.contains(location)) {
        if (isLoggedIn && user != null) {
          // User is logged in, redirect away from auth pages to appropriate home
          print('DEBUG Router: User authenticated on auth page, redirecting to home');
          if (user.role == 'Admin') {
            return '/admin-dashboard';
          } else if (user.isRecruiter == true) {
            return '/recruiter/home';
          } else {
            return '/home';
          }
        } else {
          // User NOT logged in on auth page - THIS IS CORRECT, stay here
          print('DEBUG Router: User not authenticated on auth page, staying');
          return null;
        }
      }

      // PRIORITY 2: Allow public routes for everyone
      if (publicRoutes.contains(location) || 
          location.startsWith('/job-detail/') || 
          location.startsWith('/company/') ||
          location.startsWith('/jobs/')) {
        print('DEBUG Router: Public route, allowing access');
        return null;
      }

      // PRIORITY 3: Protect restricted routes - redirect to login if not authenticated
      if (protectedRoutes.contains(location) || location.startsWith('/admin')) {
        if (!isLoggedIn) {
          print('DEBUG Router: Protected route without auth, redirecting to /login');
          return '/login';
        }
        return null;
      }

      // PRIORITY 4: Protect recruiter routes - only allow recruiters
      if (location.startsWith('/recruiter') || location.startsWith('/edit-job')) {
        if (!isLoggedIn || user?.isRecruiter != true) {
          print('DEBUG Router: Recruiter route protection, redirecting to /login');
          return '/login';
        }
        return null;
      }

      // Default: allow navigation
      print('DEBUG Router: No redirect needed, allowing navigation');
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
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = state.extra as String;
          return VerifyOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return ResetPasswordScreen(
            email: data['email'] as String,
            resetToken: data['resetToken'] as String,
          );
        },
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
        path: '/following-companies',
        builder: (context, state) => _buildWithLayout(
          context, 
          const FollowingCompaniesScreen(),
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
        path: '/application/:id',
        builder: (context, state) {
          final applicationId = state.pathParameters['id']!;
          return _buildWithLayout(
            context, 
            ApplicationDetailScreen(applicationId: applicationId),
            'candidate',
          );
        },
      ),
      GoRoute(
        path: '/cv-analysis',
        builder: (context, state) => _buildWithLayout(
          context, 
          const CVAnalysisScreen(),
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
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => _buildWithLayout(
              context, 
              const EditProfileScreen(),
              'candidate',
            ),
          ),
        ],
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
              final otherUserName = state.uri.queryParameters['userName'] ?? 'Unknown User';
              final otherUserAvatar = state.uri.queryParameters['userAvatar'] ?? '';
              
              // If we have minimal info from external navigation, use it
              // Otherwise, ChatDetailScreen will need to fetch user info from roomId
              return _buildWithLayout(
                context,
                ChatDetailScreen(
                  roomId: roomId,
                  otherUserName: otherUserName,
                  otherUserAvatar: otherUserAvatar,
                ),
                'candidate',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const AdvancedSearchScreen(),
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
        path: '/edit-job/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return _buildWithLayout(
            context,
            EditJobScreen(jobId: jobId),
            'recruiter',
          );
        },
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
        path: '/recruiter/analytics',
        builder: (context, state) => _buildWithLayout(
          context, 
          const AnalyticsScreen(),
          'recruiter',
        ),
      ),
      GoRoute(
        path: '/recruiter/applicant/:applicationId',
        builder: (context, state) {
          final applicationId = state.pathParameters['applicationId']!;
          return _buildWithLayout(
            context, 
            RecruiterApplicationDetailPage(applicationId: applicationId),
            'recruiter',
          );
        },
      ),
      GoRoute(
        path: '/recruiter/schedule-interview/:applicationId',
        builder: (context, state) {
          final application = state.extra as ApplicationModel?;
          
          if (application == null) {
            // If no application data passed, redirect back
            return _buildWithLayout(
              context,
              const Scaffold(
                body: Center(
                  child: Text('Không tìm thấy thông tin ứng viên'),
                ),
              ),
              'recruiter',
            );
          }
          
          return _buildWithLayout(
            context, 
            ScheduleInterviewScreen(application: application),
            'recruiter',
          );
        },
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
              final otherUserName = state.uri.queryParameters['userName'] ?? 'Unknown User';
              final otherUserAvatar = state.uri.queryParameters['userAvatar'] ?? '';
              
              // If we have minimal info from external navigation, use it
              // Otherwise, ChatDetailScreen will need to fetch user info from roomId
              return _buildWithLayout(
                context,
                ChatDetailScreen(
                  roomId: roomId,
                  otherUserName: otherUserName,
                  otherUserAvatar: otherUserAvatar,
                ),
                'recruiter',
              );
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
        builder: (context, state) => _buildWithLayout(
          context,
          const NotificationScreen(), 
          'candidate',
        ),
      ),
      
      // Help and Reviews routes
      GoRoute(
        path: '/help',
        builder: (context, state) => _buildWithLayout(
          context, 
          const Scaffold(
            body: Center(
              child: Text('Trang Trợ giúp - Đang phát triển'),
            ),
          ),
          'candidate',
        ),
      ),
      GoRoute(
        path: '/reviews',
        builder: (context, state) => _buildWithLayout(
          context, 
          const Scaffold(
            body: Center(
              child: Text('Trang Đánh giá - Đang phát triển'),
            ),
          ),
          'candidate',
        ),
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


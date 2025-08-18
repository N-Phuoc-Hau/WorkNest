import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/application_model.dart';
import '../../features/admin/screens/admin_companies_screen.dart';
import '../../features/admin/screens/admin_jobs_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/applications/screens/application_detail_screen.dart';
import '../../features/applications/screens/my_applications_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/candidate/screens/candidate_home_screen.dart';
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
import '../../features/recruiter/screens/recruiter_applicants_screen.dart';
import '../../features/recruiter/screens/recruiter_company_screen.dart';
import '../../features/recruiter/screens/recruiter_home_screen.dart';
import '../../features/search/screens/advanced_search_screen.dart';
import '../../features/settings/screens/admin_settings_screen.dart';
import '../../features/settings/screens/candidate_settings_screen.dart';
import '../../features/settings/screens/recruiter_settings_screen.dart';
import '../../shared/screens/company_screen.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final user = authState.user;
      final location = state.uri.toString();

      print('DEBUG Router: location=$location, isLoggedIn=$isLoggedIn, isLoading=$isLoading, user=${user?.fullName}');

      // If loading, stay on current page
      if (isLoading) {
        print('DEBUG Router: Still loading, staying on current page');
        return null;
      }

      // Public routes that don't require authentication (but exclude auth pages)
      final publicRoutes = [
        '/',
        '/jobs',
        '/search',
        '/job-detail',
        '/company',
      ];

      // Protected routes that require authentication
      final protectedRoutes = [
        '/home',
        '/favorites',
        '/applications',
        '/profile',
        '/chat',
        '/settings',
        '/notifications',
      ];

      // PRIORITY 1: If logged in and trying to access auth pages, redirect to appropriate home
      if (isLoggedIn && user != null && (location == '/login' || location == '/register')) {
        print('DEBUG Router: User is authenticated, redirecting from auth page');
        print('DEBUG Router: user.role = ${user.role}');
        print('DEBUG Router: user.isRecruiter = ${user.isRecruiter}');
        print('DEBUG Router: Checking redirect logic...');
        
        if (user.role == 'Admin') {
          print('DEBUG Router: Admin user, redirecting to /admin-dashboard');
          return '/admin-dashboard';
        } else if (user.isRecruiter == true) {
          print('DEBUG Router: Logged in recruiter accessing auth page, redirecting to /recruiter/home');
          return '/recruiter/home';
        } else {
          print('DEBUG Router: Logged in user accessing auth page, redirecting to /home');
          return '/home';
        }
      }

      // PRIORITY 2: Allow job detail and company pages for everyone
      if (location.startsWith('/job-detail/') || 
          location.startsWith('/company/') ||
          location.startsWith('/jobs/') ||
          publicRoutes.contains(location)) {
        print('DEBUG Router: Public route allowed');
        return null;
      }

      // PRIORITY 3: If not logged in and trying to access protected routes, redirect to /login
      if (!isLoggedIn && (protectedRoutes.contains(location) || 
          location.startsWith('/recruiter') || 
          location.startsWith('/edit-job'))) {
        print('DEBUG Router: Not logged in, redirecting to /login');
        return '/login';
      }

      // PRIORITY 4: Protect recruiter routes - only allow recruiters
      if ((location.startsWith('/recruiter') || location.startsWith('/edit-job')) && 
          (!isLoggedIn || user?.isRecruiter != true)) {
        print('DEBUG Router: Recruiter route protection, redirecting to /login');
        return '/login';
      }

      // PRIORITY 5: If not logged in and on root, redirect to login
      if (!isLoggedIn && location == '/') {
        print('DEBUG Router: Not logged in on root page, redirecting to /login');
        return '/login';
      }

      print('DEBUG Router: No redirect needed');
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
        builder: (context, state) => const NotificationScreen(),
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

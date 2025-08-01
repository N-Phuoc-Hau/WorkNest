import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/applications/screens/my_applications_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/candidate/screens/candidate_home_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/screens/start_chat_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart'; // Added
import '../../features/dashboard/screens/candidate_dashboard_screen.dart'; // Added
import '../../features/dashboard/screens/guest_dashboard_screen.dart'; // Added
import '../../features/dashboard/screens/recruiter_dashboard_screen.dart'; // Added
import '../../features/favorites/screens/favorite_screen.dart';
import '../../features/job_posting/screens/create_job_screen.dart';
import '../../features/job_posting/screens/edit_job_screen.dart';
import '../../features/job_posting/screens/manage_jobs_screen.dart';
import '../../features/jobs/screens/job_detail_screen.dart';
import '../../features/jobs/screens/job_list_screen.dart';
import '../../features/navigation/screens/main_navigation_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/recruiter/screens/recruiter_home_screen.dart';
import '../../features/reviews/screens/candidate_review_screen.dart';
import '../../features/reviews/screens/company_review_screen.dart';
import '../../features/reviews/screens/review_list_screen.dart';
import '../../features/search/screens/advanced_search_screen.dart'; // Added
import '../../features/splash/splash_screen.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.uri.toString();
      
      // If loading, stay on splash
      if (isLoading) {
        return '/splash';
      }
      
      // Allow access to public routes when not authenticated
      final publicRoutes = [
        '/login', 
        '/register', 
        '/onboarding', 
        '/splash',
        '/main',              // Allow main navigation
        '/guest-dashboard',   // Allow guest dashboard
        '/jobs',              // Allow job list view
        '/jobs/',             // Allow job detail view (but with limited features)
      ];
      
      // Check if current location is a job detail route
      final isJobDetailRoute = RegExp(r'^/jobs/\d+$').hasMatch(location);
      
      // If not authenticated and trying to access protected routes, go to guest dashboard
      if (!isAuthenticated && 
          !publicRoutes.any((route) => location.startsWith(route)) &&
          !isJobDetailRoute) {
        return '/guest-dashboard';
      }
      
      // If authenticated and on auth screens, redirect to appropriate dashboard
      if (isAuthenticated && 
          (location == '/login' || 
           location == '/register' || 
           location == '/onboarding' ||
           location == '/splash')) {
        // Redirect to appropriate dashboard based on user role
        final user = authState.user;
        if (user != null) {
          if (user.role == 'Admin') {
            return '/admin-dashboard';
          } else if (user.isRecruiter) {
            return '/recruiter-dashboard';
          } else {
            return '/candidate-dashboard';
          }
        }
        return '/candidate-dashboard'; // Default fallback
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Global public routes (accessible without authentication)
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final jobId = int.parse(state.pathParameters['id']!);
              return JobDetailScreen(jobId: jobId);
            },
          ),
        ],
      ),
      
      GoRoute(
        path: '/candidate',
        builder: (context, state) => const CandidateHomeScreen(),
        routes: [
          GoRoute(
            path: 'favorites',
            builder: (context, state) => const FavoriteScreen(),
          ),
          GoRoute(
            path: 'applications',
            builder: (context, state) => const MyApplicationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/recruiter',
        builder: (context, state) => const RecruiterHomeScreen(),
        routes: [
          GoRoute(
            path: 'manage-jobs',
            builder: (context, state) => const ManageJobsScreen(),
          ),
        ],
      ),
      // Global recruiter routes (accessible from any context)
      GoRoute(
        path: '/create-job',
        builder: (context, state) => const CreateJobScreen(),
      ),
      GoRoute(
        path: '/edit-job/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return EditJobScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/manage-jobs',
        builder: (context, state) => const ManageJobsScreen(),
      ),
      // Review routes
      GoRoute(
        path: '/company-review/:companyId/:companyName',
        builder: (context, state) {
          final companyId = int.parse(state.pathParameters['companyId']!);
          final companyName = state.pathParameters['companyName']!;
          return CompanyReviewScreen(
            companyId: companyId,
            companyName: Uri.decodeComponent(companyName),
          );
        },
      ),
      GoRoute(
        path: '/candidate-review/:candidateId/:candidateName',
        builder: (context, state) {
          final candidateId = state.pathParameters['candidateId']!;
          final candidateName = state.pathParameters['candidateName']!;
          return CandidateReviewScreen(
            candidateId: candidateId,
            candidateName: Uri.decodeComponent(candidateName),
          );
        },
      ),
      GoRoute(
        path: '/reviews',
        builder: (context, state) {
          final companyId = state.uri.queryParameters['companyId'];
          final companyName = state.uri.queryParameters['companyName'];
          final showMyReviews = state.uri.queryParameters['showMyReviews'] == 'true';
          
          return ReviewListScreen(
            companyId: companyId != null ? int.tryParse(companyId) : null,
            companyName: companyName != null ? Uri.decodeComponent(companyName) : null,
            showMyReviews: showMyReviews,
          );
        },
      ),
      // Chat routes
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final otherUserInfo = state.uri.queryParameters['otherUserInfo'] != null 
              ? Map<String, dynamic>.from(
                  state.uri.queryParameters['otherUserInfo'] as Map<String, dynamic>
                )
              : null;
          final jobInfo = state.uri.queryParameters['jobInfo'] != null 
              ? Map<String, dynamic>.from(
                  state.uri.queryParameters['jobInfo'] as Map<String, dynamic>
                )
              : null;
          
          return ChatScreen(
            roomId: roomId,
            otherUserInfo: otherUserInfo,
            jobInfo: jobInfo,
          );
        },
      ),
      GoRoute(
        path: '/start-chat',
        builder: (context, state) => const StartChatScreen(),
      ),
                 // Notification routes
           GoRoute(
             path: '/notifications',
             builder: (context, state) => const NotificationScreen(),
           ),
           // Search routes
           GoRoute(
             path: '/search',
             builder: (context, state) => const AdvancedSearchScreen(),
           ),
           // Dashboard routes
           GoRoute(
             path: '/guest-dashboard',
             builder: (context, state) => const GuestDashboardScreen(),
           ),
           GoRoute(
             path: '/admin-dashboard',
             builder: (context, state) => const AdminDashboardScreen(),
           ),
           GoRoute(
             path: '/recruiter-dashboard',
             builder: (context, state) => const RecruiterDashboardScreen(),
           ),
           GoRoute(
             path: '/candidate-dashboard',
             builder: (context, state) => const CandidateDashboardScreen(),
           ),
    ],
  );
});
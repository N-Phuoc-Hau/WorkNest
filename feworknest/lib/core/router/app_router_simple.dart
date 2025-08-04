// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';

// import '../../features/auth/screens/login_screen.dart';
// import '../../features/auth/screens/register_screen.dart';
// import '../../features/candidate/screens/candidate_home_screen.dart';
// import '../../features/recruiter/screens/recruiter_home_screen.dart';
// import '../../features/jobs/screens/job_list_screen.dart';
// import '../../features/jobs/screens/job_detail_screen.dart';
// import '../../features/landing/landing_page.dart';
// import '../providers/auth_provider.dart';

// final routerProvider = Provider<GoRouter>((ref) {
//   final authState = ref.watch(authProvider);

//   return GoRouter(
//     initialLocation: '/',
//     redirect: (context, state) {
//       final isLoggedIn = authState.isAuthenticated;
//       final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';

//       // If not logged in and trying to access protected routes
//       if (!isLoggedIn && !isLoggingIn && state.uri.path != '/' && !state.uri.path.startsWith('/job-detail')) {
//         return '/login';
//       }

//       // If logged in and trying to access auth pages
//       if (isLoggedIn && isLoggingIn) {
//         final userRole = authState.user?.role;
//         if (userRole == 'candidate') {
//           return '/candidate/home';
//         } else if (userRole == 'recruiter') {
//           return '/recruiter/home';
//         }
//         return '/';
//       }

//       return null;
//     },
//     routes: [
//       // Public Routes
//       GoRoute(
//         path: '/',
//         name: 'landing',
//         builder: (context, state) => const LandingPage(),
//       ),
//       GoRoute(
//         path: '/login',
//         name: 'login',
//         builder: (context, state) => const LoginScreen(),
//       ),
//       GoRoute(
//         path: '/register',
//         name: 'register',
//         builder: (context, state) => const RegisterScreen(),
//       ),
//       GoRoute(
//         path: '/jobs',
//         name: 'jobs',
//         builder: (context, state) => const JobListScreen(),
//       ),
//       GoRoute(
//         path: '/job-detail/:id',
//         name: 'job-detail',
//         builder: (context, state) {
//           final jobId = state.pathParameters['id']!;
//           return JobDetailScreen(jobId: jobId);
//         },
//       ),

//       // Candidate Routes
//       GoRoute(
//         path: '/candidate/home',
//         name: 'candidate-home',
//         builder: (context, state) => const CandidateHomeScreen(),
//       ),
//       GoRoute(
//         path: '/candidate/jobs',
//         name: 'candidate-jobs',
//         builder: (context, state) {
//           final search = state.uri.queryParameters['search'];
//           return CandidateJobsScreen(initialSearch: search);
//         },
//       ),
//       GoRoute(
//         path: '/candidate/favorites',
//         name: 'candidate-favorites',
//         builder: (context, state) => const CandidateFavoritesScreen(),
//       ),
//       GoRoute(
//         path: '/candidate/applications',
//         name: 'candidate-applications',
//         builder: (context, state) => const CandidateApplicationsScreen(),
//       ),
//       GoRoute(
//         path: '/candidate/profile',
//         name: 'candidate-profile',
//         builder: (context, state) => const CandidateProfileScreen(),
//       ),
//       GoRoute(
//         path: '/candidate/chat',
//         name: 'candidate-chat',
//         builder: (context, state) => const CandidateChatScreen(),
//       ),
//       GoRoute(
//         path: '/candidate/settings',
//         name: 'candidate-settings',
//         builder: (context, state) => const CandidateSettingsScreen(),
//       ),

//       // Recruiter Routes
//       GoRoute(
//         path: '/recruiter/home',
//         name: 'recruiter-home',
//         builder: (context, state) => const RecruiterHomeScreen(),
//       ),
//       GoRoute(
//         path: '/recruiter/post-job',
//         name: 'post-job',
//         builder: (context, state) => const PostJobScreen(),
//       ),
//       GoRoute(
//         path: '/recruiter/jobs',
//         name: 'recruiter-jobs',
//         builder: (context, state) => const RecruiterJobsScreen(),
//       ),
//       GoRoute(
//         path: '/recruiter/applicants',
//         name: 'recruiter-applicants',
//         builder: (context, state) => const RecruiterApplicantsScreen(),
//       ),
//       GoRoute(
//         path: '/recruiter/chat',
//         name: 'recruiter-chat',
//         builder: (context, state) => const RecruiterChatScreen(),
//       ),
//       GoRoute(
//         path: '/recruiter/company',
//         name: 'recruiter-company',
//         builder: (context, state) => const RecruiterCompanyScreen(),
//       ),
//       GoRoute(
//         path: '/recruiter/settings',
//         name: 'recruiter-settings',
//         builder: (context, state) => const RecruiterSettingsScreen(),
//       ),
//     ],
//     errorBuilder: (context, state) => Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.error_outline,
//               size: 64,
//               color: Colors.red,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Không tìm thấy trang',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Đường dẫn "${state.uri.path}" không tồn tại',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => context.go('/'),
//               child: const Text('Về trang chủ'),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// });

// // Placeholder screens - cần implement sau
// class CandidateJobsScreen extends StatelessWidget {
//   final String? initialSearch;
//   const CandidateJobsScreen({super.key, this.initialSearch});

//   @override
//   Widget build(BuildContext context) {
//     return const JobListScreen(); // Reuse existing JobListScreen
//   }
// }

// class CandidateFavoritesScreen extends StatelessWidget {
//   const CandidateFavoritesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Việc làm yêu thích')),
//       body: const Center(child: Text('Favorite Jobs Screen')),
//     );
//   }
// }

// class CandidateApplicationsScreen extends StatelessWidget {
//   const CandidateApplicationsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Hồ sơ ứng tuyển')),
//       body: const Center(child: Text('Applications Screen')),
//     );
//   }
// }

// class CandidateProfileScreen extends StatelessWidget {
//   const CandidateProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
//       body: const Center(child: Text('Profile Screen')),
//     );
//   }
// }

// class CandidateChatScreen extends StatelessWidget {
//   const CandidateChatScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Tin nhắn')),
//       body: const Center(child: Text('Chat Screen')),
//     );
//   }
// }

// class CandidateSettingsScreen extends StatelessWidget {
//   const CandidateSettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Cài đặt')),
//       body: const Center(child: Text('Settings Screen')),
//     );
//   }
// }

// class PostJobScreen extends StatelessWidget {
//   const PostJobScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Đăng tin tuyển dụng')),
//       body: const Center(child: Text('Post Job Screen')),
//     );
//   }
// }

// class RecruiterJobsScreen extends StatelessWidget {
//   const RecruiterJobsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Quản lý tin tuyển dụng')),
//       body: const Center(child: Text('Recruiter Jobs Screen')),
//     );
//   }
// }

// class RecruiterApplicantsScreen extends StatelessWidget {
//   const RecruiterApplicantsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Ứng viên')),
//       body: const Center(child: Text('Applicants Screen')),
//     );
//   }
// }

// class RecruiterChatScreen extends StatelessWidget {
//   const RecruiterChatScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Tin nhắn')),
//       body: const Center(child: Text('Recruiter Chat Screen')),
//     );
//   }
// }

// class RecruiterCompanyScreen extends StatelessWidget {
//   const RecruiterCompanyScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Trang công ty')),
//       body: const Center(child: Text('Company Screen')),
//     );
//   }
// }

// class RecruiterSettingsScreen extends StatelessWidget {
//   const RecruiterSettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Cài đặt')),
//       body: const Center(child: Text('Recruiter Settings Screen')),
//     );
//   }
// }

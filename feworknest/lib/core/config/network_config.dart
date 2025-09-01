class NetworkConfig {
  // For development - bypass SSL certificate validation
  static bool get isDevelopment => const bool.fromEnvironment('dart.vm.product') == false;
  
  // Use HTTP for localhost in development
  static String get baseUrl {
    if (isDevelopment) {
      // return 'http://192.168.0.161:7777'; // Updated to match backend port
      // return 'http://localhost:5006';
      return 'http://192.168.1.20:7777';
    }
    return 'https://your-production-domain.com'; // HTTPS for production
  }
  
  // API endpoints
  static const String loginEndpoint = '/api/Auth/login';
  static const String registerCandidateEndpoint = '/api/Auth/register-candidate';
  static const String registerRecruiterEndpoint = '/api/Auth/register-recruiter';
  static const String profileEndpoint = '/api/Auth/profile';
  static const String jobsEndpoint = '/api/JobPost';
}

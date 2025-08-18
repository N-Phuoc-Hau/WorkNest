import '../config/network_config.dart';

class ApiConstants {
  static String get baseUrl => NetworkConfig.baseUrl; // Dynamic base URL
  
  // Auth endpoints
  static const String login = '/api/Auth/login';
  static const String registerCandidate = '/api/Auth/register/candidate';
  static const String registerRecruiter = '/api/Auth/register/recruiter';
  static const String profile = '/api/Auth/profile';
  static const String tokenStatus = '/api/Auth/token-status';
  static const String refreshToken = '/api/Auth/refresh-token';
  static const String revokeToken = '/api/Auth/revoke-token';
  static const String revokeAllTokens = '/api/Auth/revoke-all-tokens';
  
  // Guide endpoints
  static const String appGuide = '/api/Guide/app-guide';
  static const String apiDocumentation = '/api/Guide/api-documentation';
  
  // Job endpoints
  static const String jobs = '/api/JobPost';
  static const String myJobs = '/api/JobPost/my-jobs';
  
  // Application endpoints
  static const String applications = '/api/Application';
  static const String myApplications = '/api/Application/my-applications';
  
  // Favorite endpoints
  static const String favorites = '/api/Favorite';
  static const String myFavorites = '/api/Favorite/my-favorites';
  static const String favoriteStats = '/api/Favorite/stats';
  
  // Follow endpoints
  static const String follow = '/api/Follow';
  static const String myFollowing = '/api/Follow/my-following';
  static const String followers = '/api/Follow/followers';
  
  // Review endpoints
  static const String reviews = '/api/Review';
  static const String candidateReview = '/api/Review/candidate-review';
  static const String recruiterReview = '/api/Review/recruiter-review';
  static const String myReviews = '/api/Review/my-reviews';
  
  // Notification endpoints
  static const String notifications = '/api/Notification';
  static const String markAsRead = '/api/Notification/mark-read';
  static const String markAllAsRead = '/api/Notification/mark-all-read';
  static const String unreadCount = '/api/Notification/unread-count';
  static const String deviceToken = '/api/Notification/device-token';
  static const String myDevices = '/api/Notification/my-devices';
  
  // Chat endpoints - Updated to match new ChatController
  static const String chatRooms = '/api/Chat/rooms';
  static const String createChatRoom = '/api/Chat/rooms';
  static const String getChatMessages = '/api/Chat/rooms'; // /api/Chat/rooms/{roomId}/messages
  static const String sendTextMessage = '/api/Chat/messages/text';
  static const String sendImageMessage = '/api/Chat/messages/image';
  static const String markChatAsRead = '/api/Chat/rooms'; // /api/Chat/rooms/{roomId}/mark-read
  static const String deleteChatRoom = '/api/Chat/rooms'; // /api/Chat/rooms/{roomId}
  static const String getChatRoomInfo = '/api/Chat/rooms'; // /api/Chat/rooms/{roomId}
  
  // Company endpoints
  static const String companies = '/api/Company';
  
  // Search endpoints
  static const String searchSuggestions = '/api/Search/suggestions';
  static const String searchFilters = '/api/Search/filters';
  static const String searchJobs = '/api/Search/jobs';
  static const String jobRecommendations = '/api/Search/job-recommendations';
  static const String candidateRecommendations = '/api/Search/candidate-recommendations';
  static const String searchHistory = '/api/Search/search-history';
  static const String saveSearch = '/api/Search/save-search';
  
  // Dashboard endpoints
  static const String adminDashboard = '/api/Dashboard/admin';
  static const String recruiterDashboard = '/api/Dashboard/recruiter';
  static const String candidateDashboard = '/api/Dashboard/candidate';
  static const String trackEvent = '/api/Dashboard/track';
  
  
  // Interview endpoints
  static const String scheduleInterview = '/api/Interview/schedule';
  static const String myInterviews = '/api/Interview/my-interviews';
  static const String updateInterviewStatus = '/api/Interview'; // /api/Interview/{id}/status
  static const String getInterview = '/api/Interview'; // /api/Interview/{id}
  
  // Upload endpoints
  static const String uploadAvatar = '/api/Upload/avatar';
  static const String uploadImage = '/api/Upload/image';
  static const String uploadImages = '/api/Upload/images';
  static const String uploadPdf = '/api/Upload/pdf';
  static const String uploadCv = '/api/Upload/cv';
  static const String uploadFile = '/api/Upload/file';
  
  // Public upload endpoints (no authentication required)
  static const String publicUploadAvatar = '/api/Upload/avatar';
  static const String publicUploadImage = '/api/Upload/image';
  static const String publicUploadImages = '/api/Upload/images';
}

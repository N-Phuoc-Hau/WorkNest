class DetailedAnalytics {
  final RecruiterAnalytics recruiter;
  final CompanyAnalytics company;
  final JobAnalytics jobs;
  final DateTime generatedAt;

  DetailedAnalytics({
    required this.recruiter,
    required this.company,
    required this.jobs,
    required this.generatedAt,
  });

  factory DetailedAnalytics.fromJson(Map<String, dynamic> json) {
    return DetailedAnalytics(
      recruiter: RecruiterAnalytics.fromJson(json['recruiter'] ?? {}),
      company: CompanyAnalytics.fromJson(json['company'] ?? {}),
      jobs: JobAnalytics.fromJson(json['jobs'] ?? {}),
      generatedAt: json['generatedAt'] != null 
          ? DateTime.parse(json['generatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recruiter': recruiter.toJson(),
      'company': company.toJson(),
      'jobs': jobs.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class RecruiterAnalytics {
  final int totalJobsPosted;
  final int activeJobs;
  final int inactiveJobs;
  final int totalApplicationsReceived;
  final int pendingApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final int totalJobViews;
  final int uniqueJobViewers;
  final int companyFollowers;
  final double averageApplicationsPerJob;
  final double averageViewsPerJob;
  final double applicationToViewRatio;
  final List<JobDetailedPerformance> jobPerformance;
  final List<ChartData> applicationsByMonth;
  final List<ChartData> viewsByMonth;
  final List<ChartData> topJobCategories;
  final List<ChartData> applicationStatusDistribution;
  final List<FollowerInfo> recentFollowers;

  RecruiterAnalytics({
    required this.totalJobsPosted,
    required this.activeJobs,
    required this.inactiveJobs,
    required this.totalApplicationsReceived,
    required this.pendingApplications,
    required this.acceptedApplications,
    required this.rejectedApplications,
    required this.totalJobViews,
    required this.uniqueJobViewers,
    required this.companyFollowers,
    required this.averageApplicationsPerJob,
    required this.averageViewsPerJob,
    required this.applicationToViewRatio,
    required this.jobPerformance,
    required this.applicationsByMonth,
    required this.viewsByMonth,
    required this.topJobCategories,
    required this.applicationStatusDistribution,
    required this.recentFollowers,
  });

  factory RecruiterAnalytics.fromJson(Map<String, dynamic> json) {
    return RecruiterAnalytics(
      totalJobsPosted: json['totalJobsPosted'] ?? 0,
      activeJobs: json['activeJobs'] ?? 0,
      inactiveJobs: json['inactiveJobs'] ?? 0,
      totalApplicationsReceived: json['totalApplicationsReceived'] ?? 0,
      pendingApplications: json['pendingApplications'] ?? 0,
      acceptedApplications: json['acceptedApplications'] ?? 0,
      rejectedApplications: json['rejectedApplications'] ?? 0,
      totalJobViews: json['totalJobViews'] ?? 0,
      uniqueJobViewers: json['uniqueJobViewers'] ?? 0,
      companyFollowers: json['companyFollowers'] ?? 0,
      averageApplicationsPerJob: (json['averageApplicationsPerJob'] ?? 0).toDouble(),
      averageViewsPerJob: (json['averageViewsPerJob'] ?? 0).toDouble(),
      applicationToViewRatio: (json['applicationToViewRatio'] ?? 0).toDouble(),
      jobPerformance: (json['jobPerformance'] as List<dynamic>? ?? [])
          .map((item) => JobDetailedPerformance.fromJson(item))
          .toList(),
      applicationsByMonth: (json['applicationsByMonth'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      viewsByMonth: (json['viewsByMonth'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      topJobCategories: (json['topJobCategories'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      applicationStatusDistribution: (json['applicationStatusDistribution'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      recentFollowers: (json['recentFollowers'] as List<dynamic>? ?? [])
          .map((item) => FollowerInfo.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalJobsPosted': totalJobsPosted,
      'activeJobs': activeJobs,
      'inactiveJobs': inactiveJobs,
      'totalApplicationsReceived': totalApplicationsReceived,
      'pendingApplications': pendingApplications,
      'acceptedApplications': acceptedApplications,
      'rejectedApplications': rejectedApplications,
      'totalJobViews': totalJobViews,
      'uniqueJobViewers': uniqueJobViewers,
      'companyFollowers': companyFollowers,
      'averageApplicationsPerJob': averageApplicationsPerJob,
      'averageViewsPerJob': averageViewsPerJob,
      'applicationToViewRatio': applicationToViewRatio,
      'jobPerformance': jobPerformance.map((item) => item.toJson()).toList(),
      'applicationsByMonth': applicationsByMonth.map((item) => item.toJson()).toList(),
      'viewsByMonth': viewsByMonth.map((item) => item.toJson()).toList(),
      'topJobCategories': topJobCategories.map((item) => item.toJson()).toList(),
      'applicationStatusDistribution': applicationStatusDistribution.map((item) => item.toJson()).toList(),
      'recentFollowers': recentFollowers.map((item) => item.toJson()).toList(),
    };
  }
}

class CompanyAnalytics {
  final int companyId;
  final String companyName;
  final String companyLocation;
  final bool isVerified;
  final int totalFollowers;
  final int newFollowersThisMonth;
  final int totalJobsPosted;
  final int totalApplicationsReceived;
  final DateTime companyCreatedAt;
  final List<ChartData> followerGrowth;
  final List<CompanyReview> recentReviews;
  final double averageRating;
  final int totalReviews;

  CompanyAnalytics({
    required this.companyId,
    required this.companyName,
    required this.companyLocation,
    required this.isVerified,
    required this.totalFollowers,
    required this.newFollowersThisMonth,
    required this.totalJobsPosted,
    required this.totalApplicationsReceived,
    required this.companyCreatedAt,
    required this.followerGrowth,
    required this.recentReviews,
    required this.averageRating,
    required this.totalReviews,
  });

  factory CompanyAnalytics.fromJson(Map<String, dynamic> json) {
    return CompanyAnalytics(
      companyId: json['companyId'] ?? 0,
      companyName: json['companyName'] ?? '',
      companyLocation: json['companyLocation'] ?? '',
      isVerified: json['isVerified'] ?? false,
      totalFollowers: json['totalFollowers'] ?? 0,
      newFollowersThisMonth: json['newFollowersThisMonth'] ?? 0,
      totalJobsPosted: json['totalJobsPosted'] ?? 0,
      totalApplicationsReceived: json['totalApplicationsReceived'] ?? 0,
      companyCreatedAt: DateTime.parse(json['companyCreatedAt'] ?? DateTime.now().toIso8601String()),
      followerGrowth: (json['followerGrowth'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      recentReviews: (json['recentReviews'] as List<dynamic>? ?? [])
          .map((item) => CompanyReview.fromJson(item))
          .toList(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'companyLocation': companyLocation,
      'isVerified': isVerified,
      'totalFollowers': totalFollowers,
      'newFollowersThisMonth': newFollowersThisMonth,
      'totalJobsPosted': totalJobsPosted,
      'totalApplicationsReceived': totalApplicationsReceived,
      'companyCreatedAt': companyCreatedAt.toIso8601String(),
      'followerGrowth': followerGrowth.map((item) => item.toJson()).toList(),
      'recentReviews': recentReviews.map((item) => item.toJson()).toList(),
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }
}

class JobAnalytics {
  final List<JobDetailedPerformance> allJobs;
  final JobDetailedPerformance? bestPerformingJob;
  final JobDetailedPerformance? mostViewedJob;
  final JobDetailedPerformance? mostAppliedJob;
  final List<ChartData> jobsByCategory;
  final List<ChartData> jobsByLocation;
  final List<ChartData> jobsByExperienceLevel;
  final List<ChartData> salaryDistribution;

  JobAnalytics({
    required this.allJobs,
    this.bestPerformingJob,
    this.mostViewedJob,
    this.mostAppliedJob,
    required this.jobsByCategory,
    required this.jobsByLocation,
    required this.jobsByExperienceLevel,
    required this.salaryDistribution,
  });

  factory JobAnalytics.fromJson(Map<String, dynamic> json) {
    return JobAnalytics(
      allJobs: (json['allJobs'] as List<dynamic>? ?? [])
          .map((item) => JobDetailedPerformance.fromJson(item))
          .toList(),
      bestPerformingJob: json['bestPerformingJob'] != null 
          ? JobDetailedPerformance.fromJson(json['bestPerformingJob'])
          : null,
      mostViewedJob: json['mostViewedJob'] != null 
          ? JobDetailedPerformance.fromJson(json['mostViewedJob'])
          : null,
      mostAppliedJob: json['mostAppliedJob'] != null 
          ? JobDetailedPerformance.fromJson(json['mostAppliedJob'])
          : null,
      jobsByCategory: (json['jobsByCategory'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      jobsByLocation: (json['jobsByLocation'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      jobsByExperienceLevel: (json['jobsByExperienceLevel'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      salaryDistribution: (json['salaryDistribution'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allJobs': allJobs.map((item) => item.toJson()).toList(),
      'bestPerformingJob': bestPerformingJob?.toJson(),
      'mostViewedJob': mostViewedJob?.toJson(),
      'mostAppliedJob': mostAppliedJob?.toJson(),
      'jobsByCategory': jobsByCategory.map((item) => item.toJson()).toList(),
      'jobsByLocation': jobsByLocation.map((item) => item.toJson()).toList(),
      'jobsByExperienceLevel': jobsByExperienceLevel.map((item) => item.toJson()).toList(),
      'salaryDistribution': salaryDistribution.map((item) => item.toJson()).toList(),
    };
  }
}

class JobDetailedPerformance {
  final int jobId;
  final String jobTitle;
  final String jobCategory;
  final String jobLocation;
  final String experienceLevel;
  final double salary;
  final DateTime postedDate;
  final DateTime? deadLine;
  final bool isActive;
  final int totalViews;
  final int uniqueViews;
  final int totalApplications;
  final int pendingApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final double viewToApplicationRatio;
  final double acceptanceRate;
  final int favoriteCount;
  final List<ChartData> viewsByDay;
  final List<ChartData> applicationsByDay;
  final List<ApplicantInfo> recentApplicants;

  JobDetailedPerformance({
    required this.jobId,
    required this.jobTitle,
    required this.jobCategory,
    required this.jobLocation,
    required this.experienceLevel,
    required this.salary,
    required this.postedDate,
    this.deadLine,
    required this.isActive,
    required this.totalViews,
    required this.uniqueViews,
    required this.totalApplications,
    required this.pendingApplications,
    required this.acceptedApplications,
    required this.rejectedApplications,
    required this.viewToApplicationRatio,
    required this.acceptanceRate,
    required this.favoriteCount,
    required this.viewsByDay,
    required this.applicationsByDay,
    required this.recentApplicants,
  });

  factory JobDetailedPerformance.fromJson(Map<String, dynamic> json) {
    return JobDetailedPerformance(
      jobId: json['jobId'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobCategory: json['jobCategory'] ?? '',
      jobLocation: json['jobLocation'] ?? '',
      experienceLevel: json['experienceLevel'] ?? '',
      salary: (json['salary'] ?? 0).toDouble(),
      postedDate: DateTime.parse(json['postedDate'] ?? DateTime.now().toIso8601String()),
      deadLine: json['deadLine'] != null ? DateTime.parse(json['deadLine']) : null,
      isActive: json['isActive'] ?? false,
      totalViews: json['totalViews'] ?? 0,
      uniqueViews: json['uniqueViews'] ?? 0,
      totalApplications: json['totalApplications'] ?? 0,
      pendingApplications: json['pendingApplications'] ?? 0,
      acceptedApplications: json['acceptedApplications'] ?? 0,
      rejectedApplications: json['rejectedApplications'] ?? 0,
      viewToApplicationRatio: (json['viewToApplicationRatio'] ?? 0).toDouble(),
      acceptanceRate: (json['acceptanceRate'] ?? 0).toDouble(),
      favoriteCount: json['favoriteCount'] ?? 0,
      viewsByDay: (json['viewsByDay'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      applicationsByDay: (json['applicationsByDay'] as List<dynamic>? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      recentApplicants: (json['recentApplicants'] as List<dynamic>? ?? [])
          .map((item) => ApplicantInfo.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'jobCategory': jobCategory,
      'jobLocation': jobLocation,
      'experienceLevel': experienceLevel,
      'salary': salary,
      'postedDate': postedDate.toIso8601String(),
      'deadLine': deadLine?.toIso8601String(),
      'isActive': isActive,
      'totalViews': totalViews,
      'uniqueViews': uniqueViews,
      'totalApplications': totalApplications,
      'pendingApplications': pendingApplications,
      'acceptedApplications': acceptedApplications,
      'rejectedApplications': rejectedApplications,
      'viewToApplicationRatio': viewToApplicationRatio,
      'acceptanceRate': acceptanceRate,
      'favoriteCount': favoriteCount,
      'viewsByDay': viewsByDay.map((item) => item.toJson()).toList(),
      'applicationsByDay': applicationsByDay.map((item) => item.toJson()).toList(),
      'recentApplicants': recentApplicants.map((item) => item.toJson()).toList(),
    };
  }
}

class ChartData {
  final String label;
  final double value;
  final String? color;

  ChartData({
    required this.label,
    required this.value,
    this.color,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color,
    };
  }
}

class FollowerInfo {
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final DateTime followedDate;

  FollowerInfo({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.followedDate,
  });

  factory FollowerInfo.fromJson(Map<String, dynamic> json) {
    return FollowerInfo(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userAvatar: json['userAvatar'],
      followedDate: DateTime.parse(json['followedDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatar': userAvatar,
      'followedDate': followedDate.toIso8601String(),
    };
  }
}

class ApplicantInfo {
  final int applicationId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String applicationStatus;
  final DateTime appliedDate;
  final String? cvUrl;
  final String? coverLetter;

  ApplicantInfo({
    required this.applicationId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.applicationStatus,
    required this.appliedDate,
    this.cvUrl,
    this.coverLetter,
  });

  factory ApplicantInfo.fromJson(Map<String, dynamic> json) {
    return ApplicantInfo(
      applicationId: json['applicationId'] ?? 0,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userAvatar: json['userAvatar'],
      applicationStatus: json['applicationStatus'] ?? '',
      appliedDate: DateTime.parse(json['appliedDate'] ?? DateTime.now().toIso8601String()),
      cvUrl: json['cvUrl'],
      coverLetter: json['coverLetter'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatar': userAvatar,
      'applicationStatus': applicationStatus,
      'appliedDate': appliedDate.toIso8601String(),
      'cvUrl': cvUrl,
      'coverLetter': coverLetter,
    };
  }
}

class CompanyReview {
  final int reviewId;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime reviewDate;

  CompanyReview({
    required this.reviewId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.reviewDate,
  });

  factory CompanyReview.fromJson(Map<String, dynamic> json) {
    return CompanyReview(
      reviewId: json['reviewId'] ?? 0,
      reviewerName: json['reviewerName'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      reviewDate: DateTime.parse(json['reviewDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'reviewDate': reviewDate.toIso8601String(),
    };
  }
}

class AnalyticsSummary {
  final CompanyInfo companyInfo;
  final JobStats jobStats;
  final ApplicationStats applicationStats;
  final Performance performance;

  AnalyticsSummary({
    required this.companyInfo,
    required this.jobStats,
    required this.applicationStats,
    required this.performance,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      companyInfo: CompanyInfo.fromJson(json['companyInfo'] ?? {}),
      jobStats: JobStats.fromJson(json['jobStats'] ?? {}),
      applicationStats: ApplicationStats.fromJson(json['applicationStats'] ?? {}),
      performance: Performance.fromJson(json['performance'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyInfo': companyInfo.toJson(),
      'jobStats': jobStats.toJson(),
      'applicationStats': applicationStats.toJson(),
      'performance': performance.toJson(),
    };
  }
}

class CompanyInfo {
  final String companyName;
  final String companyLocation;
  final bool isVerified;
  final int totalFollowers;
  final double averageRating;
  final int totalReviews;

  CompanyInfo({
    required this.companyName,
    required this.companyLocation,
    required this.isVerified,
    required this.totalFollowers,
    required this.averageRating,
    required this.totalReviews,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      companyName: json['companyName'] ?? '',
      companyLocation: json['companyLocation'] ?? '',
      isVerified: json['isVerified'] ?? false,
      totalFollowers: json['totalFollowers'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyLocation': companyLocation,
      'isVerified': isVerified,
      'totalFollowers': totalFollowers,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }
}

class JobStats {
  final int totalJobsPosted;
  final int activeJobs;
  final int inactiveJobs;
  final double averageViewsPerJob;
  final double averageApplicationsPerJob;

  JobStats({
    required this.totalJobsPosted,
    required this.activeJobs,
    required this.inactiveJobs,
    required this.averageViewsPerJob,
    required this.averageApplicationsPerJob,
  });

  factory JobStats.fromJson(Map<String, dynamic> json) {
    return JobStats(
      totalJobsPosted: json['totalJobsPosted'] ?? 0,
      activeJobs: json['activeJobs'] ?? 0,
      inactiveJobs: json['inactiveJobs'] ?? 0,
      averageViewsPerJob: (json['averageViewsPerJob'] ?? 0).toDouble(),
      averageApplicationsPerJob: (json['averageApplicationsPerJob'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalJobsPosted': totalJobsPosted,
      'activeJobs': activeJobs,
      'inactiveJobs': inactiveJobs,
      'averageViewsPerJob': averageViewsPerJob,
      'averageApplicationsPerJob': averageApplicationsPerJob,
    };
  }
}

class ApplicationStats {
  final int totalApplicationsReceived;
  final int pendingApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final double applicationToViewRatio;

  ApplicationStats({
    required this.totalApplicationsReceived,
    required this.pendingApplications,
    required this.acceptedApplications,
    required this.rejectedApplications,
    required this.applicationToViewRatio,
  });

  factory ApplicationStats.fromJson(Map<String, dynamic> json) {
    return ApplicationStats(
      totalApplicationsReceived: json['totalApplicationsReceived'] ?? 0,
      pendingApplications: json['pendingApplications'] ?? 0,
      acceptedApplications: json['acceptedApplications'] ?? 0,
      rejectedApplications: json['rejectedApplications'] ?? 0,
      applicationToViewRatio: (json['applicationToViewRatio'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalApplicationsReceived': totalApplicationsReceived,
      'pendingApplications': pendingApplications,
      'acceptedApplications': acceptedApplications,
      'rejectedApplications': rejectedApplications,
      'applicationToViewRatio': applicationToViewRatio,
    };
  }
}

class Performance {
  final JobDetailedPerformance? bestJob;
  final JobDetailedPerformance? mostViewed;
  final JobDetailedPerformance? mostApplied;

  Performance({
    this.bestJob,
    this.mostViewed,
    this.mostApplied,
  });

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      bestJob: json['bestJob'] != null ? JobDetailedPerformance.fromJson(json['bestJob']) : null,
      mostViewed: json['mostViewed'] != null ? JobDetailedPerformance.fromJson(json['mostViewed']) : null,
      mostApplied: json['mostApplied'] != null ? JobDetailedPerformance.fromJson(json['mostApplied']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bestJob': bestJob?.toJson(),
      'mostViewed': mostViewed?.toJson(),
      'mostApplied': mostApplied?.toJson(),
    };
  }
}

// Simple job model for summary analytics (without heavy chart data)
class JobSummary {
  final int jobId;
  final String jobTitle;
  final String jobCategory;
  final String jobLocation;
  final String experienceLevel;
  final double salary;
  final DateTime postedDate;
  final DateTime deadLine;
  final bool isActive;
  final int totalViews;
  final int uniqueViews;
  final int totalApplications;
  final int pendingApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final double viewToApplicationRatio;
  final double acceptanceRate;
  final int favoriteCount;

  JobSummary({
    required this.jobId,
    required this.jobTitle,
    required this.jobCategory,
    required this.jobLocation,
    required this.experienceLevel,
    required this.salary,
    required this.postedDate,
    required this.deadLine,
    required this.isActive,
    required this.totalViews,
    required this.uniqueViews,
    required this.totalApplications,
    required this.pendingApplications,
    required this.acceptedApplications,
    required this.rejectedApplications,
    required this.viewToApplicationRatio,
    required this.acceptanceRate,
    required this.favoriteCount,
  });

  factory JobSummary.fromJson(Map<String, dynamic> json) {
    return JobSummary(
      jobId: json['jobId'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobCategory: json['jobCategory'] ?? '',
      jobLocation: json['jobLocation'] ?? '',
      experienceLevel: json['experienceLevel'] ?? '',
      salary: (json['salary'] ?? 0).toDouble(),
      postedDate: DateTime.parse(json['postedDate'] ?? DateTime.now().toIso8601String()),
      deadLine: DateTime.parse(json['deadLine'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? false,
      totalViews: json['totalViews'] ?? 0,
      uniqueViews: json['uniqueViews'] ?? 0,
      totalApplications: json['totalApplications'] ?? 0,
      pendingApplications: json['pendingApplications'] ?? 0,
      acceptedApplications: json['acceptedApplications'] ?? 0,
      rejectedApplications: json['rejectedApplications'] ?? 0,
      viewToApplicationRatio: (json['viewToApplicationRatio'] ?? 0).toDouble(),
      acceptanceRate: (json['acceptanceRate'] ?? 0).toDouble(),
      favoriteCount: json['favoriteCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'jobCategory': jobCategory,
      'jobLocation': jobLocation,
      'experienceLevel': experienceLevel,
      'salary': salary,
      'postedDate': postedDate.toIso8601String(),
      'deadLine': deadLine.toIso8601String(),
      'isActive': isActive,
      'totalViews': totalViews,
      'uniqueViews': uniqueViews,
      'totalApplications': totalApplications,
      'pendingApplications': pendingApplications,
      'acceptedApplications': acceptedApplications,
      'rejectedApplications': rejectedApplications,
      'viewToApplicationRatio': viewToApplicationRatio,
      'acceptanceRate': acceptanceRate,
      'favoriteCount': favoriteCount,
    };
  }
}

// Lightweight summary analytics model for home screen
class SummaryAnalytics {
  final CompanySummary companyInfo;
  final JobStats jobStats;
  final ApplicationStats applicationStats;
  final PerformanceSummary performance;

  SummaryAnalytics({
    required this.companyInfo,
    required this.jobStats,
    required this.applicationStats,
    required this.performance,
  });

  factory SummaryAnalytics.fromJson(Map<String, dynamic> json) {
    return SummaryAnalytics(
      companyInfo: CompanySummary.fromJson(json['companyInfo'] ?? {}),
      jobStats: JobStats.fromJson(json['jobStats'] ?? {}),
      applicationStats: ApplicationStats.fromJson(json['applicationStats'] ?? {}),
      performance: PerformanceSummary.fromJson(json['performance'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyInfo': companyInfo.toJson(),
      'jobStats': jobStats.toJson(),
      'applicationStats': applicationStats.toJson(),
      'performance': performance.toJson(),
    };
  }
}

class CompanySummary {
  final String companyName;
  final String companyLocation;
  final bool isVerified;
  final int totalFollowers;
  final double averageRating;
  final int totalReviews;

  CompanySummary({
    required this.companyName,
    required this.companyLocation,
    required this.isVerified,
    required this.totalFollowers,
    required this.averageRating,
    required this.totalReviews,
  });

  factory CompanySummary.fromJson(Map<String, dynamic> json) {
    return CompanySummary(
      companyName: json['companyName'] ?? '',
      companyLocation: json['companyLocation'] ?? '',
      isVerified: json['isVerified'] ?? false,
      totalFollowers: json['totalFollowers'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyLocation': companyLocation,
      'isVerified': isVerified,
      'totalFollowers': totalFollowers,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }
}

class PerformanceSummary {
  final JobSummary? bestJob;
  final JobSummary? mostViewed;
  final JobSummary? mostApplied;

  PerformanceSummary({
    this.bestJob,
    this.mostViewed,
    this.mostApplied,
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      bestJob: json['bestJob'] != null ? JobSummary.fromJson(json['bestJob']) : null,
      mostViewed: json['mostViewed'] != null ? JobSummary.fromJson(json['mostViewed']) : null,
      mostApplied: json['mostApplied'] != null ? JobSummary.fromJson(json['mostApplied']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bestJob': bestJob?.toJson(),
      'mostViewed': mostViewed?.toJson(),
      'mostApplied': mostApplied?.toJson(),
    };
  }
}

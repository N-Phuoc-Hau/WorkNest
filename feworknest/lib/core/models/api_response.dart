class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? totalItems;
  final int? totalPages;
  final int? currentPage;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.totalItems,
    this.totalPages,
    this.currentPage,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'],
      message: json['message'],
      totalItems: json['totalItems'],
      totalPages: json['totalPages'],
      currentPage: json['currentPage'],
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      if (totalItems != null) 'totalItems': totalItems,
      if (totalPages != null) 'totalPages': totalPages,
      if (currentPage != null) 'currentPage': currentPage,
      if (errors != null) 'errors': errors,
    };
  }

  // Helper methods
  bool get hasData => data != null;
  bool get isError => !success;
  String get errorMessage => message ?? 'Unknown error occurred';
}

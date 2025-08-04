import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_model.dart';
import '../services/company_service.dart';

class RecruiterCompanyState {
  final CompanyModel? company;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  final bool isUploadingImage;

  const RecruiterCompanyState({
    this.company,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
    this.isUploadingImage = false,
  });

  RecruiterCompanyState copyWith({
    CompanyModel? company,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    bool? isUploadingImage,
  }) {
    return RecruiterCompanyState(
      company: company ?? this.company,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isUpdating: isUpdating ?? this.isUpdating,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
    );
  }
}

class RecruiterCompanyNotifier extends StateNotifier<RecruiterCompanyState> {
  final CompanyService _companyService;

  RecruiterCompanyNotifier(this._companyService) : super(const RecruiterCompanyState());

  Future<void> loadMyCompany() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final company = await _companyService.getMyCompany();
      
      state = state.copyWith(
        company: company,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> updateCompany(UpdateCompanyModel updateCompany) async {
    if (state.company == null) return false;

    state = state.copyWith(isUpdating: true, error: null);

    try {
      final updatedCompany = await _companyService.updateCompany(
        state.company!.id,
        updateCompany,
      );
      
      state = state.copyWith(
        company: updatedCompany,
        isUpdating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> uploadCompanyImages(List<String> imagePaths) async {
    if (state.company == null) return false;

    state = state.copyWith(isUploadingImage: true, error: null);

    try {
      final updatedCompany = await _companyService.uploadCompanyImages(
        state.company!.id,
        imagePaths,
      );
      
      state = state.copyWith(
        company: updatedCompany,
        isUploadingImage: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploadingImage: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> getCompanyJobs({
    int page = 1,
    int pageSize = 10,
  }) async {
    if (state.company == null) return;

    try {
      final jobs = await _companyService.getCompanyJobs(
        state.company!.id,
        page: page,
        pageSize: pageSize,
      );
      
      // Update company with jobs if needed
      // This depends on your CompanyModel structure
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> getCompanyFollowers() async {
    if (state.company == null) return;

    try {
      final followers = await _companyService.getCompanyFollowers(state.company!.id);
      
      // Update company with followers if needed
      // This depends on your CompanyModel structure
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  bool get hasCompany => state.company != null;
  
  bool get isVerified => state.company?.isVerified ?? false;
  
  List<String> get companyImages => state.company?.images ?? [];
  
  String get companyName => state.company?.name ?? '';
  
  String get companyDescription => state.company?.description ?? '';
  
  String get companyLocation => state.company?.location ?? '';
}

// Providers
final recruiterCompanyServiceProvider = Provider<CompanyService>((ref) => CompanyService());

final recruiterCompanyProvider = StateNotifierProvider<RecruiterCompanyNotifier, RecruiterCompanyState>((ref) {
  return RecruiterCompanyNotifier(ref.watch(recruiterCompanyServiceProvider));
}); 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/application_model.dart';
import '../../../core/providers/cv_analysis_provider.dart';
import '../../../core/providers/recruiter_applicants_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../chat/screens/chat_detail_screen.dart';
import '../../interview/screens/schedule_interview_screen.dart';
import '../widgets/cv_analysis_bottom_sheet.dart';

class ApplicationDetailPage extends ConsumerStatefulWidget {
  final ApplicationModel application;

  const ApplicationDetailPage({
    super.key,
    required this.application,
  });

  @override
  ConsumerState<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends ConsumerState<ApplicationDetailPage> {
  @override
  void initState() {
    super.initState();
    print('DEBUG ApplicationDetailPage: Initializing with application: ${widget.application.applicantName}');
    print('DEBUG ApplicationDetailPage: Email: ${widget.application.applicantEmail}');
    print('DEBUG ApplicationDetailPage: Avatar: ${widget.application.avatarUrl}');
    // Load CV analysis when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCVAnalysis();
    });
  }

  Future<void> _loadCVAnalysis() async {
    try {
      await ref.read(cvAnalysisProvider.notifier).getCVAnalysis(widget.application.id);
      
      // If no analysis found and we have CV, trigger analysis
      final analysisState = ref.read(cvAnalysisProvider);
      if (analysisState.currentAnalysis == null && 
          !analysisState.isLoading && 
          !analysisState.isAnalyzing &&
          widget.application.cvUrl?.isNotEmpty == true) {
        
        print('DEBUG ApplicationDetailPage: No analysis found, triggering analysis');
        _showAnalysisWaitingDialog();
        await _requestCVAnalysis();
      }
    } catch (e) {
      print('DEBUG ApplicationDetailPage: Error loading CV analysis: $e');
    }
  }

  void _showAnalysisWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang phân tích CV'),
          ],
        ),
        content: const Text(
          'Hệ thống đang phân tích CV của ứng viên. Vui lòng chờ trong giây lát...'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(cvAnalysisProvider);
    
    print('DEBUG ApplicationDetailPage: Building UI with applicant: ${widget.application.applicantName}');
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chi tiết ứng viên'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // CV Analysis Quick Button
          if (analysisState.analysisResult != null)
            IconButton(
              onPressed: () => _showCVAnalysis(context),
              icon: Badge(
                label: Text('${analysisState.analysisResult!.scores.overallScore}%'),
                backgroundColor: _getScoreColor(analysisState.analysisResult!.scores.overallScore),
                child: const Icon(Icons.analytics_outlined),
              ),
              tooltip: 'Phân tích CV',
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              if (widget.application.status == ApplicationStatus.pending) ...[
                const PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Phê duyệt'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Từ chối'),
                    ],
                  ),
                ),
              ],
              const PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.chat_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Nhắn tin'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'schedule',
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Lên lịch phỏng vấn'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            _buildHeaderCard(context),
            
            const SizedBox(height: 16),
            
            // Quick Match Score (if available)
            if (analysisState.currentAnalysis != null)
              _buildQuickMatchScore(analysisState.currentAnalysis!)
            else if (analysisState.isLoading || analysisState.isAnalyzing)
              _buildLoadingMatchScore(analysisState)
            else if (widget.application.cvUrl?.isNotEmpty == true)
              _buildNoAnalysisCard()
            else
              _buildNoCVCard(),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtons(context, analysisState),
            
            const SizedBox(height: 16),
            
            // Application Info
            _buildApplicationInfo(context),
            
            const SizedBox(height: 16),
            
            // CV Analysis Summary (if available)
            if (analysisState.analysisResult != null)
              _buildAnalysisSummary(analysisState.analysisResult!),
            
            const SizedBox(height: 16),
            
            // CV Preview
            _buildCVPreview(context, analysisState),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[100],
              border: Border.all(color: Colors.blue[300]!, width: 2),
            ),
            child: widget.application.avatarUrl?.isNotEmpty == true
                ? ClipOval(
                    child: Image.network(
                      widget.application.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            widget.application.applicantName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Email
          if (widget.application.applicantEmail.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.application.applicantEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Phone
          if (widget.application.applicantPhone.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.application.applicantPhone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.application.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(widget.application.status),
              ),
            ),
            child: Text(
              _getStatusText(widget.application.status),
              style: TextStyle(
                color: _getStatusColor(widget.application.status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 40,
      color: Colors.blue[300],
    );
  }

  Widget _buildQuickMatchScore(analysisResult) {
    final matchScore = analysisResult.scores?.overallScore ?? 0;
    final matchScoreColor = _getScoreColor(matchScore);
    final matchScoreText = _getScoreText(matchScore);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            matchScoreColor.withOpacity(0.1),
            matchScoreColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: matchScoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: matchScoreColor, width: 4),
            ),
            child: Center(
              child: Text(
                '$matchScore%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: matchScoreColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Độ phù hợp',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  matchScoreText,
                  style: TextStyle(
                    color: matchScoreColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phân tích vào ${_formatDate(analysisResult.analyzedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showCVAnalysis(context),
            icon: const Icon(Icons.open_in_full),
            tooltip: 'Xem chi tiết',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, analysisState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Primary Actions
          Row(
            children: [
              // CV Analysis Button
              Expanded(
                child: analysisState.currentAnalysis != null
                    ? ElevatedButton.icon(
                        onPressed: () => _showCVAnalysis(context),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Xem phân tích'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : analysisState.isAnalyzing || analysisState.isLoading
                        ? ElevatedButton.icon(
                            onPressed: null,
                            icon: const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            label: Text(analysisState.isAnalyzing ? 'Đang phân tích...' : 'Đang tải...'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : widget.application.cvUrl?.isNotEmpty == true
                            ? ElevatedButton.icon(
                                onPressed: () => _requestCVAnalysis(),
                                icon: const Icon(Icons.analytics_outlined),
                                label: const Text('Phân tích CV'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.warning_outlined),
                                label: const Text('Không có CV'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
              ),
              
              const SizedBox(width: 12),
              
              // Contact Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _contactApplicant(context),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Nhắn tin'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Error message for CV analysis
          if (analysisState.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lỗi phân tích: ${analysisState.error}',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(cvAnalysisProvider.notifier).clearError();
                      _requestCVAnalysis();
                    },
                    child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Interview Schedule Button (only if approved or interviewing)
          if (widget.application.status == ApplicationStatus.accepted || 
              widget.application.status == ApplicationStatus.interviewing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _scheduleInterview(context),
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Lên lịch phỏng vấn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Status Actions (only if pending)
          if (widget.application.status == ApplicationStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _approveApplication(context),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    label: const Text('Phê duyệt', style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectApplication(context),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildApplicationInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin đơn ứng tuyển',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Application Date
          _buildInfoRow(
            'Ngày nộp đơn',
            _formatDate(widget.application.appliedAt),
            Icons.calendar_today_outlined,
          ),
          
          const SizedBox(height: 12),
          
          // Job Title
          _buildInfoRow(
            'Vị trí ứng tuyển',
            widget.application.jobTitle,
            Icons.work_outline,
          ),
          
          const SizedBox(height: 12),
          
          // Company (if available)
          if (widget.application.job?.recruiter.company?.name != null)
            _buildInfoRow(
              'Công ty',
              widget.application.job!.recruiter.company!.name,
              Icons.business_outlined,
            ),
          
          const SizedBox(height: 12),
          
          // Status
          _buildInfoRow(
            'Trạng thái',
            _getStatusText(widget.application.status),
            Icons.info_outline,
            statusColor: _getStatusColor(widget.application.status),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSummary(analysisResult) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Tóm tắt phân tích CV',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showCVAnalysis(context),
                child: const Text('Xem chi tiết'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Skills Preview
          if (analysisResult.extractedSkills.isNotEmpty) ...[
            Text(
              'Kỹ năng nổi bật:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: analysisResult.extractedSkills.take(5).map<Widget>((skill) => 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ).toList(),
            ),
            if (analysisResult.extractedSkills.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${analysisResult.extractedSkills.length - 5} kỹ năng khác',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
          
          const SizedBox(height: 16),
          
          // Strengths & Weaknesses Summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.thumb_up_outlined, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Điểm mạnh (${analysisResult.strengths.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    if (analysisResult.strengths.isNotEmpty)
                      Text(
                        analysisResult.strengths.first,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_outlined, size: 16, color: Colors.orange[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Cần cải thiện (${analysisResult.weaknesses.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                    if (analysisResult.weaknesses.isNotEmpty)
                      Text(
                        analysisResult.weaknesses.first,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCVPreview(BuildContext context, analysisState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'CV đính kèm',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // CV File Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red[400],
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.application.cvFileName ?? 'CV_${widget.application.applicantName}.pdf',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tải lên ${_formatDate(widget.application.appliedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                PopupMenuButton<String>(
                  onSelected: (value) => _handleCVAction(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined),
                          SizedBox(width: 8),
                          Text('Xem trước'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download_outlined),
                          SizedBox(width: 8),
                          Text('Tải xuống'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: statusColor ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _requestCVAnalysis() async {
    try {
      final success = await ref.read(cvAnalysisProvider.notifier).requestCVAnalysis(widget.application.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phân tích CV thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Close the waiting dialog if it's open
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst || !route.willHandlePopInternally);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể phân tích CV. Vui lòng thử lại sau.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi phân tích CV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCVAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CVAnalysisBottomSheet(application: widget.application),
    );
  }

  void _handleCVAction(String action) {
    switch (action) {
      case 'preview':
        _previewCV(context);
        break;
      case 'download':
        _downloadCV(context);
        break;
    }
  }

  void _downloadCV(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng tải CV đang được phát triển')),
    );
  }

  void _previewCV(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng xem trước CV đang được phát triển')),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'approve':
        _approveApplication(context);
        break;
      case 'reject':
        _rejectApplication(context);
        break;
      case 'contact':
        _contactApplicant(context);
        break;
      case 'schedule':
        _scheduleInterview(context);
        break;
    }
  }

  void _approveApplication(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phê duyệt ứng viên'),
        content: Text('Bạn có chắc chắn muốn phê duyệt ứng viên ${widget.application.applicantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Đang cập nhật...'),
                    ],
                  ),
                ),
              );
              
              try {
                final updateStatus = UpdateApplicationStatusModel(status: 'accepted');
                final success = await ref.read(recruiterApplicantsProvider.notifier)
                    .updateApplicantStatus(widget.application.id, updateStatus);
                
                Navigator.pop(context); // Close loading dialog
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã phê duyệt ứng viên'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh parent screen data
                  ref.read(recruiterApplicantsProvider.notifier).refreshApplicants();
                  
                  // Go back with result
                  Navigator.pop(context, {'statusUpdated': true, 'action': 'accepted'});
                }
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Phê duyệt'),
          ),
        ],
      ),
    );
  }

  void _rejectApplication(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối ứng viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn từ chối ứng viên ${widget.application.applicantName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Lý do từ chối (tùy chọn)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Đang cập nhật...'),
                    ],
                  ),
                ),
              );
              
              try {
                final rejectionReason = reasonController.text.trim().isEmpty 
                    ? null 
                    : reasonController.text.trim();
                
                final updateStatus = UpdateApplicationStatusModel(
                  status: 'rejected',
                  rejectionReason: rejectionReason,
                );
                
                final success = await ref.read(recruiterApplicantsProvider.notifier)
                    .updateApplicantStatus(widget.application.id, updateStatus);
                
                Navigator.pop(context); // Close loading dialog
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã từ chối ứng viên'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  
                  // Refresh parent screen data
                  ref.read(recruiterApplicantsProvider.notifier).refreshApplicants();
                  
                  // Go back with result
                  Navigator.pop(context, {'statusUpdated': true, 'action': 'rejected'});
                }
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _contactApplicant(BuildContext context) async {
    try {
      LoadingDialog.show(context, message: 'Đang tạo cuộc trò chuyện...');
      
      // Create simple room ID
      final roomId = 'recruiter_${widget.application.jobId}_${widget.application.applicantId}';
      
      // Job info for context
      final jobInfo = {
        'id': widget.application.jobId.toString(),
        'title': widget.application.jobTitle,
        'company': widget.application.job?.recruiter.company?.name ?? 'Không rõ',
      };

      LoadingDialog.hide(context);

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            roomId: roomId,
            otherUserName: widget.application.applicantName,
            otherUserAvatar: widget.application.avatarUrl ?? '',
            jobInfo: jobInfo,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bắt đầu cuộc trò chuyện với ${widget.application.applicantName}'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo cuộc trò chuyện: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scheduleInterview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleInterviewScreen(
          application: widget.application,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Interview was scheduled successfully, optionally refresh the page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lên lịch phỏng vấn thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.accepted:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.interviewing:
        return Colors.blue;
      case ApplicationStatus.hired:
        return Colors.purple;
      case ApplicationStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Đang chờ';
      case ApplicationStatus.accepted:
        return 'Đã phê duyệt';
      case ApplicationStatus.rejected:
        return 'Đã từ chối';
      case ApplicationStatus.interviewing:
        return 'Phỏng vấn';
      case ApplicationStatus.hired:
        return 'Đã tuyển';
      case ApplicationStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF4CAF50); // Green
    if (score >= 80) return const Color(0xFF8BC34A); // Light Green
    if (score >= 70) return const Color(0xFFFFC107); // Amber
    if (score >= 60) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  String _getScoreText(int score) {
    if (score >= 90) return 'Rất phù hợp';
    if (score >= 80) return 'Phù hợp';
    if (score >= 70) return 'Khá phù hợp';
    if (score >= 60) return 'Trung bình';
    return 'Ít phù hợp';
  }
}

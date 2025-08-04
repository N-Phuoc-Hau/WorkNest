import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive_utils.dart';
import '../navigation/layouts/web_layout.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WebLayout(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildStatsSection(context),
            _buildFeaturesSection(context),
            _buildHowItWorksSection(context),
            _buildTestimonialsSection(context),
            _buildCTASection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    return Container(
      height: isWeb ? 600 : 500,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: ResponsiveUtils.getContentPadding(context),
        child: isWeb ? _buildWebHero(context) : _buildMobileHero(context),
      ),
    );
  }

  Widget _buildWebHero(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tiếp lời thế,\nnối thành công',
                style: TextStyle(
                  fontSize: ResponsiveUtils.isDesktop(context) ? 48 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'WorkNest - Hệ sinh thái nhân sự tiên phong ứng dụng công nghệ tại Việt Nam. Kết nối hàng ngàn ứng viên tài năng với các cơ hội việc làm tuyệt vời.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              _buildSearchBar(context),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => context.push('/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => context.push('/login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 60),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.1),
            ),
            child: const Center(
              child: Icon(
                Icons.business_center,
                size: 200,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHero(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.business_center,
          size: 100,
          color: Colors.white.withOpacity(0.9),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tiếp lời thế,\nnối thành công',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'WorkNest - Nền tảng tìm kiếm việc làm hàng đầu Việt Nam',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        _buildSearchBar(context),
        const SizedBox(height: 24),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ResponsiveUtils.isWeb(context) 
          ? _buildWebSearchBar(context)
          : _buildMobileSearchBar(context),
    );
  }

  Widget _buildWebSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm vị trí, công ty...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Container(
          width: 1,
          height: 30,
          color: Colors.grey[300],
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Địa điểm',
              prefixIcon: Icon(Icons.location_on, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả')),
              DropdownMenuItem(value: 'hanoi', child: Text('Hà Nội')),
              DropdownMenuItem(value: 'hcm', child: Text('TP.HCM')),
              DropdownMenuItem(value: 'danang', child: Text('Đà Nẵng')),
            ],
            onChanged: (value) {},
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: ElevatedButton(
            onPressed: () => context.go('/jobs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tìm kiếm'),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSearchBar(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm vị trí, công ty...',
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        Divider(color: Colors.grey[300], height: 1),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Địa điểm',
                  prefixIcon: Icon(Icons.location_on, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'hanoi', child: Text('Hà Nội')),
                  DropdownMenuItem(value: 'hcm', child: Text('TP.HCM')),
                ],
                onChanged: (value) {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                onPressed: () => context.go('/jobs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tìm'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getContentPadding(context),
      color: Colors.grey[50],
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            'Con số ấn tượng',
            style: TextStyle(
              fontSize: ResponsiveUtils.isWeb(context) ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 40),
          ResponsiveUtils.isWeb(context)
              ? Row(
                  children: _buildStatItems(context),
                )
              : Column(
                  children: _buildStatItems(context),
                ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  List<Widget> _buildStatItems(BuildContext context) {
    final stats = [
      {'number': '50,000+', 'label': 'Việc làm'},
      {'number': '10,000+', 'label': 'Công ty'},
      {'number': '1M+', 'label': 'Ứng viên'},
      {'number': '95%', 'label': 'Tỷ lệ thành công'},
    ];

    return stats.map((stat) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              stat['number']!,
              style: TextStyle(
                fontSize: ResponsiveUtils.isWeb(context) ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stat['label']!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    )).toList();
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getContentPadding(context),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            'Tính năng nổi bật',
            style: TextStyle(
              fontSize: ResponsiveUtils.isWeb(context) ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveUtils.getCrossAxisCount(context, mobile: 1, tablet: 2, desktop: 3),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: ResponsiveUtils.isWeb(context) ? 1.2 : 1.5,
            children: [
              _buildFeatureCard(
                icon: Icons.search,
                title: 'Tìm kiếm thông minh',
                description: 'AI-powered search giúp bạn tìm được công việc phù hợp nhất',
                color: Colors.blue,
              ),
              _buildFeatureCard(
                icon: Icons.chat,
                title: 'Chat trực tiếp',
                description: 'Kết nối trực tiếp với HR, trao đổi ngay lập tức',
                color: Colors.green,
              ),
              _buildFeatureCard(
                icon: Icons.notification_important,
                title: 'Thông báo thời gian thực',
                description: 'Cập nhật tình trạng ứng tuyển, cơ hội mới ngay lập tức',
                color: Colors.orange,
              ),
              _buildFeatureCard(
                icon: Icons.analytics,
                title: 'Thống kê chi tiết',
                description: 'Theo dõi hiệu quả tuyển dụng với báo cáo chi tiết',
                color: Colors.purple,
              ),
              _buildFeatureCard(
                icon: Icons.verified,
                title: 'Xác thực công ty',
                description: 'Tất cả công ty đều được xác thực, đảm bảo uy tín',
                color: Colors.teal,
              ),
              _buildFeatureCard(
                icon: Icons.favorite,
                title: 'Lưu việc yêu thích',
                description: 'Lưu và quản lý các công việc quan tâm dễ dàng',
                color: Colors.pink,
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getContentPadding(context),
      color: Colors.grey[50],
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            'Cách thức hoạt động',
            style: TextStyle(
              fontSize: ResponsiveUtils.isWeb(context) ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 40),
          ResponsiveUtils.isWeb(context)
              ? Row(
                  children: _buildStepItems(context),
                )
              : Column(
                  children: _buildStepItems(context),
                ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  List<Widget> _buildStepItems(BuildContext context) {
    final steps = [
      {
        'number': '1',
        'title': 'Đăng ký tài khoản',
        'description': 'Tạo hồ sơ cá nhân và tải lên CV của bạn',
        'icon': Icons.person_add,
      },
      {
        'number': '2',
        'title': 'Tìm kiếm việc làm',
        'description': 'Sử dụng bộ lọc thông minh để tìm công việc phù hợp',
        'icon': Icons.search,
      },
      {
        'number': '3',
        'title': 'Ứng tuyển & Chat',
        'description': 'Nộp đơn ứng tuyển và chat trực tiếp với HR',
        'icon': Icons.chat,
      },
      {
        'number': '4',
        'title': 'Nhận việc làm',
        'description': 'Thành công trong quá trình phỏng vấn và nhận việc',
        'icon': Icons.work,
      },
    ];

    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      final isLast = index == steps.length - 1;

      return Expanded(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    step['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (step['number']! as String),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              (step['title']! as String),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              (step['description']! as String),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isLast && ResponsiveUtils.isWeb(context)) ...[
              const SizedBox(height: 40),
              Icon(
                Icons.arrow_forward,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ] else if (!ResponsiveUtils.isWeb(context)) ...[
              const SizedBox(height: 24),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTestimonialsSection(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getContentPadding(context),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            'Khách hàng nói gì về chúng tôi',
            style: TextStyle(
              fontSize: ResponsiveUtils.isWeb(context) ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveUtils.getCrossAxisCount(context, mobile: 1, tablet: 2, desktop: 3),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: ResponsiveUtils.isWeb(context) ? 1.0 : 1.2,
            children: [
              _buildTestimonialCard(
                context,
                name: 'Nguyễn Văn A',
                role: 'Frontend Developer',
                company: 'TechCorp',
                content: 'WorkNest giúp tôi tìm được công việc mơ ước chỉ trong 2 tuần. Giao diện thân thiện và hỗ trợ tuyệt vời!',
                rating: 5,
              ),
              _buildTestimonialCard(
                context,
                name: 'Trần Thị B',
                role: 'HR Manager',
                company: 'StartupXYZ',
                content: 'Chất lượng ứng viên từ WorkNest rất cao. Chúng tôi đã tuyển được nhiều nhân tài từ nền tảng này.',
                rating: 5,
              ),
              _buildTestimonialCard(
                context,
                name: 'Lê Minh C',
                role: 'Product Manager',
                company: 'InnovateInc',
                content: 'Tính năng chat trực tiếp rất tiện lợi. Tôi có thể trao đổi với HR ngay lập tức mà không cần chờ đợi.',
                rating: 5,
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(
    BuildContext context, {
    required String name,
    required String role,
    required String company,
    required String content,
    required int rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              rating,
              (index) => Icon(
                Icons.star,
                color: Colors.orange,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  name.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$role tại $company',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getContentPadding(context),
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            'Sẵn sàng bắt đầu hành trình mới?',
            style: TextStyle(
              fontSize: ResponsiveUtils.isWeb(context) ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tham gia WorkNest ngay hôm nay và khám phá hàng ngàn cơ hội việc làm tuyệt vời!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ResponsiveUtils.isWeb(context)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/jobs'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Xem việc làm', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go('/jobs'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Xem việc làm', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getContentPadding(context),
      color: Colors.grey[900],
      child: Column(
        children: [
          const SizedBox(height: 40),
          ResponsiveUtils.isWeb(context)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildFooterBrand(),
                    ),
                    Expanded(child: _buildFooterLinks('Dành cho ứng viên', [
                      'Tìm việc làm',
                      'Công ty hàng đầu',
                      'Cẩm nang nghề nghiệp',
                      'Tạo CV',
                    ])),
                    Expanded(child: _buildFooterLinks('Dành cho nhà tuyển dụng', [
                      'Đăng tin tuyển dụng',
                      'Tìm hồ sơ',
                      'Dịch vụ tuyển dụng',
                      'Báo cáo thị trường',
                    ])),
                    Expanded(child: _buildFooterLinks('Về WorkNest', [
                      'Giới thiệu',
                      'Liên hệ',
                      'Điều khoản',
                      'Chính sách bảo mật',
                    ])),
                  ],
                )
              : Column(
                  children: [
                    _buildFooterBrand(),
                    const SizedBox(height: 32),
                    _buildFooterLinks('Dành cho ứng viên', [
                      'Tìm việc làm',
                      'Công ty hàng đầu',
                      'Cẩm nang nghề nghiệp',
                      'Tạo CV',
                    ]),
                    const SizedBox(height: 24),
                    _buildFooterLinks('Dành cho nhà tuyển dụng', [
                      'Đăng tin tuyển dụng',
                      'Tìm hồ sơ',
                      'Dịch vụ tuyển dụng',
                      'Báo cáo thị trường',
                    ]),
                    const SizedBox(height: 24),
                    _buildFooterLinks('Về WorkNest', [
                      'Giới thiệu',
                      'Liên hệ',
                      'Điều khoản',
                      'Chính sách bảo mật',
                    ]),
                  ],
                ),
          const SizedBox(height: 32),
          Divider(color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            '© 2025 WorkNest. All rights reserved.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.work,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              'WorkNest',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Nền tảng tìm kiếm việc làm hàng đầu Việt Nam, kết nối hàng ngàn ứng viên với các cơ hội việc làm tuyệt vời.',
          style: TextStyle(
            color: Colors.grey[400],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.facebook, color: Colors.grey[400]),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.link, color: Colors.grey[400]),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.email, color: Colors.grey[400]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLinks(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {},
            child: Text(
              link,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }
}

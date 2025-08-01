import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/onboarding_storage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      image: 'assets/images/onboarding1.png', // You need to add these images
      title: 'Tìm kiếm việc làm dễ dàng',
      description: 'Khám phá hàng ngàn cơ hội việc làm phù hợp với bạn',
    ),
    OnboardingItem(
      image: 'assets/images/onboarding2.png',
      title: 'Kết nối với nhà tuyển dụng',
      description: 'Giao tiếp trực tiếp với các công ty hàng đầu',
    ),
    OnboardingItem(
      image: 'assets/images/onboarding3.png',
      title: 'Phát triển sự nghiệp',
      description: 'Xây dựng hồ sơ chuyên nghiệp và phát triển kỹ năng',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () async {
                  await OnboardingStorage.setOnboardingSeen();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Bỏ qua'),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Placeholder for image
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.work_outline,
                            size: 100,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          item.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _items.asMap().entries.map((entry) {
                return Container(
                  width: _currentPage == entry.key ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == entry.key
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  // Primary action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentPage < _items.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          await OnboardingStorage.setOnboardingSeen();
                          if (context.mounted) context.go('/login');
                        }
                      },
                      child: Text(
                        _currentPage < _items.length - 1 ? 'Tiếp theo' : 'Đăng nhập',
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Browse jobs without login button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await OnboardingStorage.setOnboardingSeen();
                        if (context.mounted) context.go('/guest-dashboard');
                      },
                      child: const Text('Xem việc làm không cần đăng nhập'),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Navigation row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Quay lại'),
                        )
                      else
                        const SizedBox(),
                      
                      TextButton(
                        onPressed: () async {
                          await OnboardingStorage.setOnboardingSeen();
                          if (context.mounted) context.go('/register');
                        },
                        child: const Text('Đăng ký'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;

  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}

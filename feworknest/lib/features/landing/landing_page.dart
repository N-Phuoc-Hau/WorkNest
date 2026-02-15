import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/language_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/language_toggle_widget.dart';
import '../../shared/widgets/worknest_logo.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, ref),
            _buildHeroSection(context, ref),
            _buildStatsSection(context, ref),
            _buildCategoriesSection(context, ref),
            _buildFeaturedJobsSection(context, ref),
            _buildHowItWorksSection(context, ref),
            _buildTestimonialsSection(context, ref),
            _buildCTASection(context, ref),
            _buildFooter(context, ref),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.spacing48 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          const WorkNestLogo(size: 40, showName: false),
          SizedBox(width: AppSpacing.spacing12),
          Text(
            l10n.appName,
            style: AppTypography.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Navigation (for wide screens)
          if (isWide) ...[
            TextButton(
              onPressed: () => context.go('/jobs'),
              child: Text(l10n.jobs),
            ),
            SizedBox(width: AppSpacing.spacing8),
            TextButton(
              onPressed: () => context.go('/companies'),
              child: Text(l10n.companies),
            ),
            SizedBox(width: AppSpacing.spacing8),
            TextButton(
              onPressed: () {},
              child: Text(l10n.aboutUs),
            ),
            SizedBox(width: AppSpacing.spacing24),
          ],

          // Theme toggle
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: AppColors.neutral700,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),

          // Language toggle
          const LanguageToggleButton(),

          SizedBox(width: AppSpacing.spacing16),

          // Login button
          OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing20,
                vertical: AppSpacing.spacing12,
              ),
            ),
            child: Text(l10n.login),
          ),

          SizedBox(width: AppSpacing.spacing12),

          // Sign up button
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing20,
                vertical: AppSpacing.spacing12,
              ),
            ),
            child: Text(l10n.signUp),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HERO SECTION
  // ============================================================================
  Widget _buildHeroSection(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.spacing48 : AppSpacing.spacing24,
        vertical: isWide ? AppSpacing.spacing64 : AppSpacing.spacing48,
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildHeroContent(context, ref),
                ),
                SizedBox(width: AppSpacing.spacing64),
                Expanded(
                  flex: 1,
                  child: _buildHeroImage(context),
                ),
              ],
            )
          : Column(
              children: [
                _buildHeroContent(context, ref),
                SizedBox(height: AppSpacing.spacing32),
                _buildHeroImage(context),
              ],
            ),
    );
  }

  Widget _buildHeroContent(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.heroTitle,
          style: AppTypography.h1.copyWith(
            fontSize: 48,
            height: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacing16),
        Text(
          l10n.heroSubtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.neutral600,
            height: 1.6,
          ),
        ),
        SizedBox(height: AppSpacing.spacing32),
        _buildSearchBar(context, ref),
        SizedBox(height: AppSpacing.spacing16),
        Text(
          'Popular: ${l10n.design}, ${l10n.sales}, ${l10n.marketing}, ${l10n.business}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Icon(Icons.search, color: AppColors.neutral600),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchPlaceholder,
                      border: InputBorder.none,
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.neutral200,
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacing12),
                ),
                Icon(Icons.location_on, color: AppColors.neutral600),
                SizedBox(width: AppSpacing.spacing8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: l10n.location,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(l10n.allLocations, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'hanoi', child: Text('Hà Nội', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'hcm', child: Text('TP.HCM', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'danang', child: Text('Đà Nẵng', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (value) {},
                  ),
                ),
                SizedBox(width: AppSpacing.spacing12),
                ElevatedButton(
                  onPressed: () => context.go('/jobs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing32,
                      vertical: AppSpacing.spacing16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                  ),
                  child: Text(l10n.search),
                ),
              ],
            )
          : Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchPlaceholder,
                    prefixIcon: Icon(Icons.search, color: AppColors.neutral600),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: l10n.location,
                          prefixIcon: Icon(Icons.location_on, color: AppColors.neutral600),
                          border: OutlineInputBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                            borderSide: BorderSide(color: AppColors.neutral200),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(l10n.allLocations)),
                          DropdownMenuItem(value: 'hanoi', child: Text('Hà Nội')),
                          DropdownMenuItem(value: 'hcm', child: Text('TP.HCM')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacing12),
                    ElevatedButton(
                      onPressed: () => context.go('/jobs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.all(AppSpacing.spacing16),
                      ),
                      child: Icon(Icons.search, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusLg,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.work_outline,
          size: 120,
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
    );
  }

  // ============================================================================
  // STATS SECTION
  // ============================================================================
  Widget _buildStatsSection(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.spacing48 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing48,
      ),
      color: AppColors.neutral50,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: AppSpacing.spacing24,
        mainAxisSpacing: AppSpacing.spacing24,
        childAspectRatio: isWide ? 1.5 : 1.2,
        children: [
          _buildStatCard('1.7M+', l10n.peopleGotHired, context),
          _buildStatCard('50,000+', l10n.liveJobs, context),
          _buildStatCard('10,000+', l10n.totalCompanies, context),
          _buildStatCard('2.5M+', l10n.newJobsToday, context),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: AppTypography.h2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing8),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CATEGORIES SECTION
  // ============================================================================
  Widget _buildCategoriesSection(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    final categories = [
      {'icon': Icons.palette, 'name': l10n.design, 'jobs': '235', 'color': Colors.blue},
      {'icon': Icons.sell, 'name': l10n.sales, 'jobs': '756', 'color': Colors.orange},
      {'icon': Icons.campaign, 'name': l10n.marketing, 'jobs': '140', 'color': AppColors.primary},
      {'icon': Icons.monetization_on, 'name': l10n.finance, 'jobs': '325', 'color': Colors.green},
      {'icon': Icons.computer, 'name': l10n.technology, 'jobs': '436', 'color': Colors.purple},
      {'icon': Icons.construction, 'name': l10n.engineering, 'jobs': '542', 'color': Colors.teal},
      {'icon': Icons.business, 'name': l10n.business, 'jobs': '211', 'color': Colors.brown},
      {'icon': Icons.people, 'name': l10n.humanResource, 'jobs': '346', 'color': Colors.pink},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.spacing48 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing64,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.exploreByCategory,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/jobs'),
                child: Row(
                  children: [
                    Text(l10n.showAll),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: AppSpacing.spacing24,
              mainAxisSpacing: AppSpacing.spacing24,
              childAspectRatio: 1.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(
                icon: category['icon'] as IconData,
                name: category['name'] as String,
                jobs: category['jobs'] as String,
                color: category['color'] as Color,
                context: context,
                ref: ref,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String name,
    required String jobs,
    required Color color,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final l10n = ref.watch(localizationsProvider);

    return InkWell(
      onTap: () => context.go('/jobs'),
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacing20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacing4),
                  Text(
                    '$jobs ${l10n.jobsAvailable}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FEATURED JOBS (Placeholder)
  // ============================================================================
  Widget _buildFeaturedJobsSection(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.spacing48 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing64,
      ),
      color: AppColors.neutral50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.featuredJobs,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/jobs'),
                child: Row(
                  children: [
                    Text(l10n.showAll),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacing32),
          Text(
            '${l10n.exploreByCategory} - ${l10n.jobs}',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          SizedBox(height: AppSpacing.spacing24),
          ElevatedButton(
            onPressed: () => context.go('/jobs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing32,
                vertical: AppSpacing.spacing16,
              ),
            ),
            child: Text('${l10n.viewAll} ${l10n.jobs}'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HOW IT WORKS
  // ============================================================================
  Widget _buildHowItWorksSection(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    final steps = [
      {'icon': Icons.person_add, 'title': l10n.step1Title, 'desc': l10n.step1Desc},
      {'icon': Icons.upload_file, 'title': l10n.step2Title, 'desc': l10n.step2Desc},
      {'icon': Icons.search, 'title': l10n.step3Title, 'desc': l10n.step3Desc},
      {'icon': Icons.work, 'title': l10n.step4Title, 'desc': l10n.step4Desc},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.spacing48 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing64,
      ),
      child: Column(
        children: [
          Text(
            l10n.howItWorks,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing48),
          isWide
              ? Row(
                  children: steps.asMap().entries.map((entry) {
                    final isLast = entry.key == steps.length - 1;
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildStepCard(entry.value, entry.key + 1, context)),
                          if (!isLast)
                            Icon(Icons.arrow_forward, color: AppColors.primary, size: 32),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Column(
                  children: steps.asMap().entries.map((entry) {
                    return Column(
                      children: [
                        _buildStepCard(entry.value, entry.key + 1, context),
                        if (entry.key < steps.length - 1)
                          SizedBox(height: AppSpacing.spacing24),
                      ],
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStepCard(Map<String, dynamic> step, int number, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          Text(
            step['title'],
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacing8),
          Text(
            step['desc'],
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TESTIMONIALS (Placeholder)
  // ============================================================================
  Widget _buildTestimonialsSection(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing48,
        vertical: AppSpacing.spacing64,
      ),
      color: AppColors.neutral50,
      child: Column(
        children: [
          Text(
            l10n.whatPeopleSay,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacing16),
          Text(
            l10n.testimonials,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CTA SECTION
  // ============================================================================
  Widget _buildCTASection(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.spacing48 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing64,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.readyToStart,
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacing16),
          Text(
            l10n.ctaDescription,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacing32),
          isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing32,
                          vertical: AppSpacing.spacing16,
                        ),
                      ),
                      child: Text(l10n.signUpNow),
                    ),
                    SizedBox(width: AppSpacing.spacing16),
                    OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing32,
                          vertical: AppSpacing.spacing16,
                        ),
                      ),
                      child: Text(l10n.postJob),
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
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.all(AppSpacing.spacing16),
                        ),
                        child: Text(l10n.signUpNow),
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacing12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push('/register'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.all(AppSpacing.spacing16),
                        ),
                        child: Text(l10n.postJob),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ============================================================================
  // FOOTER
  // ============================================================================
  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.spacing48 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing48,
      ),
      color: AppColors.neutral900,
      child: Column(
        children: [
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFooterBrand(context, ref)),
                    SizedBox(width: AppSpacing.spacing64),
                    Expanded(
                      child: _buildFooterLinks(
                        l10n.about,
                        [l10n.aboutUs, l10n.careers, l10n.companies],
                        context,
                      ),
                    ),
                    Expanded(
                      child: _buildFooterLinks(
                        l10n.resources,
                        [l10n.helpCenter, l10n.blog, l10n.support],
                        context,
                      ),
                    ),
                    Expanded(
                      child: _buildFooterLinks(
                        l10n.getInTouch,
                        [l10n.contact, l10n.support],
                        context,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFooterBrand(context, ref),
                    SizedBox(height: AppSpacing.spacing32),
                    _buildFooterLinks(
                      l10n.about,
                      [l10n.aboutUs, l10n.careers, l10n.companies],
                      context,
                    ),
                    SizedBox(height: AppSpacing.spacing24),
                    _buildFooterLinks(
                      l10n.resources,
                      [l10n.helpCenter, l10n.blog, l10n.support],
                      context,
                    ),
                  ],
                ),
          SizedBox(height: AppSpacing.spacing32),
          Divider(color: AppColors.neutral700),
          SizedBox(height: AppSpacing.spacing16),
          Text(
            '© 2026 WorkNest. ${l10n.allRightsReserved}.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBrand(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const WorkNestLogo(size: 32, showName: false),
            SizedBox(width: AppSpacing.spacing8),
            Text(
              l10n.appName,
              style: AppTypography.h5.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.spacing16),
        Text(
          l10n.heroSubtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks(String title, List<String> links, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacing16),
        ...links.map((link) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: InkWell(
                onTap: () {},
                child: Text(
                  link,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral400,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

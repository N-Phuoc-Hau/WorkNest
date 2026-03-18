import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/subscription_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/unified_notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/subscription/widgets/premium_modal.dart';
import '../../../shared/widgets/worknest_logo.dart';

class WebSidebar extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const WebSidebar({
    super.key,
    this.isCollapsed = false,
    required this.onToggle,
  });

  @override
  ConsumerState<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends ConsumerState<WebSidebar> {
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _selectedRoute =
        GoRouter.of(context).routeInformationProvider.value.uri.path;

    // Load unread counts khi khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        // Load chat data để có unread count
        ref.read(chatProvider.notifier).loadChatRooms();

        // Load notification unread count nếu có userId
        if (authState.user?.id != null) {
          try {
            ref
                .read(unifiedNotificationProvider.notifier)
                .refreshUnreadCount();
          } catch (e) {
            print('Error loading notification count in sidebar: $e');
          }
        }
        // Subscription được load bởi ref.listen trong build() — không cần ở đây
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load subscription ngay khi auth resolve — không chờ widget khác khởi tạo
    ref.listen(authProvider, (prev, next) {
      if (next.isLoading) return; // chờ auth xong
      final isCandidate = next.user != null &&
          next.user!.isRecruiter != true &&
          next.user!.role != 'admin';
      if (!isCandidate) return;
      final subState = ref.read(subscriptionProvider);
      // Chỉ load nếu chưa có data và không đang load (tránh duplicate call)
      if (subState.mySub == null && !subState.isLoadingSub) {
        ref.read(subscriptionProvider.notifier).loadMySubscription();
      }
    });

    // Xử lý trường hợp auth đã resolve từ frame đầu tiên (ref.listen bỏ qua initial state)
    if (!authState.isLoading && isAuthenticated && user != null &&
        user.isRecruiter != true && user.role != 'admin') {
      final subState = ref.read(subscriptionProvider);
      if (subState.mySub == null && !subState.isLoadingSub) {
        Future.microtask(
            () => ref.read(subscriptionProvider.notifier).loadMySubscription());
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral900 : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildSidebarHeader(isDark),

          // Navigation Menu
          Expanded(
            child: _buildNavigationMenu(isAuthenticated, user, isDark),
          ),

          // Footer
          _buildSidebarFooter(isAuthenticated, user, isDark),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: widget.isCollapsed
          ? Center(
              child: Container(
                padding: EdgeInsets.all(AppSpacing.spacing8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const WorkNestLogo(
                  size: 28,
                  showName: false,

                ),
              ),
            )
          : Row(
               children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacing8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const WorkNestLogo(
                    size: 28,
                    showName: false,
                  ),
                ),
                SizedBox(width: AppSpacing.spacing12),
                const Flexible(
                  child: Text(
                    'WorkNest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavigationMenu(bool isAuthenticated, dynamic user, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);
        int notificationUnreadCount = 0;

        // Chỉ load notification count nếu user đã đăng nhập và có userId
        if (isAuthenticated && user?.id != null) {
          try {
            notificationUnreadCount = ref.watch(unreadCountProvider);
          } catch (e) {
            print('Error loading notification count: $e');
          }
        }

        // Đọc subscription cho candidate
        UserSubscription? mySub;
        final isCandidate =
            isAuthenticated && user?.isRecruiter != true && user?.role != 'admin';
        if (isCandidate) {
          mySub = ref.watch(mySubscriptionProvider);
        }

        final menuItems = _getMenuItems(
          isAuthenticated,
          user,
          chatState.unreadCount,
          notificationUnreadCount,
        );

        return ListView(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
          children: [
            // Banner hội viên (chỉ hiện cho candidate, chỉ khi sidebar mở)
            if (isCandidate && !widget.isCollapsed)
              _buildSubscriptionBanner(mySub, isDark),

            // Tab Premium nổi bật
            if (isCandidate)
              _buildPremiumTab(mySub, isDark),

            // Settings section header (only in expanded mode)
            if (!widget.isCollapsed && menuItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                  vertical: AppSpacing.spacing8,
                ),
                child: Text(
                  'MENU',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.neutral500 : AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ...menuItems
                .map((item) => _buildMenuItem(item, isDark, mySub))
                .toList(),
          ],
        );
      },
    );
  }

  /// Banner hiển thị cấp độ hội viên hiện tại của candidate
  Widget _buildSubscriptionBanner(UserSubscription? sub, bool isDark) {
    final planName = sub?.planName ?? 'Free';
    final isFree = sub == null || sub.isFree;
    final planColor = _planColor(planName);

    return GestureDetector(
      onTap: () => context.go('/subscription/pricing'),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          AppSpacing.spacing12,
          AppSpacing.spacing4,
          AppSpacing.spacing12,
          AppSpacing.spacing8,
        ),
        padding: EdgeInsets.all(AppSpacing.spacing12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              planColor.withOpacity(0.15),
              planColor.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: planColor.withOpacity(0.35), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isFree ? Icons.card_giftcard : Icons.workspace_premium,
              color: planColor,
              size: 20,
            ),
            SizedBox(width: AppSpacing.spacing8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: planColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        planName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ]),
                  SizedBox(height: AppSpacing.spacing4),
                  Text(
                    isFree
                        ? 'Nâng cấp để mở khoá tính năng'
                        : 'Còn ${sub.daysRemaining} ngày sử dụng',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: planColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Color _planColor(String planName) {
    switch (planName.toLowerCase()) {
      case 'basic':
        return AppColors.info;
      case 'pro':
        return AppColors.primary;
      case 'enterprise':
        return const Color(0xFFF59E0B); // amber
      default:
        return AppColors.neutral500; // free
    }
  }

  /// Tab Premium nổi bật — luôn hiển thị với candidate
  Widget _buildPremiumTab(UserSubscription? sub, bool isDark) {
    final isFree = sub == null || sub.isFree;
    final isPro = sub != null &&
        ['pro', 'enterprise'].contains(sub.planName.toLowerCase());
    final isEnterprise =
        sub != null && sub.planName.toLowerCase() == 'enterprise';

    // Không hiện nút nâng cấp nếu đã Enterprise
    if (isEnterprise) return const SizedBox.shrink();

    if (widget.isCollapsed) {
      return _buildPremiumCollapsed(isFree, isDark);
    }
    return _buildPremiumExpanded(isFree, isPro, sub, isDark);
  }

  Widget _buildPremiumCollapsed(bool isFree, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing8, vertical: AppSpacing.spacing4),
      child: Tooltip(
        message: 'Nâng cấp Premium',
        child: GestureDetector(
          onTap: () => showPremiumModal(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 20),
              ),
              // Pulse dot
              Positioned(
                top: -3,
                right: -3,
                child: _PulseDot(color: isFree ? Colors.red : AppColors.success),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumExpanded(
      bool isFree, bool isPro, UserSubscription? sub, bool isDark) {
    return GestureDetector(
      onTap: () => showPremiumModal(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing12,
          vertical: AppSpacing.spacing4,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF6B00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isFree
                    ? Icons.bolt_rounded
                    : (isPro
                        ? Icons.workspace_premium_rounded
                        : Icons.stars_rounded),
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚡ PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    isFree
                        ? 'Nâng cấp ngay từ 99K'
                        : (isPro
                            ? 'Xem gói Enterprise'
                            : 'Xem gói Pro · 199K'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'MỞ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SidebarMenuItem> _getMenuItems(bool isAuthenticated, dynamic user,
      int chatUnreadCount, int notificationUnreadCount) {
    final List<SidebarMenuItem> items = [
      SidebarMenuItem(
        icon: Icons.home_rounded,
        title: 'Trang chủ',
        route: isAuthenticated
            ? (user?.isRecruiter == true ? '/recruiter/home' : '/home')
            : '/',
      ),
      SidebarMenuItem(
        icon: Icons.work_rounded,
        title: 'Việc làm',
        route: isAuthenticated
            ? (user?.isRecruiter == true ? '/jobs' : '/jobs')
            : '/jobs',
      ),
    ];

    if (isAuthenticated) {
      if (user?.role == 'admin') {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.people_rounded,
            title: 'Quản lý người dùng',
            route: '/admin/users',
          ),
          SidebarMenuItem(
            icon: Icons.work_history_rounded,
            title: 'Quản lý tin tuyển dụng',
            route: '/admin/jobs',
          ),
          SidebarMenuItem(
            icon: Icons.business_rounded,
            title: 'Duyệt công ty',
            route: '/admin/companies',
          ),
        ]);
      } else if (user?.isRecruiter == true) {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.add_business_rounded,
            title: 'Đăng tin tuyển dụng',
            route: '/recruiter/post-job',
          ),
          SidebarMenuItem(
            icon: Icons.manage_accounts_rounded,
            title: 'Quản lý tin đăng',
            route: '/recruiter/jobs',
          ),
          SidebarMenuItem(
            icon: Icons.people_alt_rounded,
            title: 'Ứng viên',
            route: '/recruiter/applicants',
          ),
          SidebarMenuItem(
            icon: Icons.apartment_rounded,
            title: 'Công ty',
            route: '/recruiter/company',
          ),
        ]);
      } else {
        items.addAll([
          SidebarMenuItem(
            icon: Icons.description_rounded,
            title: 'Đơn ứng tuyển',
            route: '/applications',
          ),
          SidebarMenuItem(
            icon: Icons.analytics_rounded,
            title: 'Phân tích CV',
            route: '/cv-analysis',
            requiredFeature: 'cv_builder',
            planRequired: 'Basic',
          ),
          SidebarMenuItem(
            icon: Icons.article_rounded,
            title: 'CV Online',
            route: '/cv-online',
            requiredFeature: 'cv_builder',
            planRequired: 'Basic',
          ),
          SidebarMenuItem(
            icon: Icons.favorite_rounded,
            title: 'Việc làm đã lưu',
            route: '/favorites',
          ),
          SidebarMenuItem(
            icon: Icons.business_center_rounded,
            title: 'Công ty theo dõi',
            route: '/following-companies',
          ),
        ]);
      }

      // Chỉ hiển thị tin nhắn và thông báo với số lượng thật, bỏ search
      items.addAll([
        SidebarMenuItem(
          icon: Icons.chat_bubble_rounded,
          title: 'Tin nhắn',
          route: isAuthenticated
              ? (user?.isRecruiter == true ? '/recruiter/chat' : '/chat')
              : '/chat',
          badge: chatUnreadCount > 0 ? chatUnreadCount.toString() : null,
        ),
        SidebarMenuItem(
          icon: Icons.notifications_rounded,
          title: 'Thông báo',
          route: '/notifications',
          badge: notificationUnreadCount > 0
              ? notificationUnreadCount.toString()
              : null,
        ),
      ]);
    }

    return items;
  }

  Widget _buildMenuItem(
      SidebarMenuItem item, bool isDark, UserSubscription? mySub) {
    final isSelected = _selectedRoute == item.route;

    // Kiểm tra quyền truy cập dựa theo subscription
    final bool isLocked = item.requiredFeature != null &&
        (mySub == null || !mySub.canUse(item.requiredFeature!));

    void handleTap() {
      if (isLocked) {
        _showUpgradeDialog(item);
        return;
      }
      setState(() {
        _selectedRoute = item.route;
      });
      context.go(item.route);
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? AppSpacing.spacing8 : AppSpacing.spacing12,
        vertical: AppSpacing.spacing2,
      ),
      child: Tooltip(
        message: isLocked
            ? 'Yêu cầu gói ${item.planRequired ?? "cao hơn"}'
            : '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: handleTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed
                    ? AppSpacing.spacing8
                    : AppSpacing.spacing16,
                vertical: AppSpacing.spacing12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.1))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: widget.isCollapsed
                  ? Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item.icon,
                            color: isLocked
                                ? AppColors.neutral400
                                : (isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.neutral400
                                        : AppColors.neutral600)),
                            size: 22,
                          ),
                          if (isLocked)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock,
                                    size: 9, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          item.icon,
                          color: isLocked
                              ? AppColors.neutral400
                              : (isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.neutral400
                                      : AppColors.neutral600)),
                          size: 22,
                        ),
                        SizedBox(width: AppSpacing.spacing12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isLocked
                                  ? AppColors.neutral400
                                  : (isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.neutral300
                                          : AppColors.neutral700)),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isLocked) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.warning.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock,
                                    size: 10, color: AppColors.warning),
                                const SizedBox(width: 3),
                                Text(
                                  item.planRequired ?? 'Trả phí',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (item.badge != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacing8,
                              vertical: AppSpacing.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.badge!,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUpgradeDialog(SidebarMenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium,
                color: AppColors.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              'Yêu cầu gói ${item.planRequired ?? "cao hơn"}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '"${item.title}" chỉ có trong gói ${item.planRequired ?? "trả phí"} trở lên.',
              style: const TextStyle(color: AppColors.neutral600, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Để sau')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/subscription/pricing');
            },
            child: const Text('Xem gói ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter(bool isAuthenticated, dynamic user, bool isDark) {
    if (!isAuthenticated) {
      if (widget.isCollapsed) {
        return Padding(
          padding: EdgeInsets.all(AppSpacing.spacing8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => context.go('/login'),
                icon: Icon(
                  Icons.login_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                tooltip: 'Đăng nhập',
              ),
              SizedBox(height: AppSpacing.spacing4),
              IconButton(
                onPressed: () => context.go('/register'),
                icon: Icon(
                  Icons.person_add_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
                tooltip: 'Đăng ký',
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.05),
              Colors.transparent,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(
                'Đăng nhập',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.spacing12),
            OutlinedButton.icon(
              onPressed: () => context.go('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: Text(
                'Đăng ký',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Authenticated user footer
    return Container(
      padding: EdgeInsets.all(widget.isCollapsed ? AppSpacing.spacing8 : AppSpacing.spacing16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          ),
        ),
      ),
      child: widget.isCollapsed
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: user?.avatar == null
                      ? AppColors.primary
                      : null,
                  backgroundImage:
                      user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                  child: user?.avatar == null
                      ? Text(
                          (user?.firstName?.isNotEmpty == true)
                              ? user!.firstName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(height: AppSpacing.spacing8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                  ),
                  tooltip: 'Menu',
                  onSelected: (value) {
                    if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'settings') {
                      final currentUser = ref.read(authProvider).user;
                      if (currentUser?.isRecruiter == true) {
                        context.go('/recruiter/settings');
                      } else {
                        context.go('/settings');
                      }
                    } else if (value == 'subscription') {
                      context.go('/subscription/my');
                    } else if (value == 'logout') {
                      ref.read(authProvider.notifier).logout();
                      context.go('/');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, size: 20, color: AppColors.neutral600),
                          SizedBox(width: AppSpacing.spacing12),
                          const Text('Hồ sơ'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_rounded, size: 20, color: AppColors.neutral600),
                          SizedBox(width: AppSpacing.spacing12),
                          const Text('Cài đặt'),
                        ],
                      ),
                    ),
                    if (user?.isRecruiter != true && user?.role != 'admin')
                      PopupMenuItem(
                        value: 'subscription',
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.spacing12),
                            const Text('Gói hội viên',
                                style: TextStyle(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                          SizedBox(width: AppSpacing.spacing12),
                          Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: user?.avatar == null
                      ? AppColors.primary
                      : null,
                  backgroundImage:
                      user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                  child: user?.avatar == null
                      ? Text(
                          (user?.firstName?.isNotEmpty == true)
                              ? user!.firstName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.neutral200 : AppColors.neutral900,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: AppSpacing.spacing4),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.neutral500 : AppColors.neutral600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.spacing8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'settings') {
                      final currentUser = ref.read(authProvider).user;
                      if (currentUser?.isRecruiter == true) {
                        context.go('/recruiter/settings');
                      } else {
                        context.go('/settings');
                      }
                    } else if (value == 'subscription') {
                      context.go('/subscription/my');
                    } else if (value == 'logout') {
                      ref.read(authProvider.notifier).logout();
                      context.go('/');
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, size: 20, color: AppColors.neutral600),
                          SizedBox(width: AppSpacing.spacing12),
                          const Text('Hồ sơ'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_rounded, size: 20, color: AppColors.neutral600),
                          SizedBox(width: AppSpacing.spacing12),
                          const Text('Cài đặt'),
                        ],
                      ),
                    ),
                    if (user?.isRecruiter != true && user?.role != 'admin')
                      PopupMenuItem(
                        value: 'subscription',
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium,
                                size: 20, color: AppColors.primary),
                            SizedBox(width: AppSpacing.spacing12),
                            const Text('Gói hội viên',
                                style: TextStyle(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                          SizedBox(width: AppSpacing.spacing12),
                          Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class SidebarMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final String? badge;

  /// Tên feature trong subscription cần có để dùng menu item này
  final String? requiredFeature;

  /// Tên gói hiển thị cho user (ví dụ: 'Basic', 'Pro')
  final String? planRequired;

  SidebarMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.badge,
    this.requiredFeature,
    this.planRequired,
  });
}

/// Chấm nhấp nháy (pulsing dot) dùng trong tab premium collapsed mode
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

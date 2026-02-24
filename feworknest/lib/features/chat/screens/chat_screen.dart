import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/chat_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/chat_detail_panel.dart';
import '../widgets/chat_list_panel.dart';

/// Responsive chat screen with master-detail layout
/// - Web/Tablet: Shows chat list and detail side by side
/// - Mobile: Shows only chat list (detail opens in new screen)
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _selectedRoomId;
  Map<String, dynamic>? _selectedChatRoom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatNotifier = ref.read(chatProvider.notifier);
      chatNotifier.loadChatRooms();
      _startPeriodicUnreadCountUpdate();
    });
  }

  void _startPeriodicUnreadCountUpdate() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        ref.read(chatProvider.notifier).updateUnreadCount();
        _startPeriodicUnreadCountUpdate();
      }
    });
  }

  void _onChatRoomSelected(Map<String, dynamic> chatRoom) {
    setState(() {
      _selectedRoomId = chatRoom['id']?.toString();
      _selectedChatRoom = chatRoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint for master-detail layout
        final bool isWideScreen = constraints.maxWidth >= 768;

        if (isWideScreen) {
          // Web/Tablet layout: Master-detail side by side
          return Scaffold(
            backgroundColor: AppColors.white,
            body: Row(
              children: [
                // Left panel: Chat list
                SizedBox(
                  width: 360,
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),
                      
                      // Divider
                      Container(
                        height: 1,
                        color: AppColors.neutral200,
                      ),
                      
                      // Chat list
                      Expanded(
                        child: ChatListPanel(
                          onChatRoomSelected: _onChatRoomSelected,
                          selectedRoomId: _selectedRoomId,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vertical divider
                Container(
                  width: 1,
                  color: AppColors.neutral200,
                ),
                
                // Right panel: Chat detail
                Expanded(
                  child: _selectedChatRoom != null
                      ? ChatDetailPanel(
                          chatRoom: _selectedChatRoom!,
                        )
                      : _buildEmptyDetailPanel(),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout: Only show chat list
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Messages',
                style: AppTypography.h4.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.neutral900,
              elevation: 0,
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppColors.neutral200,
                ),
              ),
            ),
            backgroundColor: AppColors.white,
            body: ChatListPanel(
              onChatRoomSelected: (chatRoom) {
                // On mobile, navigate to detail screen
                Navigator.pushNamed(
                  context,
                  '/chat-detail',
                  arguments: chatRoom,
                );
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Messages',
            style: AppTypography.h4.copyWith(
              color: AppColors.neutral900,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.neutral600,
            ),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetailPanel() {
    return Container(
      color: AppColors.neutral50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppSpacing.spacing24),
            Text(
              'Select a message',
              style: AppTypography.h5.copyWith(
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: AppSpacing.spacing8),
            Text(
              'Choose from your existing conversations or start a new one',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

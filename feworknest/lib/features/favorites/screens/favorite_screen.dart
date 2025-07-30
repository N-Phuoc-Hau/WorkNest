import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/favorite_provider.dart';

class FavoriteScreen extends ConsumerStatefulWidget {
  const FavoriteScreen({super.key});

  @override
  ConsumerState<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends ConsumerState<FavoriteScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoriteProvider.notifier).getMyFavorites();
      ref.read(favoriteProvider.notifier).getFavoriteStats();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteState = ref.watch(favoriteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc yêu thích'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(favoriteProvider.notifier).getMyFavorites();
          ref.read(favoriteProvider.notifier).getFavoriteStats();
        },
        child: favoriteState.isLoading && favoriteState.favoriteJobs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : favoriteState.error != null && favoriteState.favoriteJobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          favoriteState.error!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(favoriteProvider.notifier).getMyFavorites();
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : favoriteState.favoriteJobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có công việc yêu thích nào',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy thêm các công việc bạn quan tâm vào danh sách yêu thích',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.go('/candidate/jobs'),
                              child: const Text('Tìm kiếm công việc'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Stats Card
                          if (favoriteState.stats != null)
                            Card(
                              margin: const EdgeInsets.all(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      context,
                                      'Tổng số',
                                      favoriteState.stats!.totalFavorites.toString(),
                                      Icons.favorite,
                                      Colors.red,
                                    ),
                                    _buildStatItem(
                                      context,
                                      'Đang tuyển',
                                      favoriteState.stats!.activeFavorites.toString(),
                                      Icons.work,
                                      Colors.green,
                                    ),
                                    _buildStatItem(
                                      context,
                                      'Tuần này',
                                      favoriteState.stats!.recentFavorites.toString(),
                                      Icons.access_time,
                                      Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Favorites List
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: favoriteState.favoriteJobs.length,
                              itemBuilder: (context, index) {
                                final favorite = favoriteState.favoriteJobs[index];
                                return FavoriteJobCard(
                                  favorite: favorite,
                                  onRemove: () async {
                                    final result = await ref
                                        .read(favoriteProvider.notifier)
                                        .removeFromFavorite(favorite.jobId);
                                    
                                    if (result && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã xóa khỏi danh sách yêu thích'),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class FavoriteJobCard extends StatelessWidget {
  final dynamic favorite; // FavoriteJobDto
  final VoidCallback onRemove;

  const FavoriteJobCard({
    super.key,
    required this.favorite,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: favorite.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.work,
            color: favorite.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          favorite.jobTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(favorite.companyName),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  favorite.location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  favorite.salary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') {
              _showRemoveDialog(context);
            } else if (value == 'view') {
              context.go('/candidate/jobs/${favorite.jobId}');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Xem chi tiết'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa khỏi yêu thích'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => context.go('/candidate/jobs/${favorite.jobId}'),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi yêu thích'),
        content: Text('Bạn có muốn xóa "${favorite.jobTitle}" khỏi danh sách yêu thích?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

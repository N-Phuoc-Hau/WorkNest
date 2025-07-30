import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/job_provider.dart';
import '../../../shared/widgets/job_card.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSpecialized;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobProvider.notifier).getJobPosts();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMore() {
    final state = ref.read(jobProvider);
    if (!state.isLoading && state.currentPage < state.totalPages) {
      ref.read(jobProvider.notifier).getJobPosts(
            page: state.currentPage + 1,
            search: _searchController.text.isNotEmpty ? _searchController.text : null,
            specialized: _selectedSpecialized,
            location: _selectedLocation,
            loadMore: true,
          );
    }
  }

  void _search() {
    ref.read(jobProvider.notifier).getJobPosts(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          specialized: _selectedSpecialized,
          location: _selectedLocation,
        );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => JobFilterBottomSheet(
        selectedSpecialized: _selectedSpecialized,
        selectedLocation: _selectedLocation,
        onApplyFilter: (specialized, location) {
          setState(() {
            _selectedSpecialized = specialized;
            _selectedLocation = location;
          });
          _search();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobProvider);
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm việc làm'),
        elevation: 0,
        actions: !isLoggedIn ? [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Đăng nhập'),
          ),
          TextButton(
            onPressed: () => context.go('/register'),
            child: const Text('Đăng ký'),
          ),
        ] : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công việc...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: _search,
                        icon: const Icon(Icons.send),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: (_selectedSpecialized != null || _selectedLocation != null)
                        ? Theme.of(context).primaryColor
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _showFilterBottomSheet,
                    icon: Icon(
                      Icons.filter_list,
                      color: (_selectedSpecialized != null || _selectedLocation != null)
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(jobProvider.notifier).getJobPosts(
                search: _searchController.text.isNotEmpty ? _searchController.text : null,
                specialized: _selectedSpecialized,
                location: _selectedLocation,
              );
        },
        child: jobsState.isLoading && jobsState.jobs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : jobsState.error != null && jobsState.jobs.isEmpty
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
                          jobsState.error!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(jobProvider.notifier).getJobPosts(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : jobsState.jobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_off_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy công việc nào',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: jobsState.jobs.length + (jobsState.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == jobsState.jobs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final job = jobsState.jobs[index];
                          return JobCard(job: job);
                        },
                      ),
      ),
    );
  }
}

class JobFilterBottomSheet extends StatefulWidget {
  final String? selectedSpecialized;
  final String? selectedLocation;
  final Function(String?, String?) onApplyFilter;

  const JobFilterBottomSheet({
    super.key,
    this.selectedSpecialized,
    this.selectedLocation,
    required this.onApplyFilter,
  });

  @override
  State<JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends State<JobFilterBottomSheet> {
  String? _specialized;
  String? _location;

  final List<String> _specializations = [
    'Công nghệ thông tin',
    'Kế toán',
    'Nhân sự',
    'Marketing',
    'Bán hàng',
    'Thiết kế',
    'Y tế',
    'Giáo dục',
    'Du lịch',
    'Ngân hàng',
  ];

  final List<String> _locations = [
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Biên Hòa',
    'Nha Trang',
    'Huế',
    'Vũng Tàu',
    'Quy Nhon',
  ];

  @override
  void initState() {
    super.initState();
    _specialized = widget.selectedSpecialized;
    _location = widget.selectedLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _specialized = null;
                    _location = null;
                  });
                },
                child: const Text('Xóa tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Chuyên ngành',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _specializations.map((spec) {
              final isSelected = _specialized == spec;
              return FilterChip(
                label: Text(spec),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _specialized = selected ? spec : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Địa điểm',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _locations.map((loc) {
              final isSelected = _location == loc;
              return FilterChip(
                label: Text(loc),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _location = selected ? loc : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilter(_specialized, _location);
                Navigator.pop(context);
              },
              child: const Text('Áp dụng bộ lọc'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class JobFilterBottomSheet extends StatefulWidget {
  final String? initialSpecialized;
  final String? initialLocation;

  const JobFilterBottomSheet({
    super.key,
    this.initialSpecialized,
    this.initialLocation,
  });

  @override
  State<JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends State<JobFilterBottomSheet> {
  final _specializedController = TextEditingController();
  final _locationController = TextEditingController();

  // Predefined options
  final List<String> _specializedOptions = [
    'Công nghệ thông tin',
    'Marketing',
    'Kinh doanh',
    'Nhân sự',
    'Tài chính - Kế toán',
    'Thiết kế',
    'Giáo dục',
    'Y tế',
    'Xây dựng',
    'Du lịch - Khách sạn',
  ];

  final List<String> _locationOptions = [
    'Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Cần Thơ',
    'Hải Phòng',
    'Biên Hòa',
    'Nha Trang',
    'Huế',
    'Vũng Tàu',
    'Đà Lạt',
  ];

  String? _selectedSpecialized;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedSpecialized = widget.initialSpecialized;
    _selectedLocation = widget.initialLocation;
    _specializedController.text = widget.initialSpecialized ?? '';
    _locationController.text = widget.initialLocation ?? '';
  }

  @override
  void dispose() {
    _specializedController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bộ lọc tìm kiếm',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Xóa tất cả'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Specialized section
                      Text(
                        'Chuyên ngành',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      AppTextField(
                        controller: _specializedController,
                        label: 'Nhập chuyên ngành',
                        hintText: 'VD: Công nghệ thông tin',
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialized = value.isEmpty ? null : value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _specializedOptions.map((option) {
                          final isSelected = _selectedSpecialized == option;
                          return FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSpecialized = option;
                                  _specializedController.text = option;
                                } else {
                                  _selectedSpecialized = null;
                                  _specializedController.clear();
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Location section
                      Text(
                        'Địa điểm',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      AppTextField(
                        controller: _locationController,
                        label: 'Nhập địa điểm',
                        hintText: 'VD: Hồ Chí Minh',
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value.isEmpty ? null : value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _locationOptions.map((option) {
                          final isSelected = _selectedLocation == option;
                          return FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedLocation = option;
                                  _locationController.text = option;
                                } else {
                                  _selectedLocation = null;
                                  _locationController.clear();
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                
                // Action buttons
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: 'Áp dụng',
                          onPressed: _applyFilters,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecialized = null;
      _selectedLocation = null;
      _specializedController.clear();
      _locationController.clear();
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop({
      'specialized': _selectedSpecialized,
      'location': _selectedLocation,
    });
  }
}

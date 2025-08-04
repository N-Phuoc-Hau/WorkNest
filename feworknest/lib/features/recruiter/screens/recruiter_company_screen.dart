import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecruiterCompanyScreen extends ConsumerStatefulWidget {
  const RecruiterCompanyScreen({super.key});

  @override
  ConsumerState<RecruiterCompanyScreen> createState() => _RecruiterCompanyScreenState();
}

class _RecruiterCompanyScreenState extends ConsumerState<RecruiterCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'TechCorp Solutions');
  final _descriptionController = TextEditingController(
    text: 'Công ty chuyên về phát triển phần mềm và ứng dụng di động với đội ngũ nhân viên trẻ, năng động.',
  );
  final _websiteController = TextEditingController(text: 'https://techcorp.com');
  final _addressController = TextEditingController(text: '123 Đường ABC, Quận 1, TP.HCM');
  final _phoneController = TextEditingController(text: '028-1234-5678');
  final _emailController = TextEditingController(text: 'contact@techcorp.com');

  String _selectedIndustry = 'Công nghệ thông tin';
  String _selectedSize = '50-100';
  String _selectedLocation = 'TP.HCM';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin công ty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCompanyInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo Section
              _buildLogoSection(),
              
              const SizedBox(height: 24),
              
              // Basic Information Section
              _buildSectionHeader('Thông tin cơ bản'),
              _buildTextField(
                controller: _nameController,
                label: 'Tên công ty',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên công ty';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Ngành nghề',
                value: _selectedIndustry,
                items: const [
                  'Công nghệ thông tin',
                  'Tài chính - Ngân hàng',
                  'Giáo dục',
                  'Y tế',
                  'Bán lẻ',
                  'Sản xuất',
                  'Khác',
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedIndustry = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Quy mô công ty',
                value: _selectedSize,
                items: const [
                  'Dưới 10',
                  '10-50',
                  '50-100',
                  '100-500',
                  '500-1000',
                  'Trên 1000',
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSize = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildDropdownField(
                label: 'Địa điểm',
                value: _selectedLocation,
                items: const [
                  'Hà Nội',
                  'TP.HCM',
                  'Đà Nẵng',
                  'Cần Thơ',
                  'Hải Phòng',
                  'Khác',
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Contact Information Section
              _buildSectionHeader('Thông tin liên hệ'),
              _buildTextField(
                controller: _addressController,
                label: 'Địa chỉ',
                icon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _websiteController,
                label: 'Website',
                icon: Icons.language,
                keyboardType: TextInputType.url,
              ),
              
              const SizedBox(height: 24),
              
              // Company Description Section
              _buildSectionHeader('Mô tả công ty'),
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả',
                icon: Icons.description,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả công ty';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Company Statistics Section
              _buildSectionHeader('Thống kê công ty'),
              _buildStatisticsCards(),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previewCompany,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Xem trước'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveCompanyInfo,
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu thay đổi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue[100],
            child: Text(
              'TC',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _changeLogo,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Thay đổi logo'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Tin tuyển dụng',
            value: '8',
            icon: Icons.work,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Ứng viên',
            value: '45',
            icon: Icons.people,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Đã tuyển',
            value: '12',
            icon: Icons.check_circle,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _changeLogo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng thay đổi logo đang phát triển')),
    );
  }

  void _previewCompany() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xem trước trang công ty'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tính năng xem trước trang công ty đang phát triển...'),
          ],
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

  void _saveCompanyInfo() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thông tin công ty đã được cập nhật thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/register_image_picker_widget.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  // For recruiter registration
  final _companyNameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRecruiter = false;
  
  // Image files for registration
  XFile? _avatarFile;
  List<XFile> _companyImageFiles = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _taxCodeController.dispose();
    _companyDescriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authProvider.notifier);
    
    Map<String, dynamic> userData = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
    };

    // Add avatar if selected
    // Avatar file will be handled separately in registerWithFiles

    print('DEBUG RegisterScreen: userData before register: $userData');
    print('DEBUG RegisterScreen: isRecruiter: $_isRecruiter');

    if (_isRecruiter) {
      // Validate company images
      if (_companyImageFiles.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Công ty phải có ít nhất 3 ảnh môi trường làm việc'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      userData.addAll({
        'companyName': _companyNameController.text.trim(),
        'taxCode': _taxCodeController.text.trim(),
        'description': _companyDescriptionController.text.trim(),
        'location': _locationController.text.trim(),
      });
    }

    final success = await authNotifier.registerWithFiles(
      userData, 
      isRecruiter: _isRecruiter,
      avatarFile: _avatarFile,
      companyImageFiles: _companyImageFiles,
    );

    print('DEBUG RegisterScreen: Registration result: $success');

    if (success && mounted) {
      print('DEBUG RegisterScreen: Registration SUCCESS, navigating to login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    } else if (mounted) {
      print('DEBUG RegisterScreen: Registration FAILED, staying on register page');
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Đăng ký thất bại'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Force rebuild to show error state
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role selector
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRecruiter = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: !_isRecruiter
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Ứng viên',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_isRecruiter
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRecruiter = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _isRecruiter
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Nhà tuyển dụng',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isRecruiter
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Personal information
                Text(
                  'Thông tin cá nhân',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Avatar picker
                RegisterImagePickerWidget(
                  label: 'Ảnh đại diện (tùy chọn)',
                  isMultiple: false,
                  onSingleImageSelected: (file) {
                    setState(() {
                      _avatarFile = file;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _firstNameController,
                        label: 'Họ',
                        hintText: 'Nhập họ của bạn',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập họ';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _lastNameController,
                        label: 'Tên',
                        hintText: 'Nhập tên của bạn',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Nhập email của bạn',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu của bạn',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  hintText: 'Nhập lại mật khẩu',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _passwordController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),
                
                // Company information (for recruiters)
                if (_isRecruiter) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Thông tin công ty',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _companyNameController,
                    label: 'Tên công ty',
                    hintText: 'Nhập tên công ty',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên công ty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _taxCodeController,
                    label: 'Mã số thuế',
                    hintText: 'Nhập mã số thuế công ty',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mã số thuế';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _locationController,
                    label: 'Địa chỉ',
                    hintText: 'Nhập địa chỉ công ty',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa chỉ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    controller: _companyDescriptionController,
                    label: 'Mô tả công ty',
                    hintText: 'Nhập mô tả về công ty',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mô tả công ty';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Company images picker
                  RegisterImagePickerWidget(
                    label: 'Ảnh môi trường làm việc (tối thiểu 3 ảnh)',
                    isMultiple: true,
                    maxImages: 5,
                    onSingleImageSelected: (file) {}, // Not used for multiple
                    onMultipleImagesSelected: (files) {
                      setState(() {
                        _companyImageFiles = files;
                      });
                    },
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Error message display
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Register button
                AppButton(
                  onPressed: authState.isLoading ? null : _register,
                  isLoading: authState.isLoading,
                  text: 'Đăng ký',
                ),
                const SizedBox(height: 16),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản? '),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Đăng nhập ngay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

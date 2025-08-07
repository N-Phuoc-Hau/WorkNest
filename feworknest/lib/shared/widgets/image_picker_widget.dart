import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/upload_provider.dart';

class ImagePickerWidget extends ConsumerStatefulWidget {
  final String label;
  final String? initialImageUrl;
  final Function(String) onImageSelected;
  final bool isMultiple;
  final int maxImages;
  final String uploadFolder;

  const ImagePickerWidget({
    super.key,
    required this.label,
    this.initialImageUrl,
    required this.onImageSelected,
    this.isMultiple = false,
    this.maxImages = 1,
    this.uploadFolder = 'images',
  });

  @override
  ConsumerState<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends ConsumerState<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  
  List<String> _selectedImageUrls = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialImageUrl != null) {
      _selectedImageUrls.add(widget.initialImageUrl!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        if (kIsWeb) {
          // On web, work with XFile directly
          await _uploadImageWeb(image);
        } else {
          // On mobile, convert to File
          await _uploadImage(File(image.path));
        }
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _uploadImageWeb(XFile imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      String imageUrl;
      
      // Try public upload first (for registration), fallback to authenticated upload
      final publicUploadService = ref.read(publicUploadServiceProvider);
      final uploadService = ref.read(uploadServiceProvider);
      
      try {
        if (widget.uploadFolder == 'avatars') {
          imageUrl = await publicUploadService.uploadAvatarWeb(imageFile);
        } else {
          imageUrl = await publicUploadService.uploadImageWeb(imageFile, folder: widget.uploadFolder);
        }
      } catch (e) {
        // Fallback to authenticated upload if public upload fails
        if (widget.uploadFolder == 'avatars') {
          imageUrl = await uploadService.uploadAvatarWeb(imageFile);
        } else {
          imageUrl = await uploadService.uploadImageWeb(imageFile, folder: widget.uploadFolder);
        }
      }

      setState(() {
        if (widget.isMultiple) {
          if (_selectedImageUrls.length < widget.maxImages) {
            _selectedImageUrls.add(imageUrl);
          } else {
            _selectedImageUrls[_selectedImageUrls.length - 1] = imageUrl;
          }
        } else {
          _selectedImageUrls = [imageUrl];
        }
      });

      // Notify parent widget about the selected images
      if (widget.isMultiple) {
        widget.onImageSelected(_selectedImageUrls.join(','));
      } else {
        widget.onImageSelected(imageUrl);
      }

    } catch (e) {
      _showErrorSnackBar('Lỗi khi tải ảnh lên: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      String imageUrl;
      
      // Try public upload first (for registration), fallback to authenticated upload
      final publicUploadService = ref.read(publicUploadServiceProvider);
      final uploadService = ref.read(uploadServiceProvider);
      
      try {
        if (widget.uploadFolder == 'avatars') {
          imageUrl = await publicUploadService.uploadAvatar(imageFile);
        } else {
          imageUrl = await publicUploadService.uploadImage(imageFile, folder: widget.uploadFolder);
        }
      } catch (e) {
        // Fallback to authenticated upload if public upload fails
        if (widget.uploadFolder == 'avatars') {
          imageUrl = await uploadService.uploadAvatar(imageFile);
        } else {
          imageUrl = await uploadService.uploadImage(imageFile, folder: widget.uploadFolder);
        }
      }

      setState(() {
        if (widget.isMultiple) {
          if (_selectedImageUrls.length < widget.maxImages) {
            _selectedImageUrls.add(imageUrl);
          } else {
            _selectedImageUrls[_selectedImageUrls.length - 1] = imageUrl;
          }
        } else {
          _selectedImageUrls = [imageUrl];
        }
      });

      // Notify parent widget
      if (widget.isMultiple) {
        widget.onImageSelected(_selectedImageUrls.join(','));
      } else {
        widget.onImageSelected(imageUrl);
      }

      _showSuccessSnackBar('Tải ảnh thành công!');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi tải ảnh: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickMultipleImagesWeb() async {
    try {
      final List<XFile> images = await _picker.pickMultipleMedia(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (images.isNotEmpty) {
        for (final image in images) {
          if (_selectedImageUrls.length >= widget.maxImages) break;
          await _uploadImageWeb(image);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImageUrls.removeAt(index);
    });

    if (widget.isMultiple) {
      widget.onImageSelected(_selectedImageUrls.join(','));
    } else {
      widget.onImageSelected('');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn ảnh từ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Máy ảnh'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Thư viện ảnh'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (widget.isMultiple && kIsWeb) {
                    _pickMultipleImagesWeb();
                  } else {
                    _pickImage(ImageSource.gallery);
                  }
                },
              ),
              if (widget.isMultiple && kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Chọn nhiều ảnh'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickMultipleImagesWeb();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        if (widget.isMultiple) ...[
          // Multiple images grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImageUrls.length + (_selectedImageUrls.length < widget.maxImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _selectedImageUrls.length) {
                // Add button
                return _buildAddButton();
              }
              return _buildImageItem(_selectedImageUrls[index], index);
            },
          ),
        ] else ...[
          // Single image
          if (_selectedImageUrls.isNotEmpty)
            _buildSingleImage(_selectedImageUrls.first)
          else
            _buildAddButton(),
        ],
        
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Đang tải ảnh...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
              SizedBox(height: 4),
              Text(
                'Thêm ảnh',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, size: 50, color: Colors.grey),
                      );
                    },
                  )
                : Image.file(
                    File(imageUrl),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeImage(0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(String imageUrl, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, size: 30, color: Colors.grey),
                      );
                    },
                  )
                : Image.file(
                    File(imageUrl),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 
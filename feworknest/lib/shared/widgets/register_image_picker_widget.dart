import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterImagePickerWidget extends StatefulWidget {
  final String label;
  final Function(XFile?) onSingleImageSelected;
  final Function(List<XFile>)? onMultipleImagesSelected;
  final bool isMultiple;
  final int maxImages;

  const RegisterImagePickerWidget({
    super.key,
    required this.label,
    required this.onSingleImageSelected,
    this.onMultipleImagesSelected,
    this.isMultiple = false,
    this.maxImages = 1,
  });

  @override
  State<RegisterImagePickerWidget> createState() => _RegisterImagePickerWidgetState();
}

class _RegisterImagePickerWidgetState extends State<RegisterImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  
  List<XFile> _selectedFiles = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (widget.isMultiple) {
        // Pick single image for multiple collection (user can pick multiple times)
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (image != null) {
          setState(() {
            _selectedFiles.add(image);
            if (_selectedFiles.length > widget.maxImages) {
              _selectedFiles = _selectedFiles.take(widget.maxImages).toList();
            }
          });
          
          widget.onMultipleImagesSelected?.call(_selectedFiles);
        }
      } else {
        // Pick single image
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (image != null) {
          setState(() {
            _selectedFiles = [image];
          });
          
          widget.onSingleImageSelected(image);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });

    if (widget.isMultiple) {
      widget.onMultipleImagesSelected?.call(_selectedFiles);
    } else {
      widget.onSingleImageSelected(null);
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
              if (!kIsWeb) // Camera chỉ có trên mobile
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
                title: Text(widget.isMultiple ? 'Chọn ảnh' : 'Thư viện ảnh'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
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

  Widget _buildImagePreview(XFile file, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    file.path,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  )
                : Image.file(
                    File(file.path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
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
        
        // Selected images preview
        if (_selectedFiles.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              children: _selectedFiles.asMap().entries.map((entry) {
                return _buildImagePreview(entry.value, entry.key);
              }).toList(),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Add image button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              if (widget.isMultiple && _selectedFiles.length >= widget.maxImages) {
                _showErrorSnackBar('Đã chọn tối đa ${widget.maxImages} ảnh');
                return;
              }
              _showImageSourceDialog();
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(
              _selectedFiles.isEmpty
                  ? (widget.isMultiple ? 'Chọn ảnh (${widget.maxImages} ảnh)' : 'Chọn ảnh')
                  : (widget.isMultiple 
                      ? 'Thêm ảnh (${_selectedFiles.length}/${widget.maxImages})'
                      : 'Thay đổi ảnh'),
            ),
          ),
        ),
        
        if (widget.isMultiple && _selectedFiles.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Cần ít nhất 3 ảnh môi trường làm việc',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

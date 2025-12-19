// ignore_for_file: non_constant_identifier_names, unused_field

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';

/// EditPostPage - Halaman untuk mengedit post
/// 
/// Hanya bisa diakses oleh:
/// 1. Pemilik post (user yang membuat)
/// 2. Superuser/admin
/// 
/// Cara pakai:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => EditPostPage(post: postData),
///   ),
/// );
/// ```
/// 
/// Endpoint API: `POST /post/api/posts/<id>/edit/`
class EditPostPage extends StatefulWidget {
  const EditPostPage({super.key, required this.post});

  final ProfileFeedItem post; // Data post yang akan diedit

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  // Form key untuk validasi
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk form fields
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  late TextEditingController _videoUrlController;

  // State management
  bool _isLoading = false;
  String? _error;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form dengan data existing
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _imageUrlController = TextEditingController(text: widget.post.image ?? '');
    _videoUrlController = TextEditingController(text: widget.post.videoLink ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  /// Validasi form dan kirim ke API
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = Provider.of<CookieRequest>(context, listen: false);
      final postId = widget.post.id;

      // Data yang akan dikirim
      final data = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'image': _imageUrlController.text.trim(),
        'video': _videoUrlController.text.trim(),
      };

      // Kirim ke API Django
      // Pastikan endpoint ini ada di Django: POST /post/api/posts/<id>/edit/
      final response = await request.post(
        'http://localhost:8000/post/api/posts/$postId/edit/',
        data,
      );

      if (!mounted) return;

      // Cek response dari API
      if (response is Map<String, dynamic> && response['status'] == 'success') {
        // Kembali ke halaman sebelumnya dengan membawa data terbaru
        Navigator.of(context).pop(true); // true = berhasil
      } else {
        final errorMsg = response?['message'] ?? 'Gagal mengedit post.';
        setState(() => _error = errorMsg);
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Cek apakah ada perubahan data
  void _checkForChanges() {
    final hasChanges =
        _titleController.text.trim() != widget.post.title ||
        _contentController.text.trim() != widget.post.content ||
        _imageUrlController.text.trim() != (widget.post.image ?? '') ||
        _videoUrlController.text.trim() != (widget.post.videoLink ?? '');

    setState(() => _hasChanges = hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // Save button
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: _checkForChanges,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title field
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Masukkan judul post...',
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Content field
            _buildTextField(
              controller: _contentController,
              label: 'Content',
              hint: 'Tulis konten post...',
              maxLines: 6,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Konten tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Image URL field
            _buildTextField(
              controller: _imageUrlController,
              label: 'Image URL (Optional)',
              hint: 'https://example.com/image.jpg',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),

            // Preview image jika ada URL
            if (_imageUrlController.text.isNotEmpty)
              _buildImagePreview(_imageUrlController.text),
            const SizedBox(height: 20),

            // Video URL field
            _buildTextField(
              controller: _videoUrlController,
              label: 'YouTube URL (Optional)',
              hint: 'https://youtube.com/watch?v=...',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),

            // Preview video jika ada URL
            if (_videoUrlController.text.isNotEmpty)
              _buildVideoPreview(_videoUrlController.text, context),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 20),
              _buildErrorMessage(_error!),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Widget TextFormField reusable
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLines,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (_) => _checkForChanges(),
    );
  }

  /// Preview gambar dari URL
  Widget _buildImagePreview(String url) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal load gambar',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Preview video dari URL
  Widget _buildVideoPreview(String url, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: _YoutubePreview(url: url, onTap: () {}),
    );
  }

  /// Widget error message
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Preview widget untuk YouTube video
  Widget _YoutubePreview({required String url, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade200,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.red.shade700,
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
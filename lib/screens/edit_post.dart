// ignore_for_file: non_constant_identifier_names, unused_field

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';

/**
 * EditPostPage - Halaman edit post dengan tema gelap modern
 * 
 * Fitur:
 * - Gradient background biru-ungu gelap
 * - Form dengan validasi real-time
 * - Preview gambar/video langsung
 * - Loading state dengan indikator
 * - Error handling yang user-friendly
 * 
 * Hak akses:
 * - Hanya pemilik post atau superuser
 * 
 * Endpoint: POST /post/api/posts/<id>/edit/
 * 
 * Cara pakai:
 * ```dart
 * Navigator.push(
 *   context,
 *   MaterialPageRoute(
 *     builder: (_) => EditPostPage(post: postData),
 *   ),
 * );
 * ```
 */
class EditPostPage extends StatefulWidget {
  const EditPostPage({super.key, required this.post});

  final ProfileFeedItem post;

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  late TextEditingController _videoUrlController;

  // State
  bool _isLoading = false;
  String? _error;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
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

  /// Simpan perubahan ke API
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = Provider.of<CookieRequest>(context, listen: false);
      final postId = widget.post.id;

      final data = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'image': _imageUrlController.text.trim(),
        'video': _videoUrlController.text.trim(),
      };

      final response = await request.post(
        'http://localhost:8000/post/api/posts/$postId/edit/',
        data,
      );

      if (!mounted) return;

      if (response is Map<String, dynamic> && response['status'] == 'success') {
        Navigator.of(context).pop(true); // Kembali dengan sukses
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

  /// Cek perubahan form
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
      extendBodyBehindAppBar: true, // AppBar transparan
      appBar: AppBar(
        title: const Text(
          'Edit Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F2027), // Biru tua
              const Color(0xFF203A43), // Biru keunguan
              const Color(0xFF2C5364), // Ungu tua
            ],
          ),
        ),
        child: SafeArea( // Hindari notch dan status bar
          child: Form(
            key: _formKey,
            onChanged: _checkForChanges,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
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

                _buildTextField(
                  controller: _imageUrlController,
                  label: 'Image URL (Optional)',
                  hint: 'https://example.com/image.jpg',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),

                if (_imageUrlController.text.isNotEmpty)
                  _buildImagePreview(_imageUrlController.text),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _videoUrlController,
                  label: 'YouTube URL (Optional)',
                  hint: 'https://youtube.com/watch?v=...',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),

                if (_videoUrlController.text.isNotEmpty)
                  _buildVideoPreview(_videoUrlController.text, context),

                if (_error != null) ...[
                  const SizedBox(height: 20),
                  _buildErrorMessage(_error!),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// TextFormField dengan tema gelap
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade300,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (_) => _checkForChanges(),
    );
  }

  /// Preview gambar
  Widget _buildImagePreview(String url) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                  const Icon(Icons.error, color: Colors.redAccent),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal load gambar',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Preview video
  Widget _buildVideoPreview(String url, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: _YoutubePreview(url: url, onTap: () {}),
    );
  }

  /// Error message
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade300,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// YouTube preview
  Widget _YoutubePreview({required String url, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
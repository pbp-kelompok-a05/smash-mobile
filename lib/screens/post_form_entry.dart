// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures, unused_import

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/post_entry.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman form untuk membuat post baru dengan glassmorphism UI
class PostEntryFormPage extends StatefulWidget {
  const PostEntryFormPage({super.key});

  @override
  State<PostEntryFormPage> createState() => _PostEntryFormPageState();
}

class _PostEntryFormPageState extends State<PostEntryFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  bool _isSubmitting = false;

  /// Endpoint API untuk membuat post
  static const String _createEndpoint =
      'http://localhost:8000/post/api/create/';

  /// Controller untuk animasi fade-in
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Jalankan animasi setelah build selesai
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    _videoCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Validasi dan submit form ke API
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final request = context.read<CookieRequest>();
    final postData = {
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'image': _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      'video': _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim(),
    };

    try {
      final response = await request.postJson(
        _createEndpoint,
        jsonEncode(postData),
      );

      if (!mounted) return;

      // Cek response sukses (sesuaikan dengan backend Anda)
      final isSuccess =
          response is Map &&
          (response['status'] == 'success' || response['status'] == true);

      if (isSuccess) {
        _showSuccess('Post created successfully!');
        // Kembali ke halaman utama setelah sukses
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MyHomePage()),
        );
      } else {
        final message = response is Map
            ? response['message'] ?? 'Failed to create post'
            : 'Failed to create post';
        _showError(message);
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Tampilkan snackbar sukses
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Tampilkan snackbar error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background gradient konsisten dengan halaman lain
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4A2B55), // ungu gelap
              const Color(0xFF6A2B53), // ungu medium
              const Color(0xFF9D50BB), // ungu kebiruan
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animationController,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header dengan judul dan ikon kembali
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Create New Post',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphism card untuk form
                  _buildGlassCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget glassmorphism card untuk form
  Widget _buildGlassCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // Transparan 15%
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  Text(
                    'Title *',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleCtrl,
                    hint: 'Enter post title',
                    icon: Icons.title,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Title is required';
                      if (v.length < 5)
                        return 'Title must be at least 5 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Content field
                  Text(
                    'Content *',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _contentCtrl,
                    hint: 'Write your post content...',
                    icon: Icons.article_outlined,
                    maxLines: 5,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Content is required';
                      if (v.length < 10)
                        return 'Content must be at least 10 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Image URL field (optional)
                  Text(
                    'Image URL (Optional)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _imageCtrl,
                    hint: 'https://example.com/image.jpg',
                    icon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
                    validator: (String? p1) {
                      return;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Video URL field (optional)
                  Text(
                    'Video URL (Optional)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _videoCtrl,
                    hint: 'https://youtube.com/watch?v=...',
                    icon: Icons.video_library_outlined,
                    keyboardType: TextInputType.url,
                    validator: (String? p1) {
                      return;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A2B55),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4A2B55),
                            ),
                          )
                        : Text(
                            'Create Post',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget reusable untuk text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

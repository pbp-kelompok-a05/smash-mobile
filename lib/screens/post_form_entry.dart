// ignore_for_file: unused_import, deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';

/// Halaman form untuk membuat post baru dengan glassmorphism UI
/// Hanya dapat diakses oleh user yang sudah login
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

  /// [PERUBAHAN] Endpoint yang benar sesuai post/urls.py
  /// POST ke /post/api/posts/ untuk create new post
  static const String _createEndpoint = 'http://localhost:8000/post/api/posts/';

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
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

  /// Submit form ke API dengan method POST
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final request = context.read<CookieRequest>();
    
    // [PERUBAHAN] Hanya kirim field yang tidak kosong
    final postData = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
    };
    
    // Tambahkan field opsional jika tidak kosong
    if (_imageCtrl.text.trim().isNotEmpty) {
      postData['image'] = _imageCtrl.text.trim();
    }
    if (_videoCtrl.text.trim().isNotEmpty) {
      postData['video'] = _videoCtrl.text.trim();
    }

    try {
      // [PERUBAHAN] Gunakan postJson dengan data langsung (tidak perlu jsonEncode)
      final response = await request.postJson(_createEndpoint, jsonEncode(postData));

      if (!mounted) return;

      // [PERUBAHAN] Validasi response sesuai Django Rest Framework
      final isSuccess = response != null && 
                       response is Map<String, dynamic> && 
                       (response.containsKey('id') || response['status'] == 'success');

      if (isSuccess) {
        _showSuccess('Post created successfully!');
        // [PERUBAHAN] Kembali ke halaman sebelumnya setelah 1 detik
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true); // Kirim nilai true untuk refresh
      } else {
        final message = response is Map ? 
                       (response['message'] ?? response['detail'] ?? 'Failed to create post') : 
                       'Failed to create post';
        _showError(message);
      }
    } catch (e) {
      if (mounted) _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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

  /// [PERUBAHAN] Sederhanakan build method dengan extract widgets
  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    if (!request.loggedIn) return _buildLoginRequiredScreen();
    
    return _buildFormScreen();
  }

  /// [PERUBAHAN] Extract metode untuk form screen
  Widget _buildFormScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A2B55), Color(0xFF6A2B53), Color(0xFF9D50BB)],
            stops: [0.0, 0.5, 1.0],
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
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildGlassCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [PERUBAHAN] Extract widget untuk header
  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        Text(
          'Create New Post',
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ],
    );
  }

  /// [PERUBAHAN] Sederhanakan login required screen
  Widget _buildLoginRequiredScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF4A2B55), const Color(0xFF9D50BB)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animationController,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildGlassLoginCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [PERUBAHAN] Extract glass card untuk login
  Widget _buildGlassLoginCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLockIcon(),
          const SizedBox(height: 24),
          _buildLoginMessage(),
          const SizedBox(height: 32),
          _buildLoginButton(),
          const SizedBox(height: 12),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  Widget _buildLockIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Icon(Icons.lock_outline, size: 48, color: Colors.white),
    );
  }

  Widget _buildLoginMessage() {
    return Column(
      children: [
        Text('Login Required', style: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 12),
        Text('You need to be logged in to create a post',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmashLoginPage()),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A2B55),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: Text('Login', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildRegisterLink() {
    return TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmashRegisterPage()),
      ),
      child: Text("Don't have an account? Register",
        style: GoogleFonts.inter(color: Colors.white70, decoration: TextDecoration.underline),
      ),
    );
  }

  /// Glassmorphism card untuk form input
  Widget _buildGlassCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
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
                  _buildTitleField(),
                  const SizedBox(height: 20),
                  _buildContentField(),
                  const SizedBox(height: 20),
                  _buildImageField(),
                  const SizedBox(height: 20),
                  _buildVideoField(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title *', style: GoogleFonts.inter(
          fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _titleCtrl,
          hint: 'Enter post title',
          icon: Icons.title,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Title is required';
            if (v.length < 5) return 'Title must be at least 5 characters';
            if (v.length > 200) return 'Title too long (max 200)';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Content *', style: GoogleFonts.inter(
          fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _contentCtrl,
          hint: 'Write your post content...',
          icon: Icons.article_outlined,
          maxLines: 5,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Content is required';
            if (v.length < 10) return 'Content must be at least 10 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Image URL (Optional)', style: GoogleFonts.inter(
          fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _imageCtrl,
          hint: 'https://example.com/image.jpg',
          icon: Icons.image_outlined,
          keyboardType: TextInputType.url,
          validator: _validateUrl, // [PERUBAHAN] Tambahkan validator URL
        ),
      ],
    );
  }

  Widget _buildVideoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video URL (Optional)', style: GoogleFonts.inter(
          fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _videoCtrl,
          hint: 'https://youtube.com/watch?v=...',
          icon: Icons.video_library_outlined,
          keyboardType: TextInputType.url,
          validator: _validateUrl, // [PERUBAHAN] Tambahkan validator URL
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A2B55),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          : Text('Create Post', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  /// [PERUBAHAN] Widget reusable untuk text field
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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

  /// [PERUBAHAN] Validator untuk URL
  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlPattern.hasMatch(value)) return 'Invalid URL format';
    return null;
  }
}
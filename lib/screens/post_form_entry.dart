// ignore_for_file: unused_import, deprecated_member_use, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/screens/register.dart';

/// Halaman form untuk membuat post baru dengan glassmorphism UI
/// dan login required check
/// 
/// API Endpoint: POST http://localhost:8000/post/api/posts/
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
  /// Menggunakan endpoint: 'api/posts/' (method: POST)
  /// Sesuai dengan urls.py Django: path('api/posts/', views.PostAPIView.as_view(), name='post_api')
  static const String _createEndpoint = 'http://localhost:8000/post/api/posts/';

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
    
    // Siapkan data untuk dikirim ke API
    // Catatan: Sesuaikan field dengan model Post di backend Django
    // Biasanya field untuk media adalah 'image' dan 'video' atau 'image_url' dan 'video_url'
    final Map<String, dynamic> postData = {
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
    };

    // Tambahkan field optional jika diisi (sesuaikan dengan field di model Django)
    final imageText = _imageCtrl.text.trim();
    final videoText = _videoCtrl.text.trim();
    
    // Pilih salah satu format field berikut sesuai dengan model Django Anda:
    // Opsi 1: Jika model menggunakan 'image' dan 'video'
    if (imageText.isNotEmpty) postData['image'] = imageText;
    if (videoText.isNotEmpty) postData['video'] = videoText;
    
    // Opsi 2: Jika model menggunakan 'image_url' dan 'video_url'
    // if (imageText.isNotEmpty) postData['image_url'] = imageText;
    // if (videoText.isNotEmpty) postData['video_url'] = videoText;

    try {
      // Kirim request POST ke endpoint
      final response = await request.postJson(
        _createEndpoint,
        jsonEncode(postData),
      );

      if (!mounted) return;

      // Cek response sukses
      // Django REST Framework biasanya mengembalikan:
      // - Status 201 Created untuk POST sukses
      // - Objek dengan field 'id' untuk resource yang dibuat
      // Custom views mungkin mengembalikan format berbeda
      bool isSuccess = false;
      String successMessage = 'Post created successfully!';
      
      if (response is Map) {
        // Format 1: Django REST Framework (mengembalikan objek dengan id)
        if (response.containsKey('id')) {
          isSuccess = true;
          successMessage = 'Post #${response['id']} created successfully!';
        } 
        // Format 2: Custom view dengan field 'status'
        else if (response['status'] == 'success' || response['status'] == true) {
          isSuccess = true;
          if (response.containsKey('message')) {
            successMessage = response['message'];
          }
        }
        // Format 3: Response dari PostAPIView (mungkin mengembalikan data post)
        else if (response.containsKey('title') || response.containsKey('content')) {
          isSuccess = true;
        }
      }

      if (isSuccess) {
        _showSuccess(successMessage);
        // Kembali ke halaman utama setelah sukses
        // Alternatif: Navigator.pop(context) untuk kembali ke halaman sebelumnya
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MyHomePage()),
        );
      } else {
        // Handle error response
        String errorMessage = 'Failed to create post';
        
        if (response is Map) {
          // Django REST Framework validation errors
          if (response.containsKey('errors')) {
            errorMessage = 'Validation errors: ${response['errors']}';
          } 
          // Custom error messages
          else if (response.containsKey('error')) {
            errorMessage = response['error'];
          } else if (response.containsKey('detail')) {
            errorMessage = response['detail'];
          } else if (response.containsKey('message')) {
            errorMessage = response['message'];
          }
          // Field-specific errors (common in DRF)
          else {
            final errors = <String>[];
            response.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errors.add('$key: ${value.first}');
              }
            });
            if (errors.isNotEmpty) {
              errorMessage = errors.join('\n');
            }
          }
        } else if (response is String) {
          errorMessage = response;
        }
        
        _showError(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Tampilkan snackbar sukses
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Tampilkan snackbar error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // === LOGIN CHECK & UI ===

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    // Jika user belum login, tampilkan halaman login required
    if (!request.loggedIn) {
      return _buildLoginRequiredScreen();
    }

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
                      Expanded(
                        child: Text(
                          'Create New Post',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Optional: Info icon untuk bantuan
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                          size: 22,
                        ),
                        onPressed: () {
                          _showInfoDialog();
                        },
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

  /// Dialog informasi tentang fitur posting
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Creating a Post',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A2B55),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tips for a great post:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoItem('📝', 'Title should be clear and descriptive'),
            _buildInfoItem('📄', 'Content should be detailed and valuable'),
            _buildInfoItem('🖼️', 'Image URL should be a direct link to an image'),
            _buildInfoItem('🎬', 'Video URL should be a link to YouTube or similar'),
            const SizedBox(height: 15),
            Text(
              'API Endpoint:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              _createEndpoint,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A2B55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Build login required screen dengan glassmorphism style
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
          child: Center(
            child: FadeTransition(
              opacity: _animationController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon lock dengan glass effect
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Glass card untuk pesan
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Login Required',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You need to be logged in to create a post',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SmashLoginPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4A2B55),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.2),
                            ),
                            child: Text(
                              'Login',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Register link
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SmashRegisterPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              "Don't have an account? Register",
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Glassmorphism card untuk form
  Widget _buildGlassCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
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
                  _buildFieldLabel('Title *', 'Required, at least 5 characters'),
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
                  _buildFieldLabel('Content *', 'Required, at least 10 characters'),
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
                  _buildFieldLabel('Image URL (Optional)', 'Direct link to image'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _imageCtrl,
                    hint: 'https://example.com/image.jpg',
                    icon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final urlPattern = RegExp(
                          r'^(https?://)?([\da-z.-]+)\.([a-z.]{2,6})([/\w .-]*)*/?$',
                          caseSensitive: false,
                        );
                        if (!urlPattern.hasMatch(v)) {
                          return 'Please enter a valid URL';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Video URL field (optional)
                  _buildFieldLabel('Video URL (Optional)', 'YouTube or video link'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _videoCtrl,
                    hint: 'https://youtube.com/watch?v=...',
                    icon: Icons.video_library_outlined,
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final urlPattern = RegExp(
                          r'^(https?://)?([\da-z.-]+)\.([a-z.]{2,6})([/\w .-]*)*/?$',
                          caseSensitive: false,
                        );
                        if (!urlPattern.hasMatch(v)) {
                          return 'Please enter a valid URL';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget untuk label field dengan subtitle
  Widget _buildFieldLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
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
      cursorColor: Colors.white,
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
        errorStyle: GoogleFonts.inter(color: Colors.red.shade300),
      ),
      validator: validator,
    );
  }

  /// Widget untuk submit button
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A2B55),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isSubmitting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF4A2B55).withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Creating Post...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Create Post',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
// ignore_for_file: unused_import, deprecated_member_use, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as http_browser;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/screens/register.dart';

/// Halaman form untuk membuat post baru dengan glassmorphism UI
/// dan login required check
///
/// API Endpoint: POST http://localhost:8000/post/api/posts/
class PostEditFormPage extends StatefulWidget {
  final ProfileFeedItem post;
  const PostEditFormPage({super.key, required this.post});

  @override
  State<PostEditFormPage> createState() => _PostEditFormPageState();
}

class _PostEditFormPageState extends State<PostEditFormPage>

    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _contentController = TextEditingController();
  late TextEditingController _videoController = TextEditingController();

  late AnimationController _animationController;
  String get _editEndpoint =>
      'http://localhost:8000/post/edit-flutter/${widget.post.id}/';
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _videoController = TextEditingController(text: widget.post.videoLink);
    // Jalankan animasi setelah build selesai
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  String? _selectedImageOption;
  final List<String> _imageOptions = [
    'No image',
    'Upload from device',
    'Choose from gallery',
  ];

  Uint8List? _pickedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedXFile;

  bool _submitting = false;

  /// Endpoint API untuk membuat post
  /// Menggunakan endpoint: 'api/posts/' (method: POST)
  /// Sesuai dengan urls.py Django: path('api/posts/', views.PostAPIView.as_view(), name='post_api')

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  bool _isYouTubeLink(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  /// Pilih gambar dari device menggunakan image_picker
  Future<void> _pickImage() async {
    try {
      final XFile? xfile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedXFile = xfile;
        _selectedImageOption = 'Upload from device';
      });
    } catch (e) {
      // ignore: avoid_print
      print('Image pick failed: $e');
    }
  }

  /// Validasi dan submit form ke API
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final video = _videoController.text.trim();

    String? inferredMime;
    if (_pickedXFile != null) {
      final p = _pickedXFile!.path.toLowerCase();
      if (p.endsWith('.png'))
        inferredMime = 'image/png';
      else if (p.endsWith('.jpg') || p.endsWith('.jpeg'))
        inferredMime = 'image/jpeg';
      else if (p.endsWith('.webp'))
        inferredMime = 'image/webp';
      else if (p.endsWith('.gif'))
        inferredMime = 'image/gif';
    }

    try {
      await _createPost(
        title: title,
        content: content,
        videoLink: video.isEmpty ? null : video,
        imageBytes: _pickedImageBytes,
        imageMime: inferredMime,
      );
      setState(() => _submitting = false);
      _showSuccess('Post created successfully!');
      Navigator.of(context).pop(true);
    } catch (err) {
      _showError('Failed to create post: $err');
    }
  }

  Future<Map<String, dynamic>> _createPost({
    required String title,
    required String content,
    String? videoLink,
    List<int>? imageBytes,
    String? imageMime,
    String? userId,
  }) async {
    final url = _editEndpoint;

    // If caller didn't provide a userId, try to obtain it from the logged-in session
    if (userId == null) {
      try {
        final request = context.read<CookieRequest>();
        final me = await request.get('http://localhost:8000/post/me/');
        if (me != null && me['id'] != null) userId = me['id'].toString();
      } catch (_) {
        // ignore and fall back to default
      }
    }

    final body = <String, dynamic>{
      'title': title,
      'content': content,
      'video_link': videoLink ?? '',
      'user_id': userId ?? '1',
    };

    if (imageBytes != null) {
      final b64 = base64Encode(imageBytes);
      final mime = imageMime ?? 'image/png';
      body['image'] = 'data:$mime;base64,$b64';
    }

    try {
      final request = context.read<CookieRequest>();
      final response = await request.post(url, body);

      if (response is Map<String, dynamic>) {
        // API may return status/message or the created post
        if (response['status'] == 'success' || response['status'] == true) {
          if (response.containsKey('post'))
            return Map<String, dynamic>.from(response['post']);
          return response;
        }
        // Some endpoints return the created object directly
        return response;
      }
      throw Exception('Create post failed: unexpected response: $response');
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  /// Tampilkan snackbar sukses
  void _showSuccess(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
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
            messenger.clearSnackBars();
          },
        ),
      ),
    );
  }

  /// Tampilkan snackbar error
  void _showError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
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
            messenger.clearSnackBars();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildInfoItem('📝', 'Title should be clear and descriptive'),
            _buildInfoItem('📄', 'Content should be detailed and valuable'),
            _buildInfoItem(
              '🖼️',
              'Image URL should be a direct link to an image',
            ),
            _buildInfoItem(
              '🎬',
              'Video URL should be a link to YouTube or similar',
            ),
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
              _editEndpoint,
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
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14))),
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
                                horizontal: 20,
                                vertical: 12,
                              ),
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
                  _buildFieldLabel(
                    'Title *',
                    'Required, at least 5 characters',
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
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
                  _buildFieldLabel(
                    'Content *',
                    'Required, at least 10 characters',
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _contentController,
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

                  // Image selector (optional) - prefer file picker over URL
                  _buildFieldLabel(
                    'Image (Optional)',
                    'Pick an image from device',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 80, 67, 78),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _pickedImageBytes != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(
                                    _pickedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        80,
                                        67,
                                        78,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                          size: 18,
                                        ),
                                        onPressed: () => setState(() {
                                          _pickedImageBytes = null;
                                          _pickedXFile = null;
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.upload,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Post Image (Optional)\nTap to select an image',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Video URL field (optional)
                  _buildFieldLabel(
                    'Video URL (Optional)',
                    'YouTube or video link',
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _videoController,
                    hint: 'https://youtube.com/watch?v=...',
                    icon: Icons.video_library_outlined,
                    keyboardType: TextInputType.url,
                    validator: (v) =>
                        (v != null && v.isNotEmpty && !_isYouTubeLink(v))
                        ? 'Only YouTube links are supported'
                        : null,
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
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
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
      onPressed: _submitting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A2B55),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _submitting
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

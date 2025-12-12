import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();

  String? _selectedImageOption;
  final List<String> _imageOptions = [
    'No image',
    'Upload from device',
    'Choose from gallery',
  ];

  Uint8List? _pickedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();

  bool _submitting = false;

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

  Widget _section({required Widget child, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

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
        _selectedImageOption = 'Upload from device';
      });
    } catch (e) {
      // ignore: avoid_print
      print('Image pick failed: $e');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    // Skeleton -- replace with real upload / API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post submitted (skeleton)')),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text('Add New Post'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD6F5E4), Color(0xFFFFECEF)],
            stops: [0.3, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section(
                          color: const Color(0xFFFFFFFF),
                          child: TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Post Title',
                              border: InputBorder.none,
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Title is required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _section(
                          color: const Color(0xFFF9FBFF),
                          child: TextFormField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              labelText: 'Post Content',
                              border: InputBorder.none,
                            ),
                            maxLines: 6,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Content is required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _section(
                          color: const Color(0xFFFFFFFF),
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                                            backgroundColor: Colors.black45,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              onPressed: () => setState(
                                                () => _pickedImageBytes = null,
                                              ),
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
                                            color: Colors.black54,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Post Image (Optional)\nTap to select an image',
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _section(
                          color: const Color(0xFFF9F5FF),
                          child: TextFormField(
                            controller: _videoController,
                            decoration: const InputDecoration(
                              labelText: 'YouTube Video Link (optional)',
                              border: InputBorder.none,
                            ),
                            validator: (v) =>
                                (v != null &&
                                    v.isNotEmpty &&
                                    !_isYouTubeLink(v))
                                ? 'Only YouTube links are supported'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _section(
                          color: const Color(0xFFFFFFFF),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit Post'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

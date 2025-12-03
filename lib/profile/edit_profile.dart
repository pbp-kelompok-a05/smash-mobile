import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


import 'widgets/navbar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.profile,
    required this.api,
  });

  final ProfileData? profile;
  final ProfileApi api;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;
  File? _selectedImage;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.profile?.username ?? '';
    _bioController.text = widget.profile?.bio ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2F3E0),
      appBar: CustomNavBar(
        username: widget.profile?.username ?? 'User',
        photoUrl: widget.profile?.profilePhoto,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD2F3E0), Color(0xFFFFE2E2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              const SizedBox(height: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: _avatarPreview(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.profile?.username ?? 'User',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _label('Username'),
              const SizedBox(height: 6),
              _textField(_usernameController),
              const SizedBox(height: 16),
              _label('Photo profile'),
              const SizedBox(height: 6),
              _uploadField(),
              const SizedBox(height: 16),
              _label('Bio'),
              const SizedBox(height: 6),
              _textField(
                _bioController,
                maxLines: 4,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              const SizedBox(height: 16),
              _label('Change password'),
              const SizedBox(height: 6),
              _passwordField(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF202726),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Update',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarPreview() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: 86,
        height: 86,
      );
    }
    if (widget.profile?.profilePhoto.isNotEmpty ?? false) {
      return Image.network(
        widget.profile!.profilePhoto,
        fit: BoxFit.cover,
        width: 86,
        height: 86,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/avatar.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(
      'assets/avatar.png',
      fit: BoxFit.cover,
      width: 86,
      height: 86,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _removePhoto = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final updated = await widget.api.updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        password: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(),
        profilePhoto: _selectedImage,
        removePhoto: _removePhoto,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
        ),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        hintText: 'Enter new password',
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _textField(TextEditingController controller,
      {int maxLines = 1, EdgeInsetsGeometry? contentPadding}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            contentPadding ?? const EdgeInsets.symmetric(horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black87, width: 1.2),
        ),
      ),
    );
  }

  Widget _uploadField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.file_upload_outlined, size: 20),
              tooltip: 'Pilih foto',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedImage != null
                  ? _selectedImage!.path.split(Platform.pathSeparator).last
                  : 'Upload photo',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _removePhoto ? Icons.check_box : Icons.check_box_outline_blank,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _removePhoto = !_removePhoto;
                if (_removePhoto) {
                  _selectedImage = null;
                }
              });
            },
            tooltip: 'Hapus foto profil',
          ),
        ],
      ),
    );
  }
}

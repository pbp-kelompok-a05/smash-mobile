// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smash_mobile/models/profile_entry.dart';

import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:smash_mobile/screens/login.dart';

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
  bool _isSaving = false;
  bool _isChangingPass = false;
  bool _isDeletingAccount = false;
  File? _selectedImage;
  Uint8List? _selectedBytes;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.profile?.username ?? '';
    _bioController.text = widget.profile?.bio ?? '';
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool obscureOld = true;
        bool obscureNew = true;
        bool obscureConfirm = true;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            InputDecoration dec(String hint) => InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.teal.shade400, width: 1.2),
                  ),
                );
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan password lama lalu password baru yang ingin digunakan.',
                    style: TextStyle(fontSize: 13.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: oldCtrl,
                    obscureText: obscureOld,
                    decoration: dec('Old Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureOld ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setStateDialog(
                            () => obscureOld = !obscureOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    decoration: dec('New Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setStateDialog(
                            () => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    decoration: dec('Confirm Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setStateDialog(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isChangingPass
                      ? null
                      : () async {
                          final oldPass = oldCtrl.text.trim();
                          final newPass = newCtrl.text.trim();
                          final confirmPass = confirmCtrl.text.trim();
                          if (oldPass.isEmpty ||
                              newPass.isEmpty ||
                              confirmPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Semua kolom password wajib diisi.')),
                            );
                            return;
                          }
                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Konfirmasi password tidak cocok.')),
                            );
                            return;
                          }
                          setState(() => _isChangingPass = true);
                          try {
                            await widget.api.changePassword(
                              username:  widget.profile?.username ?? '',
                              oldPassword: oldPass,
                              newPassword: newPass,
                              confirmPassword: confirmPass,
                            );
                            if (mounted) {
                              Navigator.of(context).pop();
                              Navigator.of(context).maybePop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Password berhasil diperbarui.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Gagal memperbarui password: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isChangingPass = false);
                            }
                          }
                        },
                  child: const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool obscure = true;
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Masukkan password untuk konfirmasi penghapusan akun. Tindakan ini tidak dapat dibatalkan.',
                  style: TextStyle(fontSize: 13.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setStateDialog(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _isDeletingAccount
                    ? null
                    : () async {
                        final pass = passwordCtrl.text.trim();
                        if (pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password wajib diisi untuk konfirmasi.')),
                          );
                          return;
                        }
                        Navigator.of(ctx).pop(); // tutup dialog input
                        setState(() => _isDeletingAccount = true);

                        try {
                          await widget.api.deleteAccount(
                            username: widget.profile?.username ?? '',
                            password: pass,
                          );

                          // Hapus session di client (opsional) lalu arahkan ke login
                          final request = Provider.of<CookieRequest>(context, listen: false);
                          try {
                            await request.logout('http://localhost:8000/authentication/logout/');
                          } catch (_) {}

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Akun berhasil dihapus.')),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const SmashLoginPage()),
                            (route) => false,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menghapus akun: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _isDeletingAccount = false);
                        }
                      },
                child: _isDeletingAccount
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Delete Account'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2F3E0),
      appBar: NavBar(
        isLoggedIn: true,
        username: widget.profile?.username ?? 'User',
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
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
              _changePasswordCTA(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isDeletingAccount ? null : _showDeleteAccountDialog,
                  child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
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
    if (_selectedBytes != null) {
      return Image.memory(
        _selectedBytes!,
        fit: BoxFit.cover,
        width: 86,
        height: 86,
      );
    }
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: 86,
        height: 86,
      );
    }
    final photo = widget.profile?.profilePhoto;
    if (photo != null && photo.isNotEmpty) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        width: 86,
        height: 86,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/avatar.png', fit: BoxFit.cover),
      );
    }
    return Container(
      width: 86,
      height: 86,
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 36, color: Colors.grey.shade600),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      try {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedBytes = bytes;
          _selectedImage = null;
          _removePhoto = false;
        });
      } catch (_) {
        setState(() {
          _selectedImage = File(picked.path);
          _selectedBytes = null;
          _removePhoto = false;
        });
      }
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
        profilePhoto: _selectedImage,
        profileBytes: _selectedBytes,
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

  Widget _changePasswordCTA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.lock_outline),
          label: const Text(
            'Change Password?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          onPressed: _isChangingPass ? null : _showChangePasswordDialog,
        ),
      ],
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
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              setState(() {
                _removePhoto = true;
                _selectedImage = null;
                _selectedBytes = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto profil akan dihapus saat disimpan')),
              );
            },
            tooltip: 'Hapus foto profil',
          ),
        ],
      ),
    );
  }
}

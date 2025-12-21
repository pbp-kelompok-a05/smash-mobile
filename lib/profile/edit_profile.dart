// ignore_for_file: depend_on_referenced_packages, unused_element, use_build_context_synchronously, dead_code, unnecessary_underscores

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smash_mobile/models/profile_entry.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isSaving = false;
  bool _isChangingPass = false;
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;
  File? _selectedImage;
  Uint8List? _selectedBytes;
  bool _removePhoto = false;
  String? _avatarUrl;
  static const _fallbackAvatar = 'https://raw.githubusercontent.com/identicons/rustcrate/master/public/images/default.png';

  String _resolvePhotoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return _fallbackAvatar;
    final resolved = widget.api.resolveMediaUrl(url);
    if (resolved == null || resolved.isEmpty) return _fallbackAvatar;
    final cacheBust = DateTime.now().millisecondsSinceEpoch;
    return '$resolved?v=$cacheBust';
  }

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.profile?.username ?? '';
    _bioController.text = widget.profile?.bio ?? '';
    _avatarUrl = _resolvePhotoUrl(widget.profile?.profilePhoto);
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
                  hintStyle: GoogleFonts.inter(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.white, width: 1.6),
                  ),
                );
            OutlineInputBorder focusBorder = const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.white, width: 1.6),
            );
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFF4A2B55),
              title: Text(
                'Change Password',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your current password, then set a new one.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: oldCtrl,
                    obscureText: obscureOld,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: dec('Old Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureOld ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                        onPressed: () => setStateDialog(
                            () => obscureOld = !obscureOld),
                      ),
                      focusedBorder: focusBorder,
                    ),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: dec('New Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureNew ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                        onPressed: () => setStateDialog(
                            () => obscureNew = !obscureNew),
                      ),
                      focusedBorder: focusBorder,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: dec('Confirm Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                            color: Colors.white70,
                          ),
                        onPressed: () => setStateDialog(
                            () => obscureConfirm = !obscureConfirm),
                      ),
                      focusedBorder: focusBorder,
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: BorderSide(color: Colors.white.withOpacity(0.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4A2B55),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
                              await _logoutToHome();
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
                  child: Text(
                    'Update Password',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
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
            backgroundColor: const Color(0xFF4A2B55),
            title: Text(
              'Delete Account',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your password to confirm account deletion. This action cannot be undone.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintStyle: GoogleFonts.inter(color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () => setStateDialog(() => obscure = !obscure),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white, width: 1.6),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4A2B55),
                ),
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
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Color(0xFF4A2B55),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Delete Account',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
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
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A2B55),
              Color(0xFF6A2B53),
              Color(0xFF9D50BB),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
            ];
          },
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 58,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _avatarPreview(size: 116),
                                Container(
                                  width: 116,
                                  height: 116,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 6,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 124,
                                  height: 124,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.profile?.username ?? 'User',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildGlassFormCard(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassFormCard() {
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Username'),
                const SizedBox(height: 8),
                _textField(
                  _usernameController,
                  hintText: 'Username cannot be blank',
                ),
                const SizedBox(height: 20),
                _label('Photo profile'),
                const SizedBox(height: 8),
                _uploadField(),
                const SizedBox(height: 20),
                _label('Bio'),
                const SizedBox(height: 8),
                _textField(
                  _bioController,
                  maxLines: 4,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                const SizedBox(height: 20),
                _changePasswordCTA(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600.withOpacity(0.7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed:
                        _isDeletingAccount ? null : _showDeleteAccountDialog,
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.white.withOpacity(0.6)),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4A2B55),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        onPressed: _isSaving ? null : _submit,
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4A2B55),
                                ),
                              )
                            : Text(
                                'Update',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPreview({double size = 86}) {
    if (_selectedBytes != null) {
      return Image.memory(
        _selectedBytes!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    }
    final photo = widget.profile?.profilePhoto;
    final url = (!_removePhoto && photo != null && photo.isNotEmpty)
        ? _avatarUrl ?? _resolvePhotoUrl(photo)
        : _fallbackAvatar;
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) {
        return Container(
          width: size,
          height: size,
          color: Colors.grey.shade200,
          child:
              Icon(Icons.person, size: size * 0.42, color: Colors.grey.shade600),
        );
      },
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
          _avatarUrl = null;
        });
      } catch (_) {
        setState(() {
          _selectedImage = File(picked.path);
          _selectedBytes = null;
          _removePhoto = false;
          _avatarUrl = null;
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
        _avatarUrl = _resolvePhotoUrl(updated.profilePhoto);
        _selectedBytes = null;
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

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    final request = context.read<CookieRequest>();
    try {
      await request.logout('http://localhost:8000/authentication/logout/');
    } catch (_) {}
    if (!mounted) return;
    _isLoggingOut = false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SmashLoginPage()),
      (route) => false,
    );
  }

  Future<void> _logoutToHome() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    final request = context.read<CookieRequest>();
    try {
      await request.logout('http://localhost:8000/authentication/logout/');
    } catch (_) {}
    if (!mounted) return;
    _isLoggingOut = false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyHomePage()),
      (route) => false,
    );
  }

  void _openProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  Widget _changePasswordCTA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            foregroundColor: const Color(0xFF4A2B55),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
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
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _textField(TextEditingController controller,
      {int maxLines = 1,
      EdgeInsetsGeometry? contentPadding,
      String? emptyError,
      String? hintText}) {
    const accent = Colors.white;
    return Focus(
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          contentPadding:
              contentPadding ?? const EdgeInsets.symmetric(horizontal: 12),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.white54),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accent, width: 1.6),
          ),
          errorText: null,
        ),
        cursorColor: Colors.white,
        onChanged: (v) {
          if (emptyError != null && v.trim().isEmpty) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _uploadField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withOpacity(0.15),
            ),
            child: IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.file_upload_outlined, size: 20, color: Colors.white),
              tooltip: 'Pilih foto',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedImage != null
                  ? _selectedImage!.path.split(Platform.pathSeparator).last
                  : 'Upload photo',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.delete,
                  color: Colors.red.shade500,
                  size: 20,
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                _removePhoto = true;
                _selectedImage = null;
                _selectedBytes = null;
                _avatarUrl = _fallbackAvatar;
              });
            },
            tooltip: 'Hapus foto profil',
          ),
        ],
      ),
    );
  }
}

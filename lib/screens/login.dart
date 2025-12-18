// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const SmashApp());
}

class SmashApp extends StatelessWidget {
  const SmashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smash Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const SmashLoginPage(),
    );
  }
}

/// Halaman login dengan background gradient modern dan glassmorphism card
class SmashLoginPage extends StatelessWidget {
  const SmashLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background gradient modern: ungu ke biru muda
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _LogoSection(),
                const SizedBox(height: 32),
                const _GlassLoginCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo section (VERSI ASLI - DIPERTAHANKAN)
class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Smash!',
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white, // Warna putih agar kontras
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2C6D9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports_tennis,
                size: 26,
                color: Color(0xFF6A2B53),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Forum Diskusi Olahraga Padel\nPERTAMA di Indonesia',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Glassmorphism login card dengan efek blur kaca
class _GlassLoginCard extends StatelessWidget {
  const _GlassLoginCard();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Container(
      width: width * 0.92,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // Transparan 15%
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: _SignInForm(),
          ),
        ),
      ),
    );
  }
}

/// Form sign in dengan validasi
class _SignInForm extends StatefulWidget {
  const _SignInForm();

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;

  static const String _baseUrl = 'http://localhost:8000';
  static const String _loginPath = '/authentication/login/';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Sign In to your account',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Username field
          Text(
            'Username',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _usernameCtrl,
            hint: 'Enter your username',
            icon: Icons.person_outline,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter username';
              if (v.length < 3) return 'Username must be at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Password field
          Text(
            'Password',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passCtrl,
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white70,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Sign in button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
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
                    'Sign In',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          
          // Register link
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
                TextButton(
                  onPressed: () {
                    // FIX: Navigasi ke halaman register yang baru
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SmashRegisterPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Create account',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget reusable untuk text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        suffixIcon: suffixIcon,
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isSubmitting = true);
    
    final request = context.read<CookieRequest>();
    final username = _usernameCtrl.text.trim();
    final password = _passCtrl.text.trim();

    try {
      final response = await request.login(_baseUrl + _loginPath, {
        'username': username,
        'password': password,
      });

      if (!mounted) return;

      final success =
          (response is Map && response['status'] == true) || response == true;

      if (success) {
        // Navigasi ke homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MyHomePage()),
        );
      } else {
        final message = (response is Map && response['message'] != null)
            ? response['message'].toString()
            : 'Login gagal, periksa username dan password.';
        _showError(message);
      }
    } catch (e) {
      if (mounted) {
        _showError('Login gagal: pastikan backend berjalan di $_baseUrl$_loginPath\n$e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
}
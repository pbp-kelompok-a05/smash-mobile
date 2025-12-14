// ignore_for_file: unused_element_parameter

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/screens/login.dart';

void main() {
  runApp(const SmashApp());
}

class SmashApp extends StatelessWidget {
  const SmashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smash Auth',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      debugShowCheckedModeBanner: false,
      home: const SmashLoginPage(),
    );
  }
}

/* ---------------------------
   Shared Logo / Header
   --------------------------- */
class SmashHeader extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final double logoSize;
  const SmashHeader({super.key, this.padding, this.logoSize = 48});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 18.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Smash!',
                style: TextStyle(
                  fontSize: logoSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A2B55),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: logoSize * 0.92,
                height: logoSize * 0.92,
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
        ],
      ),
    );
  }
}

/* ---------------------------
   Register Page
   --------------------------- */
class SmashRegisterPage extends StatelessWidget {
  const SmashRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFDFF7EE),
              Color(0xFFF7E7E9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const SmashHeader(padding: EdgeInsets.only(top: 12, bottom: 6), logoSize: 56),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    width: width * 0.92,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const _RegisterForm(),
                  ),
                ),
                const SizedBox(height: 10),
                // tagline below card (mirrors the screenshot)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Text(
                    'Forum Diskusi Olahraga Padel\nPERTAMA di Indonesia',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({super.key});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscureA = true;
  bool _obscureB = true;
  bool _isSubmitting = false;

  static const String _baseUrl = 'http://localhost:8000';
  static const String _registerPath = '/authentication/register/';

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: Colors.grey.shade500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showSideImage = width > 900;

    Widget formCard = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create your account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Join SMASH! today.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Username', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _userCtrl,
            decoration: _dec('Choose a username'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter username';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _fieldLabel('Email (Optional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            decoration: _dec('Enter your email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _fieldLabel('Password', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passCtrl,
            decoration: _dec('Enter a password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscureA ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureA = !_obscureA),
              ),
            ),
            obscureText: _obscureA,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              if (v.length < 6) return 'Password must be at least 6 chars';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _fieldLabel('Confirm Password', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pass2Ctrl,
            decoration: _dec('Confirm your password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscureB ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureB = !_obscureB),
              ),
            ),
            obscureText: _obscureB,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm password';
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create account', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already have an account? ',
                  style: TextStyle(color: Colors.grey.shade700)),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SmashLoginPage()),
                  );
                },
                child:
                    const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 10,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: formCard,
          ),
        ),
        if (showSideImage) const SizedBox(width: 20),
        if (showSideImage)
          Expanded(
            flex: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1544379370-59dab029d803?auto=format&fit=crop&w=1200&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.45)),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Join the SMASH Community',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Connect with padel enthusiasts,\nshare experiences, and find partners.',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    final request = context.read<CookieRequest>();
    try {
      final response = await request.postJson(
        '$_baseUrl$_registerPath',
        jsonEncode({
          'username': _userCtrl.text.trim(),
          'password1': _passCtrl.text,
          'password2': _pass2Ctrl.text,
        }),
      );
      if (!mounted) return;
      final isSuccess =
          (response is Map && (response['status'] == true || response['status'] == 'success'));
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil, silakan login.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SmashLoginPage()),
        );
      } else {
        final message = (response is Map && response['message'] != null)
            ? response['message'].toString()
            : 'Registrasi gagal, coba lagi.';
        _showError(message);
      }
    } catch (e) {
      if (mounted) _showError('Registrasi gagal: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (required)
            TextSpan(
              text: '*',
              style: TextStyle(color: Colors.red.shade700),
            ),
        ],
      ),
    );
  }
}

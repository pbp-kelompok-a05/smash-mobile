// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
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

class _SignInForm extends StatefulWidget {
  const _SignInForm({super.key});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Center(
            child: Text(
              'Sign In to your account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Welcome back to SMASH!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(
                  text: 'Username',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: '*', style: TextStyle(color: Colors.red.shade700)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Enter your email'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(
                  text: 'Password',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: '*', style: TextStyle(color: Colors.red.shade700)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: _dec('Enter your password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              if (v.length < 6) return 'Password must be at least 6 chars';
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signing in...')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: const Text('Sign In', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade700)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SmashRegisterPage()),
                  );
                },
                child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.w600)),
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
      // same background as login
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
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscureA = true;
  bool _obscureB = true;

  @override
  void dispose() {
    _userCtrl.dispose();
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Center(
            child: Text(
              'Create a New Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Start your winning journey with SMASH!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Username', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: '*', style: TextStyle(color: Colors.red.shade700)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userCtrl,
            decoration: _dec('Enter your email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Password', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: '*', style: TextStyle(color: Colors.red.shade700)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            decoration: _dec('Enter your password').copyWith(
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
          // second password field (the screenshot shows two Password labels — we treat second as repeat/confirm)
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Password', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: '*', style: TextStyle(color: Colors.red.shade700)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pass2Ctrl,
            decoration: _dec('Enter your password').copyWith(
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
          const SizedBox(height: 12),
          // Confirm Password (explicit label shown in screenshot)
          Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Confirm Password', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: '*', style: TextStyle(color: Colors.red.shade700)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          // For UX we reuse pass2 controller (the screenshot had 3 password fields; to be safe, keep this as a check)
          TextFormField(
            decoration: _dec('Enter your password'),
            obscureText: true,
            validator: (v) {
              // optional: check that this matches previous confirm
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  // simulate register action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registering account...')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: const Text('Register', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text('Already have an account? ', style: TextStyle(color: Colors.grey.shade700)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

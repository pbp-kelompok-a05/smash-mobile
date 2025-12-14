import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/screens/register.dart';

void main() {
  runApp(const SmashApp());
}

class SmashApp extends StatelessWidget {
  const SmashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smash Login',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      debugShowCheckedModeBanner: false,
      home: const SmashLoginPage(),
    );
  }
}

class SmashLoginPage extends StatelessWidget {
  const SmashLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      // background gradient dari hijau pucat ke pink pucat
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDFF7EE), // mint very light
              Color(0xFFF7E7E9), // pink very light
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo + tagline
                const _LogoSection(),
                const SizedBox(height: 24),
                // Card form
                Center(
                  child: Container(
                    width: width * 0.92,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const _SignInForm(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo (bisa diganti dengan Image.asset jika Anda punya asset logo)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // tulisan Smash!
            Text(
              'Smash!',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4A2B55), // deep purple
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            // Balloon / icon sebagai dekorasi logo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2C6D9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports_tennis, // mendekati bola padel
                size: 26,
                color: Color(0xFF6A2B53),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            '“Forum Diskusi Olahraga Padel\nPERTAMA di Indonesia”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm();

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;

  static const String _baseUrl = 'http://localhost:8000';
  static const String _loginPath = '/authentication/login/';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
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
        // isi card
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Sign In to your account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Welcome back to SMASH!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Username label + field
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Username',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Enter your username'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter username';
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Password label + field
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: _inputDecoration('Enter your password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              return null;
            },
          ),
          const SizedBox(height: 18),
          // Sign in button (pill black)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
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
                  : const Text(
                      'Sign In',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          // bottom text "Don't have an account? Create account"
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                TextButton(
                  onPressed: () {                    
                    Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SmashRegisterPage()),
                          );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Create account',
                    style: TextStyle(
                      color: Color(0xFF3E98D6), // biru muda link
                      fontWeight: FontWeight.w600,
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    final request = context.read<CookieRequest>();
    final username = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    try {
      final response = await request.login('$_baseUrl$_loginPath', {
        'username': username,
        'password': password,
      });
      if (!mounted) return;
      final success =
          (response is Map && response['status'] == true) || response == true;
      if (success) {
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
        _showError(
            'Login gagal: pastikan backend berjalan di $_baseUrl$_loginPath\n$e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/notifications/notifications_api.dart';

class NotificationsPlaceholder extends StatefulWidget {
  const NotificationsPlaceholder({super.key});

  @override
  State<NotificationsPlaceholder> createState() =>
      _NotificationsPlaceholderState();
}

class _NotificationsPlaceholderState
    extends State<NotificationsPlaceholder> {
  late NotificationsApi _api;
  bool _loading = true;
  String? _error;
  int _count = 0;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _loggedIn = request.loggedIn;
    _api = NotificationsApi(request: request);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _count = list.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Login required to view notifications.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text(_error!)
                : Text('Notifications loaded: $_count (UI coming soon)'),
      ),
    );
  }
}

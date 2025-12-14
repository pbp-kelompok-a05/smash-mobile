import 'dart:convert';

import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:smash_mobile/post/post_api.dart';

class NotificationsApi {
  NotificationsApi({required this.request, String? baseUrl})
      : baseUrl = baseUrl ?? 'http://localhost:8000';

  final CookieRequest request;
  final String baseUrl;

  static const String _defaultAvatarPath = '/static/images/user-profile.png';
  String get defaultAvatar => '$baseUrl$_defaultAvatarPath';

  Future<List<NotificationItem>> fetchNotifications() async {
    final endpoints = [
      '$baseUrl/notifications/api/',
      '$baseUrl/notifications/api',
      '$baseUrl/post/api/notifications/',
      '$baseUrl/post/api/notifications',
    ];

    dynamic lastError;
    for (final path in endpoints) {
      final uri = Uri.parse(path);
      try {
        final response = await _safeGet(uri);
        if (response is Map<String, dynamic> &&
            response['status'] == 'success') {
          final list = response['notifications'] as List<dynamic>? ?? [];
          return list
              .map(
                (item) => NotificationItem.fromJson(
                  Map<String, dynamic>.from(item as Map),
                  resolveMediaUrl: _resolveMediaUrl,
                  defaultAvatarUrl: '$baseUrl$_defaultAvatarPath',
                ),
              )
              .toList();
        }
        lastError = response;
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('INVALID_RESPONSE: $lastError');
  }

  Future<dynamic> _safeGet(Uri uri) async {
    try {
      final res = await request.get(uri.toString());
      if (res is String) {
        try {
          return jsonDecode(res);
        } catch (_) {
          return res;
        }
      }
      return res;
    } on FormatException {
      throw Exception('INVALID_RESPONSE');
    }
  }

  String? _resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('/')) return '$baseUrl$trimmed';
    return '$baseUrl/$trimmed';
  }
}

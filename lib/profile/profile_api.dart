import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as http_browser;
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/models/profile_entry.dart';

class ProfileApi {
  ProfileApi({required this.request, String? baseUrl})
      : baseUrl = baseUrl ?? _defaultBaseUrl;

  final CookieRequest request;
  final String baseUrl;

  static const String _defaultBaseUrl = 'http://localhost:8000';

  String get defaultAvatarUrl => '$baseUrl/static/images/user-profile.png';

  Future<ProfileData> fetchProfile({int? userId}) async {
    final uri = Uri.parse(
      userId == null
          ? '$baseUrl/profil/api/profile/'
          : '$baseUrl/profil/api/profile/$userId/',
    );
    final response = await _safeGet(uri);
    if (response is Map<String, dynamic>) {
      final status = response['status'] == true;
      if (status && response['data'] != null) {
        return ProfileData.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        );
      }
      throw Exception(response['message'] ?? 'Gagal memuat profil.');
    }
    throw Exception('Respon tidak valid saat memuat profil: $response');
  }

  Future<FilteringEntry> fetchProfilePosts({
    String filter = 'my',
    int page = 1,
    int perPage = 10,
    int? userId,
  }) async {
    final query = <String, String>{
      'filter': filter,
      'page': '$page',
      'per_page': '$perPage',
      if (userId != null) 'user_id': '$userId',
    };

    final candidates = [
      // Prefer the new dash-separated API first (matches Django route: api/profile-posts/)
      '$baseUrl/profil/api/profile-posts/',
      '$baseUrl/profil/api/profile-posts',
      '$baseUrl/profil/profile_posts_api/',
      '$baseUrl/profil/profile_posts_api',
      '$baseUrl/profil/api/posts/',
      '$baseUrl/profil/api/posts',
      '$baseUrl/profile/profile_posts_api/',
      '$baseUrl/profile/profile_posts_api',
      '$baseUrl/profile/api/posts/',
      '$baseUrl/profile/api/posts',
      '$baseUrl/profile/api/profile-posts/',
      '$baseUrl/profile/api/profile-posts',
      '$baseUrl/api/profile/posts/',
      '$baseUrl/api/profile/posts',
      '$baseUrl/api/profile/profile-posts/',
      '$baseUrl/api/profile/profile-posts',
    ];

    dynamic lastError;
    for (final path in candidates) {
      final uri = Uri.parse(path).replace(queryParameters: query);
      try {
        final response = await _safeGet(uri);
        if (response is Map<String, dynamic>) {
          if (response.containsKey('raw_html')) {
            lastError = 'HTML response from $path';
            continue;
          }
          final status = (response['status'] ?? '').toString().toLowerCase();
          if (status == 'success') {
            return FilteringEntry.fromJson(
              Map<String, dynamic>.from(response),
            );
          }
          lastError = response['message'] ?? response;
          continue;
        }
        lastError = response;
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Gagal memuat postingan: $lastError');
  }

  Future<dynamic> _safeGet(Uri uri) async {
    try {
      final res = await request.get(uri.toString());
      if (res is String) {
        final trimmed = res.trimLeft();
        if (trimmed.startsWith('<')) {
          return {'raw_html': trimmed, 'uri': uri.toString()};
        }
        try {
          return jsonDecode(res);
        } catch (_) {
          return {'raw': res};
        }
      }
      return res;
    } on FormatException catch (e) {
      throw Exception('Respon tidak valid dari server: $e');
    }
  }

  Future<ProfileData> updateProfile({
    String? username,
    String? bio,
    File? profilePhoto,
    bool removePhoto = false,
    Uint8List? profileBytes,
    String? profileFileName,
  }) async {
    final url = '$baseUrl/profil/api/profile/';
    final Map<String, String> fields = {
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      'remove_photo': removePhoto.toString(),
    };

    dynamic response;
    final hasPhoto = profileBytes != null || profilePhoto != null;
    if (hasPhoto) {
      final req = http.MultipartRequest('POST', Uri.parse(url));
      // copy cookies / csrf headers from CookieRequest
      final headers = Map<String, String>.from(request.headers);
      // Ensure cookies are attached (BrowserClient will send same-origin cookies)
      if (!kIsWeb) {
        final cookieHeader = request.cookies.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');
        if (cookieHeader.isNotEmpty) {
          headers['Cookie'] = cookieHeader;
        }
      }
      final csrfToken = (request.headers['X-CSRFToken'] ??
              request.cookies['csrftoken']?.toString() ??
              request.cookies['csrf']?.toString() ??
              '')
          .toString();
      if (csrfToken.isNotEmpty) {
        headers['X-CSRFToken'] = csrfToken;
      }
      headers.putIfAbsent('Referer', () => baseUrl);
      req.headers.addAll(headers);
      fields.forEach((k, v) => req.fields[k] = v);
      if (profileBytes != null) {
        req.files.add(http.MultipartFile.fromBytes(
          'profile_photo',
          profileBytes,
          filename: profileFileName ?? 'avatar.jpg',
        ));
      } else if (profilePhoto != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'profile_photo',
          profilePhoto.path,
          filename: profileFileName ?? 'avatar.jpg',
        ));
      }
      late http.Client client;
      if (kIsWeb) {
        final c = http_browser.BrowserClient()..withCredentials = true;
        client = c;
      } else {
        client = http.Client();
      }
      try {
        final streamed = await client.send(req);
        final body = await streamed.stream.bytesToString();
        response = jsonDecode(body);
        if (streamed.statusCode == 401) {
          throw Exception('Authentication required.');
        }
      } finally {
        client.close();
      }
    } else {
      response = await request.post(url, fields);
    }

    if (response is Map<String, dynamic>) {
      final ok = response['status'] == true;
      if (ok && response['data'] != null) {
        return ProfileData.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        );
      }
      throw Exception(response['message'] ?? 'Gagal memperbarui profil.');
    }
    throw Exception('Respon tidak valid saat memperbarui profil.');
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = '$baseUrl/profil/api/change-password/';
    final response = await request.post(url, {
      'old_password': oldPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
    if (response is Map<String, dynamic>) {
      final ok = response['status'] == true;
      if (!ok) {
        throw Exception(response['message'] ?? 'Gagal mengubah password.');
      }
      return;
    }
    throw Exception('Respon tidak valid saat mengubah password.');
  }

  /// Melengkapi URL media relatif agar menjadi absolut ke server Django.
  String? resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('/')) return '$baseUrl$trimmed';
    return '$baseUrl/$trimmed';
  }
}

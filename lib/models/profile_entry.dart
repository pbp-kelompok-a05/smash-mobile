import 'dart:convert';

ProfileResponse profileFromJson(String str) =>
    ProfileResponse.fromJson(json.decode(str));

String profileToJson(ProfileResponse data) => json.encode(data.toJson());

class ProfileResponse {
  final bool status;
  final String? message;
  final ProfileData data;

  ProfileResponse({
    required this.status,
    required this.data,
    this.message,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      ProfileResponse(
        status: json['status'] == true,
        data: ProfileData.fromJson(
            Map<String, dynamic>.from(json['data'] ?? {})),
        message: json['message'],
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data.toJson(),
      };
}

class ProfileData {
  final int id;
  final String username;
  final String bio;
  final String? profilePhoto;

  ProfileData({
    required this.id,
    required this.username,
    required this.bio,
    this.profilePhoto,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        id: json['id'] ?? 0,
        username: (json['username'] ?? '').toString(),
        bio: (json['bio'] ?? '').toString(),
        profilePhoto: json['profile_photo'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'bio': bio,
        'profile_photo': profilePhoto,
      };
}

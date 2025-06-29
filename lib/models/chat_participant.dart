// lib/models/chat_participant.dart
class ChatParticipant {
  final String id;
  final String roomId;
  final String userId;
  final DateTime joinedAt;
  final UserProfile? profile;

  ChatParticipant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.joinedAt,
    this.profile,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      userId: json['user_id'] ?? '',
      joinedAt: DateTime.parse(json['joined_at'] ?? DateTime.now().toIso8601String()),
      profile: json['profiles'] != null 
          ? UserProfile.fromJson(json['profiles'])
          : null,
    );
  }
}

class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? email;

  UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'email': email,
    };
  }
  }

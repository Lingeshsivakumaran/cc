class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ChatRoom {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatParticipant> participants;
  final Message? lastMessage;

  ChatRoom({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      participants: (json['participants'] as List)
          .map((p) => ChatParticipant.fromJson(p))
          .toList(),
      lastMessage: json['last_message'] != null && (json['last_message'] as List).isNotEmpty
          ? Message.fromJson(json['last_message'][0])
          : null,
    );
  }

  String getOtherParticipantName(String currentUserId) {
    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.profile?.fullName ?? 'Unknown User';
  }

  String? getOtherParticipantAvatar(String currentUserId) {
    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.profile?.avatarUrl;
  }
}

class ChatParticipant {
  final String userId;
  final UserProfile? profile;

  ChatParticipant({
    required this.userId,
    this.profile,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['user_id'],
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
      id: json['id'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      email: json['email'],
    );
  }
}
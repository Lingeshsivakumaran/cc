import 'message.dart';

class ChatRoom {
  final String id;
  final List<ChatParticipant> participants;
  final Message? lastMessage;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
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
      (participant) => participant.id != currentUserId,
      orElse: () => ChatParticipant(id: '', name: 'Unknown'),
    );
    return otherParticipant.name;
  }

  String? getOtherParticipantAvatar(String currentUserId) {
    final otherParticipant = participants.firstWhere(
      (participant) => participant.id != currentUserId,
      orElse: () => ChatParticipant(id: '', name: 'Unknown'),
    );
    return otherParticipant.avatarUrl;
  }
}

class ChatParticipant {
  final String id;
  final String name;
  final String? avatarUrl;

  ChatParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
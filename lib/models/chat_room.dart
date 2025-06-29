// In lib/models/chat_room.dart
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
      lastMessage: json['last_message'] != null && 
                   (json['last_message'] as List).isNotEmpty
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
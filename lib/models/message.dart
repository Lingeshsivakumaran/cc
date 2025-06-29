// lib/models/message.dart
class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
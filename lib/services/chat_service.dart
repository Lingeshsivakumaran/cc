// lib/services/chat_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/chat_participant.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all chat rooms for current user
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('chat_rooms')
          .select('''
            id,
            created_at,
            updated_at,
            participants:chat_participants(
              id,
              user_id,
              room_id,
              joined_at,
              profiles(id, full_name, avatar_url, email)
            ),
            last_message:messages(
              id,
              content,
              created_at,
              sender_id
            )
          ''')
          .eq('chat_participants.user_id', currentUserId)
          .order('updated_at', ascending: false)
          .limit(1, referencedTable: 'messages');

      return response.map<ChatRoom>((json) => ChatRoom.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching chat rooms: $e');
      return [];
    }
  }

  // Get messages for a specific room
  Stream<List<Message>> getMessages(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  // Send a message
  Future<bool> sendMessage(String roomId, String content) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      await _supabase.from('messages').insert({
        'room_id': roomId,
        'sender_id': currentUserId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update room's updated_at timestamp
      await _supabase
          .from('chat_rooms')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', roomId);

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get all users (excluding current user)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url, email')
          .neq('id', currentUserId)
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Create or get existing chat room
  Future<String?> createOrGetChatRoom(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      // Check if chat room already exists between these two users
      final existingRooms = await _supabase
          .from('chat_participants')
          .select('room_id, user_id')
          .in('user_id', [currentUserId, otherUserId]);

      if (existingRooms.isNotEmpty) {
        // Group by room_id and count participants
        final roomCounts = <String, int>{};
        for (final room in existingRooms) {
          final roomId = room['room_id'] as String;
          roomCounts[roomId] = (roomCounts[roomId] ?? 0) + 1;
        }

        // Find a room with exactly 2 participants (both users)
        final existingRoomId = roomCounts.entries
            .where((entry) => entry.value == 2)
            .map((entry) => entry.key)
            .firstOrNull;

        if (existingRoomId != null) {
          return existingRoomId;
        }
      }

      // Create new chat room
      final roomResponse = await _supabase
          .from('chat_rooms')
          .insert({
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final roomId = roomResponse['id'];

      // Add participants
      await _supabase.from('chat_participants').insert([
        {'room_id': roomId, 'user_id': currentUserId, 'joined_at': DateTime.now().toIso8601String()},
        {'room_id': roomId, 'user_id': otherUserId, 'joined_at': DateTime.now().toIso8601String()},
      ]);

      return roomId;
    } catch (e) {
      print('Error creating chat room: $e');
      return null;
    }
  }
}
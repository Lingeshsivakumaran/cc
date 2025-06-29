import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/message.dart';
import '../models/chat_room.dart' as chat_room_model;

class ChatService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all chat rooms for current user
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('chat_rooms')
          .select('''
            *,
            participants:chat_participants(
              user_id,
              profiles:profiles(id, full_name, avatar_url)
            ),
            last_message:messages(content, created_at, sender_id)
          ''')
          .eq('chat_participants.user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List<Map<String, dynamic>>).map((data) => chat_room_model.ChatRoom.fromJson(data)).toList();
    } catch (e) {
      print('Error getting chat rooms: $e');
      return [];
    }
  }

  // Create or get existing chat room
  Future<String?> createOrGetChatRoom(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      // Check if chat room already exists
      final existingRoom = await _supabase
          .from('chat_participants')
          .select('room_id')
          .contains('user_id', [currentUserId, otherUserId])
          .then((response) {
            final groupedRooms = (response as List<dynamic>)
                .where((room) => room['user_id'].length == 2)
                .toList();
            return groupedRooms.isNotEmpty ? groupedRooms.first : null;
          })
          .then((response) => response.isNotEmpty ? response.first : null);

      if (existingRoom != null) {
        return existingRoom['room_id'];
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
        {'room_id': roomId, 'user_id': currentUserId},
        {'room_id': roomId, 'user_id': otherUserId},
      ]);

      return roomId;
    } catch (e) {
      print('Error creating chat room: $e');
      return null;
    }
  }

  // Get messages for a chat room
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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('messages').insert({
        'room_id': roomId,
        'sender_id': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update chat room's last activity
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

  // Get all users (for starting new chats)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url, email')
          .neq('id', currentUserId);

      return response;
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }
}
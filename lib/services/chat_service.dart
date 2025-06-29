import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/chat_participant.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fixed getChatRooms method
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      // First get room IDs where current user is a participant
      final participantRooms = await _supabase
          .from('chat_participants')
          .select('room_id')
          .eq('user_id', currentUserId);

      if (participantRooms.isEmpty) return [];

      final roomIds = participantRooms.map((p) => p['room_id']).toList();

      // Then get room details with participants and last message
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
          .inFilter('id', roomIds)
          .order('updated_at', ascending: false);

      return response.map<ChatRoom>((json) {
        // Fix last_message handling
        if (json['last_message'] != null && json['last_message'].isNotEmpty) {
          // Sort messages by created_at and get the latest
          final messages = json['last_message'] as List;
          messages.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
          json['last_message'] = [messages.first];
        }
        return ChatRoom.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error fetching chat rooms: $e');
      return [];
    }
  }

  // Fix message streaming
  Stream<List<Message>> getMessages(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList())
        .handleError((error) {
          print('Error streaming messages: $error');
          return <Message>[];
        });
  }

  // Rest of the methods remain the same...
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

  Future<String?> createOrGetChatRoom(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      // Check if chat room already exists
      final existingRooms = await _supabase
          .from('chat_participants')
          .select('room_id')
          .inFilter('user_id', [currentUserId, otherUserId]);

      if (existingRooms.isNotEmpty) {
        // Check each room to see if it contains both users
        for (final room in existingRooms) {
          final roomId = room['room_id'];
          final participants = await _supabase
              .from('chat_participants')
              .select('user_id')
              .eq('room_id', roomId);
          
          final userIds = participants.map((p) => p['user_id']).toSet();
          if (userIds.contains(currentUserId) && userIds.contains(otherUserId) && userIds.length == 2) {
            return roomId;
          }
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
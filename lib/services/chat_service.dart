Future<String?> createOrGetChatRoom(String otherUserId) async {
  try {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    // Check if chat room already exists between these two users
    final existingRooms = await _supabase
        .from('chat_participants')
        .select('room_id, user_id')
        .in_('user_id', [currentUserId, otherUserId]);

    if (existingRooms.isNotEmpty) {
      // Group by room_id and count participants
      final roomCounts = <String, int>{};
      for (final room in existingRooms) {
        final roomId = room['room_id'] as String;
        roomCounts[roomId] = (roomCounts[roomId] ?? 0) + 1;
      }

      // Find a room with exactly 2 participants (both users)
      final existingRoomId = roomCounts.entries
          .firstWhere(
            (entry) => entry.value == 2,
            orElse: () => null,
          )
          ?.key;

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
      {'room_id': roomId, 'user_id': currentUserId},
      {'room_id': roomId, 'user_id': otherUserId},
    ]);

    return roomId;
  } catch (e) {
    print('Error creating chat room: $e');
    return null;
  }
}

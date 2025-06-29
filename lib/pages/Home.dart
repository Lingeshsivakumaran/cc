import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/chat_room.dart';
import 'chat_page.dart';
import 'new_chat_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  List<ChatRoom> _allChatRooms = [];
  List<ChatRoom> _filteredChatRooms = [];

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    _searchController.addListener(_filterChatRooms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    final chatRooms = await _chatService.getChatRooms();
    setState(() {
      _allChatRooms = chatRooms.cast<ChatRoom>();
      _filteredChatRooms = chatRooms.cast<ChatRoom>();
    });
  }

  void _filterChatRooms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChatRooms = _allChatRooms.where((room) {
        final participantName = room.getOtherParticipantName(
          _authService.currentUser?.id ?? ''
        ).toLowerCase();
        return participantName.contains(query);
      }).toList();
    });
  }

  void _navigateToChat(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          roomId: chatRoom.id,
          chatTitle: chatRoom.getOtherParticipantName(
            _authService.currentUser?.id ?? ''
          ),
        ),
      ),
    ).then((_) => _loadChatRooms());
  }

  void _navigateToNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewChatPage()),
    ).then((_) => _loadChatRooms());
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    
    if (difference == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Top row with profile and new chat icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _signOut,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: user?.userMetadata?['avatar_url'] != null
                            ? NetworkImage(user!.userMetadata!['avatar_url'])
                            : null,
                        child: user?.userMetadata?['avatar_url'] == null
                            ? Text(
                                user?.userMetadata?['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.logout, size: 20, color: Colors.red),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _navigateToNewChat,
                  child: const Icon(Icons.add_comment, size: 30, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Welcome text
            Row(
              children: [
                const Text(
                  "Welcome to",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  "ChatApp",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Greeting with user name
            Row(
              children: [
                Image.asset(
                  "images/wave.png",
                  width: 50, 
                  height: 90, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.waving_hand, size: 50, color: Colors.orange);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Hello, ${user?.userMetadata?['full_name'] ?? 'User'}!",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Chat list container
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.amberAccent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30.0),
                    
                    // Search bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          hintText: "Search chats",
                          contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Chat list
                    Expanded(
                      child: _filteredChatRooms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _allChatRooms.isEmpty 
                                        ? "No chats yet\nTap + to start a new conversation"
                                        : "No chats found",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              itemCount: _filteredChatRooms.length,
                              itemBuilder: (context, index) {
                                final chatRoom = _filteredChatRooms[index];
                                final currentUserId = _authService.currentUser?.id ?? '';
                                final participantName = chatRoom.getOtherParticipantName(currentUserId);
                                final participantAvatar = chatRoom.getOtherParticipantAvatar(currentUserId);
                                
                                return GestureDetector(
                                  onTap: () => _navigateToChat(chatRoom),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(25),
                                          child: participantAvatar != null
                                              ? Image.network(
                                                  participantAvatar,
                                                  height: 50,
                                                  width: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      height: 50,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                        color: Colors.deepPurple,
                                                        borderRadius: BorderRadius.circular(25),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          participantName.substring(0, 1).toUpperCase(),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  height: 50,
                                                  width: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.deepPurple,
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      participantName.isNotEmpty 
                                                          ? participantName.substring(0, 1).toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                participantName,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                chatRoom.lastMessage?.content ?? "No messages yet",
                                                style: const TextStyle(
                                                  color: CupertinoColors.secondaryLabel,
                                                  fontSize: 14.0,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              chatRoom.lastMessage != null
                                                  ? _formatTime(chatRoom.lastMessage!.createdAt)
                                                  : _formatTime(chatRoom.createdAt),
                                              style: const TextStyle(
                                                color: CupertinoColors.secondaryLabel,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            const Icon(
                                              Icons.chevron_right,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sportsin/components/custom_toast.dart';
import 'package:sportsin/models/models.dart';
import 'package:sportsin/services/db/db_provider.dart';
import 'chat_details_screen.dart';

class ChatListItem {
  final ChatRoom room;
  final User otherUser;
  ChatListItem({required this.room, required this.otherUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatListItem>> _chatsFuture;
  final DbProvider _db = DbProvider.instance;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  List<UserSearchResult> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _chatsFuture = _initializeAndFetchChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    DbProvider.instance.disconnectFromChat();
    super.dispose();
  }

  Future<List<ChatListItem>> _initializeAndFetchChats() async {
    try {
      await DbProvider.instance.connectToChat();
      return _fetchChats();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChatListItem>> _fetchChats() async {
    final currentUser = _db.cashedUser;
    if (currentUser == null) throw Exception("User not logged in");

    final chatRooms = await _db.getChatRooms();

    final List<Future<ChatListItem?>> futureItems = chatRooms.map((room) async {
      final otherUserId =
          room.user1 == currentUser.id ? room.user2 : room.user1;
      final otherUser = await _db.getUserById(otherUserId);
      if (otherUser != null) {
        return ChatListItem(room: room, otherUser: otherUser);
      }
      return null;
    }).toList();

    final results = await Future.wait(futureItems);
    return results.where((item) => item != null).cast<ChatListItem>().toList();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final results = await DbProvider.instance.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      CustomToast.showError(message: 'Failed to search users.');
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(
          child: Text("No users found.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final searchResult = _searchResults[index];
        return _buildSearchResultTile(searchResult);
      },
    );
  }

  Widget _buildSearchResultTile(UserSearchResult result) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            try {
              final fullUser = await _db.getUserById(result.id);
              if (fullUser != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailsScreen(
                      roomId: '',
                      otherUser: fullUser,
                    ),
                  ),
                );
              }
            } catch (e) {
              CustomToast.showError(message: "Could not load user details.");
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: result.profilePicture != null
                      ? NetworkImage(result.profilePicture!)
                      : null,
                  radius: 28,
                  backgroundColor: const Color(0xFF3A3A3A),
                  child: result.profilePicture == null
                      ? const Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("@${result.username}",
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text('Inbox',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey[900],
              ),
            ),
          ),
          Expanded(
            child: _showSearchResults
                ? _buildSearchResults()
                : FutureBuilder<List<ChatListItem>>(
                    future: _chatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No conversations found.',
                                style: TextStyle(color: Colors.grey)));
                      }

                      final chatItems = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: chatItems.length,
                        itemBuilder: (context, index) {
                          final item = chatItems[index];
                          final otherUser = item.otherUser;
                          final room = item.room;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailsScreen(
                                        roomId: room.id,
                                        otherUser: otherUser,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage:
                                            otherUser.profilePicture != null
                                                ? NetworkImage(
                                                    otherUser.profilePicture!)
                                                : null,
                                        radius: 28,
                                        backgroundColor:
                                            const Color(0xFF3A3A3A),
                                        child: otherUser.profilePicture == null
                                            ? const Icon(Icons.person,
                                                color: Colors.white, size: 28)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              otherUser.name,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Last message...",
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey[300]),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

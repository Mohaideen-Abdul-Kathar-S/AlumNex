import 'dart:async';
import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Assumes you have a global like this somewhere
/// const String urI = "http://localhost:5000"; // your backend base URL

class AlumnexGroupChatPage extends StatefulWidget {
  final dynamic sender; // e.g., user id string
  final dynamic groupid; // group id string

  const AlumnexGroupChatPage({
    super.key,
    required this.sender,
    required this.groupid,
  });

  @override
  State<AlumnexGroupChatPage> createState() => _AlumnexGroupChatPageState();
}

class _AlumnexGroupChatPageState extends State<AlumnexGroupChatPage> {
  final Color primaryColor = const Color(0xFF1565C0);
  final Color accentColor = const Color(0xFFFF7043);
  final Color secondaryColor = const Color(0xFFEEEEEE);

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late Timer _pollTimer;
  bool _loading = false;
  bool _searchMode = false;
  bool _selectMode = false;

  /// Chat messages for the group
  List<ChatMessage> messages = [];

  /// Search results (when _searchMode == true)
  List<ChatMessage> searchResults = [];

  /// Selected message ids (for snapshot/bookmark actions)
  final Set<String> _selectedIds = <String>{};
String? snapshotTitle;
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadMessages(),
    );
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final fetched = await _fetchMessages();
      setState(() => messages = fetched);
      print("messages of fetch " + messages.toString());
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

Future<List<ChatMessage>> _fetchMessages() async {
  final uri = Uri.parse('$urI/get_group_messages/${widget.groupid}');
  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw Exception('Failed to load messages');
  }
  final List data = jsonDecode(resp.body) as List;
  return data.map((m) => ChatMessage.fromJson(m)).toList();
}


Future<Map<String, dynamic>> fetchSnapshot(String snapshotId) async {
  final uri = Uri.parse('$urI/snapshot/$snapshotId');
  final resp = await http.get(uri);

  if (resp.statusCode != 200) {
    throw Exception('Failed to load snapshot');
  }

  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  return data;
}

Future<void> loadSnapshot(String snapshotId) async {
  try {
    final snapData = await fetchSnapshot(snapshotId);

    final List msgsJson = snapData['messages'] as List;
    final snapshotMessages = msgsJson
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    setState(() {
      snapshotTitle = snapData['title'];
      messages = snapshotMessages; // reuse your chat list
    });

    print("Loaded snapshot ${snapData['title']} with ${messages.length} messages");
  } catch (e) {
    debugPrint("Error loading snapshot: $e");
  }
}



  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$urI/send_group_message');
      final payload = {
        'group_id': widget.groupid,
        'sender': widget.sender,
        'message': text,
      };
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200) {
        _messageController.clear();
        await _loadMessages();
      } else {
        _showSnack('Failed to send');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

Future<void> _search() async {
  final query = _searchController.text.trim();
  if (query.isEmpty) return;

  final url = Uri.parse("$urI/search?group_id=${widget.groupid}&q=$query");
  final res = await http.get(url);

  if (res.statusCode == 200) {
    final List<dynamic> data = jsonDecode(res.body);

    setState(() {
      // Convert each JSON map to ChatMessage
      searchResults = data.map((d) => ChatMessage.fromJson(d)).toList();
    });

    print("Search results: $searchResults");
  } else {
    print("Search failed: ${res.body}");
  }
}


  Future<void> _createSnapshot() async {
    if (_selectedIds.isEmpty) {
      _showSnack('Select at least one message');
      return;
    }
    final title = await _askText(
      context,
      title: 'Snapshot Title',
      initial: 'Snapshot',
    );
    if (title == null) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$urI/snapshot');
      final payload = {
        'group_id': widget.groupid,
        'user_id': widget.sender,
        'title': title,
        'message_ids': _selectedIds.toList(),
      };
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200) {
        _showSnack('Snapshot saved');
        setState(() => _selectedIds.clear());
      } else {
        _showSnack('Failed to save snapshot');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editMessage(ChatMessage msg) async {
    final newText = await _askText(
      context,
      title: 'Edit Message',
      initial: msg.text,
    );
    if (newText == null || newText.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      print("Editing message ID: ${msg.id}");

      final uri = Uri.parse('$urI/edit_message/${msg.id}');

      final payload = {'message': newText.trim(), 'editor': widget.sender};
      final resp = await http.put(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200) {
        _showSnack('Message updated');
        await _loadMessages();
      } else {
        _showSnack('Failed to update');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showVersions(ChatMessage msg) async {
    try {
      final uri = Uri.parse('$urI/message_versions/${msg.id}');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        _showSnack('Failed to load versions');
        return;
      }
      final List data = jsonDecode(resp.body) as List;
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (_) => DraggableScrollableSheet(
              expand: false,
              builder:
                  (_, controller) => Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ListView.builder(
                      controller: controller,
                      itemCount: data.length,
                      itemBuilder: (_, i) {
                        final v = data[i] as Map<String, dynamic>;
                        final content = v['content']?.toString() ?? '';
                        final version = v['version']?.toString() ?? '';
                        final editedAt = v['edited_at']?.toString() ?? '';
                        final editedBy = v['edited_by']?.toString() ?? '';
                        return Card(
                          child: ListTile(
                            title: Text('v$version'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(content),
                                const SizedBox(height: 6),
                                Text(
                                  'Edited by $editedBy at $editedAt',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ),
      );
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectMode = _selectedIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectMode = false;
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final list = _searchMode ? searchResults : messages;

    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title:
            _searchMode
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                )
                : const Text(
                  'Group Chat',
                  style: TextStyle(color: Colors.white),
                ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
  if (_searchMode) ...[
    IconButton(icon: const Icon(Icons.search), onPressed: _search),
    IconButton(
      icon: const Icon(Icons.close),
      onPressed: () {
        setState(() {
          _searchMode = false;
          _searchController.clear();
          searchResults = [];  // resets to empty list of ChatMessage
        });
      },
    ),
  ] else if (!_selectMode) ...[
    IconButton(
      icon: const Icon(Icons.collections_bookmark),
      tooltip: 'View Snapshots',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SnapshotsPage(groupId: widget.groupid),
          ),
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.search),
      tooltip: 'Search Messages',
      onPressed: () => setState(() => _searchMode = true),
    ),
  ] else ...[
    IconButton(
      icon: const Icon(Icons.bookmark_add_outlined),
      tooltip: 'Create Snapshot from selected',
      onPressed: _createSnapshot,
    ),
    IconButton(
      icon: const Icon(Icons.clear),
      tooltip: 'Clear selection',
      onPressed: _clearSelection,
    ),
  ],
],

      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final m = list[index];
                  return _buildMessageBubble(m);
                },
              ),
            ),
          ),
          if (!_searchMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : _sendMessage,
                    child: CircleAvatar(
                      backgroundColor: accentColor,
                      radius: 22,
                      child:
                          _loading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.sender == widget.sender;
    final selected = _selectedIds.contains(message.id);

    return GestureDetector(
      onLongPress: () => _toggleSelect(message.id),
      onTap: () {
        if (_selectMode) {
          _toggleSelect(message.id);
        }
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: isMe ? primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 14),
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? Colors.amber : Colors.grey).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: selected ? Border.all(color: Colors.amber, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  message.sender,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                message.text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  if (message.edited)
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: isMe ? Colors.white70 : Colors.black45,
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          if (isMe) _editMessage(message);
                          print("msg data" + message.toString());
                          break;
                        case 'versions':
                          _showVersions(message);
                          break;
                        case 'select':
                          _toggleSelect(message.id);
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          if (isMe)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                          const PopupMenuItem(
                            value: 'versions',
                            child: Text('View Versions'),
                          ),
                          const PopupMenuItem(
                            value: 'select',
                            child: Text('Select'),
                          ),
                        ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? ts) {
    if (ts == null) return '';
    final t = TimeOfDay.fromDateTime(ts.toLocal());
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }
}



class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final bool edited;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.edited,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '', // ✅ must read "id" (string from backend)
      text: json['message'] ?? '',
      sender: json['sender'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      edited: json['edited'] ?? false,
    );
  }
  @override
  String toString() {
    return 'ChatMessage{id: $id, text: $text, sender: $sender, timestamp: $timestamp, edited: $edited}';
  }
}

/// Simple helper dialog that returns entered text or null.
Future<String?> _askText(
  BuildContext context, {
  required String title,
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String?>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter text'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}


class SnapshotsPage extends StatefulWidget {
  final String groupId;   // 1️⃣ add a field

  const SnapshotsPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _SnapshotsPageState createState() => _SnapshotsPageState();
}

class _SnapshotsPageState extends State<SnapshotsPage> {
 List<Map<String, dynamic>> snapshots = [];
  List<dynamic> filtered = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSnapshots();
  }

Future<void> _fetchSnapshots() async {
  try {
    final uri = Uri.parse('$urI/snapshots/${widget.groupId}');
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
  final List<dynamic> data = jsonDecode(resp.body);

  setState(() {
    snapshots = data.cast<Map<String, dynamic>>();
    filtered = List<Map<String, dynamic>>.from(data);
  });
}
else {
      debugPrint("❌ Failed to load snapshots: ${resp.body}");
    }
  } catch (e) {
    debugPrint("⚠️ Error fetching snapshots: $e");
  }
}


  void _search(String query) {
    setState(() {
      filtered = snapshots
          .where((s) =>
              (s['title'] as String).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Search snapshots...",
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, i) {
          final snap = filtered[i];
          return ListTile(
            title: Text(snap['title']),
            subtitle: Text("Messages: ${snap['message_ids'].length}"),
            onTap: () {
              // Open snapshot messages
              Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SnapshotMessagesPage(snapshotId: snap['_id']),
  ),
);

            },
          );
        },
      ),
    );
  }
}

class SnapshotMessagesPage extends StatefulWidget {
  final String snapshotId;
  const SnapshotMessagesPage({Key? key, required this.snapshotId}) : super(key: key);

  @override
  State<SnapshotMessagesPage> createState() => _SnapshotMessagesPageState();
}

class _SnapshotMessagesPageState extends State<SnapshotMessagesPage> {
  List messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final uri = Uri.parse('$urI/snapshot/messages/${widget.snapshotId}');
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      setState(() {
        messages = data['messages'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Snapshot Messages")),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final msg = messages[i];
          return ListTile(
            title: Text(msg['message']),
            subtitle: Text("${msg['sender']} • ${msg['timestamp']}"),
          );
        },
      ),
    );
  }
}

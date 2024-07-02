import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_client/services/xmpp_service.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:chat_client/pages/login_screen.dart';
import 'package:chat_client/pages/user_settings_screen.dart';
import 'package:chat_client/models/user.dart';
import '../config.dart';
import '../providers/user_provider.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  ChatScreen({required this.user});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late XmppService _xmppService;
  List<Map<String, dynamic>> _messages = [];
  List<String> _users = [];
  String? _selectedUser;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _xmppService = Provider.of<UserProvider>(context, listen: false).xmppService;
    final user = Provider.of<UserProvider>(context, listen: false).user!;
    _xmppService.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });
    });
    _xmppService.usersStream.listen((users) {
      setState(() {
        _users = users.where((u) => u != user.username).toList();
      });
    });
  }

  void _sendMessage() {
    if (_selectedUser != null) {
      var message = _messageController.text;
      final user = Provider.of<UserProvider>(context, listen: false).user!;
      _xmppService.sendMessage(user, message, _selectedUser!);
      setState(() {
        _messages.add({
          'sender': 'Me',
          'displayName': user.displayName,
          'photoBase64': user.photoBase64,
          'message': message,
        });
      });
      _messageController.clear();
    }
  }

  void _logout() async {
    await Provider.of<UserProvider>(context, listen: false).clearCredentials();
    _xmppService.dispose();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _goToUserSettings() {
    final user = Provider.of<UserProvider>(context, listen: false).user!;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserSettingsScreen(user: user)),
    );
  }

  ImageProvider _base64ToImageProvider(String base64String) {
    if (base64String.isEmpty) return AssetImage('assets/placeholder.png');
    Uint8List bytes = base64Decode(base64String);
    return MemoryImage(bytes);
  }

  @override
  void dispose() {
    _xmppService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user!;
    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
        leading: user.photoBase64 != null && user.photoBase64!.isNotEmpty
            ? CircleAvatar(
          backgroundImage: _base64ToImageProvider(user.photoBase64!),
        )
            : CircleAvatar(
          child: Text(user.displayName.isNotEmpty ? user.displayName[0] : '?'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _goToUserSettings,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            hint: Text('Select User'),
            value: _selectedUser,
            onChanged: (newValue) {
              setState(() {
                _selectedUser = newValue;
              });
            },
            items: _users.map((user) {
              return DropdownMenuItem<String>(
                value: user,
                child: Text(user),
              );
            }).toList(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final messageData = _messages[index];
                return ListTile(
                  leading: messageData['photoBase64'] != null && messageData['photoBase64'].isNotEmpty
                      ? CircleAvatar(
                    backgroundImage: _base64ToImageProvider(messageData['photoBase64']),
                  )
                      : CircleAvatar(
                    child: Text(messageData['displayName'].isNotEmpty ? messageData['displayName'][0] : '?'),
                  ),
                  title: Text(messageData['displayName']),
                  subtitle: Text(messageData['message']),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: 'Message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

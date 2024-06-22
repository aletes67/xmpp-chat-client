import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chat_client/services/xmpp_service.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:chat_client/pages/login_screen.dart';
import 'package:chat_client/pages/user_settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String password;
  final String domain;
  final int port;

  ChatScreen({
    required this.username,
    required this.password,
    required this.domain,
    required this.port,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final XmppService _xmppService = XmppService();
  final AuthService _authService = AuthService();
  List<String> _messages = [];
  List<String> _users = [];
  String? _selectedUser;
  final TextEditingController _messageController = TextEditingController();
  String? _displayName;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _xmppService.connect(widget.username, widget.password, widget.domain, widget.port);
    _xmppService.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });
    });
    _xmppService.usersStream.listen((users) {
      setState(() {
        _users = users;
      });
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();
    setState(() {
      _displayName = profile['displayName'];
      _photoPath = profile['photoPath'];
    });
  }

  void _sendMessage() {
    if (_selectedUser != null) {
      var message = _messageController.text;
      _xmppService.sendMessage(message, _selectedUser!);
      setState(() {
        _messages.add('Me: $message');
      });
      _messageController.clear();
    }
  }

  void _logout() async {
    await _authService.clearCredentials();
    _xmppService.dispose();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  void dispose() {
    _xmppService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_photoPath != null)
              CircleAvatar(
                backgroundImage: FileImage(File(_photoPath!)),
                radius: 20,
              ),
            if (_displayName != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(_displayName!),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserSettingsScreen()),
              ).then((_) {
                _loadUserProfile(); // Reload the user profile after returning from settings
              });
            },
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
            items: _users.where((user) => user != widget.username).map((user) {
              return DropdownMenuItem<String>(
                value: user,
                child: Row(
                  children: [
                    if (_photoPath != null)
                      CircleAvatar(
                        backgroundImage: FileImage(File(_photoPath!)),
                        radius: 10,
                      ),
                    SizedBox(width: 8),
                    Text(user),
                  ],
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: _messages[index].startsWith('Me: ')
                      ? CircleAvatar(
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null ? Text('Me') : null,
                  )
                      : null,
                  title: Text(_messages[index]),
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

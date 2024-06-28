import 'package:flutter/material.dart';
import 'package:chat_client/services/xmpp_service.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:chat_client/pages/login_screen.dart';
import 'package:chat_client/pages/user_settings_screen.dart';
import 'package:chat_client/models/user.dart';
import '../config.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  ChatScreen({
    required this.user,
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

  @override
  void initState() {
    super.initState();
    final domain = Config.domain;
    final port = Config.port;

    _xmppService.connect(
      widget.user.username,
      widget.user.password,
      domain,
      port,
      widget.user.groupName,
    );
    _xmppService.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });
    });
    _xmppService.usersStream.listen((users) {
      setState(() {
        _users = users.where((user) => user != widget.user.username).toList(); // Rimuove l'utente corrente
      });
    });
  }

  void _sendMessage() {
    if (_selectedUser != null) {
      var message = _messageController.text;
      _xmppService.sendMessage(message, _selectedUser!); // Pass only the username, domain is handled in the service
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

  void _goToUserSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserSettingsScreen(user: widget.user)),
    );
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
        title: Text(widget.user.displayName),
        leading: widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty
            ? CircleAvatar(
          backgroundImage: NetworkImage(widget.user.photoUrl!),
        )
            : CircleAvatar(
          child: Text(widget.user.displayName.isNotEmpty ? widget.user.displayName[0] : '?'),
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
                return ListTile(
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

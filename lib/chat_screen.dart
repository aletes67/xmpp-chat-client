import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'dart:async';
import 'package:logging/logging.dart';

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
  late xmpp.Connection _connection;
  List<String> _messages = [];
  List<String> _users = [];
  String? _selectedUser;
  final _messageController = TextEditingController();
  late StreamSubscription _messageSubscription;
  late StreamSubscription _presenceSubscription;
  final Logger _logger = Logger('ChatScreen');

  @override
  void initState() {
    super.initState();
    _setupLogging();
    _connect();
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL; // Set the logging level
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });
  }

  void _connect() async {
    _logger.info('Attempting to connect to XMPP server...');
    var jid = xmpp.Jid.fromFullJid('${widget.username}@${widget.domain}');
    var account = xmpp.XmppAccountSettings(
      'name',
      widget.username,
      widget.domain,
      widget.password,
      widget.port,
      host: widget.domain,
      resource: 'resource',
    );

    _connection = xmpp.Connection(account);

    _connection.connectionStateStream.listen((xmpp.XmppConnectionState state) {
      _logger.info('Connection state changed: $state');
      if (state == xmpp.XmppConnectionState.Ready) {
        _logger.info('Connected to XMPP server!');
        _joinGroup();
      }
    });

    _messageSubscription = _connection.inStanzasStream.listen((stanza) {
      if (stanza is xmpp.MessageStanza && stanza.body != null) {
        _logger.info('Message received from ${stanza.fromJid!.fullJid}: ${stanza.body}');
        setState(() {
          _messages.add('${stanza.fromJid!.fullJid}: ${stanza.body}');
        });
      }
    });

    _presenceSubscription = _connection.inStanzasStream.listen((stanza) {
      if (stanza is xmpp.PresenceStanza) {
        _logger.info('Presence stanza received from ${stanza.fromJid!.fullJid}: ${stanza.type}');
        _handlePresenceStanza(stanza);
      }
    });

    _connection.connect();
  }

  void _joinGroup() {
    String groupName = dotenv.env['GROUP_NAME']!;
    String groupJid = '$groupName@conference.${widget.domain}';
    var presenceStanza = xmpp.PresenceStanza();
    presenceStanza.toJid = xmpp.Jid.fromFullJid(groupJid);
    _logger.info('Joining group with JID: $groupJid');
    _connection.writeStanza(presenceStanza);
  }

  void _handlePresenceStanza(xmpp.PresenceStanza stanza) {
    var userJid = stanza.fromJid?.fullJid;
    if (userJid != null) {
      setState(() {
        if (stanza.type == null && !_users.contains(userJid)) {
          _logger.info('User available: $userJid');
          _users.add(userJid);
        } else if (stanza.type == xmpp.PresenceType.UNAVAILABLE) {
          _logger.info('User unavailable: $userJid');
          _users.remove(userJid);
        }
      });
    }
  }

  void _sendMessage() {
    if (_selectedUser != null) {
      var message = _messageController.text;
      var jidTo = xmpp.Jid.fromFullJid(_selectedUser!);
      var messageStanza = xmpp.MessageStanza(
        'id',
        xmpp.MessageStanzaType.CHAT,
      );
      messageStanza.toJid = jidTo;
      messageStanza.body = message;
      _logger.info('Sending message to ${jidTo.fullJid}: $message');
      _connection.writeStanza(messageStanza);
      setState(() {
        _messages.add('Me: $message');
      });
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _logger.info('Disposing resources...');
    _messageSubscription.cancel();
    _presenceSubscription.cancel();
    _connection.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _connection.close();
              Navigator.pop(context);
            },
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

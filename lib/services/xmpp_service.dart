import 'dart:async';
import 'dart:convert';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'package:logging/logging.dart';
import '../models/user.dart';

class XmppService {
  final Logger _logger = Logger('XmppService');
  late xmpp.Connection _connection;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _presenceSubscription;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<List<String>> _usersController = StreamController.broadcast();
  List<String> _users = [];

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<List<String>> get usersStream => _usersController.stream;

  void connect(User user, String domain, int port) {
    _logger.info('Attempting to connect to XMPP server...');
    xmpp.Jid.fromFullJid('${user.username}@$domain');
    var account = xmpp.XmppAccountSettings(
      'name',
      user.username,
      domain,
      user.password,
      port,
      host: domain,
      resource: 'resource',
    );

    _connection = xmpp.Connection(account);

    _connection.connectionStateStream.listen((xmpp.XmppConnectionState state) {
      _logger.info('Connection state changed: $state');
      if (state == xmpp.XmppConnectionState.Ready) {
        _logger.info('Connected to XMPP server!');
        _joinGroup(user.groupName, domain);
      }
    });

    _messageSubscription = _connection.inStanzasStream.listen((stanza) {
      if (stanza is xmpp.MessageStanza && stanza.body != null) {
        final sender = stanza.fromJid!.local; // Extracting the username
        try {
          final messageData = jsonDecode(stanza.body!);
          final userProfile = jsonDecode(messageData['userProfile']);
          final messageText = messageData['message'];
          _messageController.add({
            'sender': sender,
            'displayName': userProfile['displayName'] ?? sender,
            'photoUrl': userProfile['photoUrl'],
            'message': messageText,
          });
          _logger.info('Message received from $sender: $messageText');
        } catch (e) {
          _logger.warning('Failed to decode message: $e');
        }
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

  void _joinGroup(String groupName, String domain) {
    String groupJid = '$groupName@conference.$domain';
    var presenceStanza = xmpp.PresenceStanza();
    presenceStanza.toJid = xmpp.Jid.fromFullJid(groupJid);
    _logger.info('Joining group with JID: $groupJid');
    _connection.writeStanza(presenceStanza);
  }

  void _handlePresenceStanza(xmpp.PresenceStanza stanza) {
    var userJid = stanza.fromJid?.local; // Extracting the username
    if (userJid != null) {
      if (stanza.type == null && !_users.contains(userJid)) {
        _logger.info('User available: $userJid');
        _users.add(userJid);
        _usersController.add(_users);
      } else if (stanza.type == xmpp.PresenceType.UNAVAILABLE) {
        _logger.info('User unavailable: $userJid');
        _users.remove(userJid);
        _usersController.add(_users);
      }
    }
  }

  void sendMessage(User user, String message, String toUsername) {
    var jidTo = xmpp.Jid.fromFullJid('$toUsername@${_connection.account.domain}');
    var messageStanza = xmpp.MessageStanza(
      DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      xmpp.MessageStanzaType.CHAT,
    );
    messageStanza.toJid = jidTo;
    var userProfile = jsonEncode({
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
    });
    messageStanza.body = jsonEncode({
      'userProfile': userProfile,
      'message': message,
    });
    _logger.info('Sending message to ${jidTo.fullJid}: $message'); // Logging full JID

    _connection.writeStanza(messageStanza);
  }

  void dispose() {
    _logger.info('Disposing resources...');
    _messageSubscription.cancel();
    _presenceSubscription.cancel();
    _connection.close();
    _messageController.close();
    _usersController.close();
  }
}

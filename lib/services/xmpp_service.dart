import 'dart:async';
import 'package:logging/logging.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class XmppService {
  final Logger _logger = Logger('XmppService');
  late xmpp.Connection _connection;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _presenceSubscription;
  final StreamController<String> _messageController = StreamController.broadcast();
  final StreamController<List<String>> _usersController = StreamController.broadcast();
  List<String> _users = [];

  Stream<String> get messageStream => _messageController.stream;
  Stream<List<String>> get usersStream => _usersController.stream;

  void connect(String username, String password, String domain, int port) {
    _logger.info('Attempting to connect to XMPP server...');
    var jid = xmpp.Jid.fromFullJid('$username@$domain');
    var account = xmpp.XmppAccountSettings(
      'name',
      username,
      domain,
      password,
      port,
      host: domain,
      resource: 'resource',
    );

    _connection = xmpp.Connection(account);

    _connection.connectionStateStream.listen((xmpp.XmppConnectionState state) {
      _logger.info('Connection state changed: $state');
      if (state == xmpp.XmppConnectionState.Ready) {
        _logger.info('Connected to XMPP server!');
        _joinGroup(domain);
      }
    });

    _messageSubscription = _connection.inStanzasStream.listen((stanza) {
      if (stanza is xmpp.MessageStanza && stanza.body != null) {
        final sender = stanza.fromJid!.local; // Extracting the username
        final message = '${sender}: ${stanza.body}';
        _logger.info('Message received from $sender: ${stanza.body}');
        _messageController.add(message);
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

  void _joinGroup(String domain) {
    String groupName = dotenv.env['GROUP_NAME']!;
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

  void sendMessage(String message, String toUsername) {
    String domain = dotenv.env['DOMAIN']!;
    var jidTo = xmpp.Jid.fromFullJid('$toUsername@$domain');
    var messageStanza = xmpp.MessageStanza(
      DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      xmpp.MessageStanzaType.CHAT,
    );
    messageStanza.toJid = jidTo;
    messageStanza.body = message;
    _logger.info('Sending message to ${jidTo.fullJid}: $message'); // Logging full JID

    // Aggiunta del log prima di inviare il messaggio
    _logger.info('Message stanza before sending: ${messageStanza.buildXmlString()}');
    _connection.writeStanza(messageStanza);
    _logger.info('Message stanza sent successfully.');
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

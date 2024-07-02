import 'dart:async';
import 'dart:convert'; // Aggiunto jsonEncode e jsonDecode
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import 'package:logging/logging.dart';
import '../config.dart';
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

  Future<bool> connect(User user) async {
    _logger.info('XmppService.connect: Attempting to connect to XMPP server...');
    xmpp.Jid.fromFullJid('${user.username}@${Config.domain}');
    var account = xmpp.XmppAccountSettings(
      user.displayName,
      user.username,
      Config.domain,
      user.password,
      kIsWeb ? Config.webPort : Config.port,
      host: Config.domain,
      resource: _getResource(),
      wsPath: 'ws',
      wsProtocols: ['xmpp'],
    );

    _connection = xmpp.Connection(account);

    final completer = Completer<bool>();

    _connection.connectionStateStream.listen((xmpp.XmppConnectionState state) {
      _logger.info('XmppService.connect: Connection state changed: $state');
      if (state == xmpp.XmppConnectionState.Ready) {
        _logger.info('XmppService.connect: Connected to XMPP server!');
        completer.complete(true);
      } else if (state == xmpp.XmppConnectionState.ForcefullyClosed) {
        completer.complete(false);
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
            'photoBase64': userProfile['photoBase64'],
            'message': messageText,
          });
          _logger.info('XmppService.connect: Message received from $sender: $messageText');
        } catch (e) {
          _logger.warning('XmppService.connect: Failed to decode message: $e');
        }
      }
    });

    _presenceSubscription = _connection.inStanzasStream.listen((stanza) {
      if (stanza is xmpp.PresenceStanza) {
        _logger.info('XmppService.connect: Presence stanza received from ${stanza.fromJid!.fullJid}: ${stanza.type}');
        _handlePresenceStanza(stanza);
      }
    });

    _connection.connect();
    return completer.future;
  }

  void _handlePresenceStanza(xmpp.PresenceStanza stanza) {
    var userJid = stanza.fromJid?.local; // Extracting the username
    if (userJid != null) {
      if (stanza.type == null && !_users.contains(userJid)) {
        _logger.info('XmppService._handlePresenceStanza: User available: $userJid');
        _users.add(userJid);
        _usersController.add(_users);
      } else if (stanza.type == xmpp.PresenceType.UNAVAILABLE) {
        _logger.info('XmppService._handlePresenceStanza: User unavailable: $userJid');
        _users.remove(userJid);
        _usersController.add(_users);
      }
    }
  }

  String _getResource() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isWindows) {
      return 'windows';
    } else {
      return 'unknown';
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
      'photoBase64': user.photoBase64,
    });
    messageStanza.body = jsonEncode({
      'userProfile': userProfile,
      'message': message,
    });
    _logger.info('XmppService.sendMessage: Sending message to ${jidTo.fullJid}: $message'); // Logging full JID

    _connection.writeStanza(messageStanza);
  }

  void dispose() {
    _logger.info('XmppService.dispose: Disposing resources...');
    _messageSubscription.cancel();
    _presenceSubscription.cancel();
    _connection.close();
    _messageController.close();
    _usersController.close();
  }
}

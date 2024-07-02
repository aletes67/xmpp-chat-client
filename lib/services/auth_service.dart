import 'dart:io';
import 'package:logging/logging.dart';
import '../models/user.dart';
import 'xmpp_service.dart';

class AuthService {
  final Logger _logger = Logger('AuthService');
  final XmppService _xmppService = XmppService();

  AuthService();

  Future<User?> tryLoadUserFromProfile() async {
    _logger.info('AuthService.tryLoadUserFromProfile: Trying to load user from profile...');
    return await User.loadFromLocalStorage();
  }

  Future<bool> authenticate(String username, String password) async {
    _logger.info('AuthService.authenticate: Authenticating user...');
    final user = User(
      username: username,
      password: password,
      displayName: username,
      groupName: '---',
      isAuthenticated: false,
    );

    // Attempt to connect to the XMPP server
    bool isAuthenticated = await _xmppService.connect(user);

    if (isAuthenticated) {
      user.isAuthenticated = true;
      return true;
    } else {
      return false;
    }
  }

  XmppService get xmppService => _xmppService;
}

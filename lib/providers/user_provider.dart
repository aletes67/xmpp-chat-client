import 'package:flutter/material.dart';
import 'package:chat_client/models/user.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:chat_client/services/xmpp_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthService _authService = AuthService();
  final XmppService _xmppService = XmppService();

  User? get user => _user;
  XmppService get xmppService => _xmppService;

  Future<void> loadUser(String username, String password) async {
    _user = await _authService.getUserProfile(username, password);
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    await _authService.saveUserProfile(user);
    _user = user;
    notifyListeners();
  }

  Future<User?> tryLoadUserFromProfile() async {
    _user = await _authService.tryLoadUserFromProfile();
    if (_user != null) {
      bool authenticated = await _xmppService.connect(_user!);
      if (!authenticated) {
        _user = null;
      }
    }
    notifyListeners();
    return _user;
  }

  Future<bool> authenticate(String username, String password) async {
    final user = await _authService.getUserProfile(username, password);
    bool authenticated = await _xmppService.connect(user);
    if (authenticated) {
      _user = user;
      await _authService.saveUserProfile(user);
    }
    notifyListeners();
    return authenticated;
  }

  Future<void> clearCredentials() async {
    await _authService.clearCredentials();
    _user = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:chat_client/models/user.dart';
import 'package:chat_client/services/xmpp_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  late XmppService _xmppService;

  UserProvider() {
    _xmppService = XmppService(this); // Passa il provider stesso a XmppService
  }

  User? get user => _user;
  XmppService get xmppService => _xmppService;

  Future<void> loadUser(String username, String password) async {
    _user = User(username: username, password: password, displayName: username, groupName: '---');
    notifyListeners();
  }

  Future<void> updateUser(User user) async {
    await user.saveToLocalStorage();
    _user = user;
    notifyListeners();
  }

  Future<User?> tryLoadUserFromProfile() async {
    _user = await User.loadFromLocalStorage();
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
    final user = User(
      username: username,
      password: password,
      displayName: username,
      groupName: '---',
      isAuthenticated: false,
    );
    bool authenticated = await _xmppService.connect(user);
    if (authenticated) {
      _user = User(username: username, password: password, displayName: username, groupName: '---', isAuthenticated: true);
      await _user!.saveToLocalStorage();
    }
    notifyListeners();
    return authenticated;
  }

  Future<void> clearCredentials() async {
    await _user?.clearCredentials();
    _user = null;
    notifyListeners();
  }
}

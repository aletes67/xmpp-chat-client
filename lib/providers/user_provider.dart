import 'package:flutter/material.dart';
import 'package:chat_client/models/user.dart';
import 'package:chat_client/services/xmpp_service.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class UserProvider with ChangeNotifier {
  User? _user;
  late XmppService _xmppService;
  List<String> _users = [];
  String? authError;

  UserProvider() {
    _xmppService = XmppService();
    _xmppService.usersStream.listen((users) {
      _users = users.where((u) => u != _user?.username).toList();
      notifyListeners();
      print('UserProvider usersStream listen: $_users');
    });

    // Listen to connection state changes
    _xmppService.connectionStateStream.listen((state) {
      if (state == xmpp.XmppConnectionState.Closed || state == xmpp.XmppConnectionState.ForcefullyClosed) {
        clearCredentials();
        notifyListeners();
      }
    });
  }

  User? get user => _user;
  XmppService get xmppService => _xmppService;
  List<String> get users => _users;

  Future<void> loadUser(String username, String password) async {
    _user = User(username: username, password: password, displayName: username, groupName: '---');
    notifyListeners();
    print('UserProvider loadUser: $_user');
  }

  Future<void> updateUser(User user) async {
    await user.saveToLocalStorage();
    _user = user;
    notifyListeners();
    print('UserProvider updateUser: $_user');
  }

  Future<User?> tryLoadUserFromProfile() async {
    _user = await User.loadFromLocalStorage();
    print('UserProvider tryLoadUserFromProfile: $_user');
    if (_user != null) {
      bool authenticated = await _xmppService.connect(_user!);
      if (!authenticated) {
        _user = null;
      }
    }
    notifyListeners();
    print('UserProvider notifyListeners: $_user');
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
    print('UserProvider authenticate: user created');
    bool authenticated = await _xmppService.connect(user);
    print('UserProvider authenticate: xmppService connect: $authenticated');
    if (authenticated) {
      _user = User(username: username, password: password, displayName: username, groupName: '---', isAuthenticated: true);
      await _user!.saveToLocalStorage();
      authError = null;
    } else {
      authError = 'Authentication failed. Please check your credentials and try again.';
      _user = null;
    }
    notifyListeners();
    print('UserProvider authenticate: notifyListeners: $_user, authError: $authError');
    return authenticated;
  }

  Future<void> clearCredentials() async {
    await _user?.clearCredentials();
    _user = null;
    notifyListeners();
    print('UserProvider clearCredentials: $_user');
  }
}

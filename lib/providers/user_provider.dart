import 'package:flutter/material.dart';
import 'package:chat_client/models/user.dart';
import 'package:chat_client/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthService _authService = AuthService();

  User? get user => _user;

  Future<void> loadUser(String username) async {
    _user = await _authService.getUserProfile(username);
    notifyListeners();
  }

  Future<void> updateUser(User user, String? photoPath) async {
    await _authService.saveUserProfile(user, photoPath);
    _user = user;
    notifyListeners();
  }
}

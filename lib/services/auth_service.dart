import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/user.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromLength(32)));
  final _iv = encrypt.IV.fromLength(16);

  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'password', value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    String? username = await _storage.read(key: 'username');
    String? password = await _storage.read(key: 'password');
    return {'username': username, 'password': password};
  }

  Future<void> saveUserProfile(User user, String? photoPath) async {
    if (photoPath != null) {
      await user.saveImageLocally(File(photoPath));
    }

    // Save to local storage
    await _storage.write(key: 'displayName', value: user.displayName);
    if (user.photoUrl != null) {
      await _storage.write(key: 'photoUrl', value: user.photoUrl);
      await _storage.write(key: 'photoBase64', value: user.photoBase64);
    }
    await _storage.write(key: 'groupName', value: user.groupName);

    // Save to home directory
    await user.saveToLocalStorage(_encrypter, _iv);
  }

  Future<User> getUserProfile(String username) async {
    String? password = await _storage.read(key: 'password');
    String? displayName = await _storage.read(key: 'displayName');
    String? photoUrl = await _storage.read(key: 'photoUrl');
    String? photoBase64 = await _storage.read(key: 'photoBase64');
    String? groupName = await _storage.read(key: 'groupName');

    try {
      return await User.loadFromLocalStorage(username, _encrypter, _iv);
    } catch (e) {
      return User(
        username: username,
        password: password ?? '',
        displayName: displayName ?? '',
        groupName: groupName ?? '',
        photoUrl: photoUrl,
        photoBase64: photoBase64,
      );
    }
  }

  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }
}

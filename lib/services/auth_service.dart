import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
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

  String generateResource() {
    if (kIsWeb) {
      return 'browser';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isWindows) {
      return 'windows';
    } else {
      return 'unknown';
    }
  }

  Future<void> saveUserProfile(User user, String? photoPath) async {
    String resource = generateResource();
    String? photoUrl;
    if (photoPath != null) {
      photoUrl = await _saveImageLocally(File(photoPath), user.username);
      user.photoUrl = photoUrl;
    }

    // Save to local storage
    await _storage.write(key: 'displayName', value: user.displayName);
    if (photoUrl != null) {
      await _storage.write(key: 'photoUrl', value: photoUrl);
    }
    await _storage.write(key: 'groupName', value: user.groupName);

    // Save to home directory
    final userProfile = user.toJson();
    final jsonString = jsonEncode(userProfile);
    final encrypted = _encrypter.encrypt(jsonString, iv: _iv);
    final directory = await _getLocalPath();
    final file = File('$directory/.${resource}chtxmp');
    await file.writeAsString(encrypted.base64);
  }

  Future<User> getUserProfile(String username) async {
    String resource = generateResource();
    String? password = await _storage.read(key: 'password');
    String? displayName = await _storage.read(key: 'displayName');
    String? photoUrl = await _storage.read(key: 'photoUrl');
    String? groupName = await _storage.read(key: 'groupName');

    final directory = await _getLocalPath();
    final file = File('$directory/.${resource}chtxmp');
    if (await file.exists()) {
      final encrypted = await file.readAsString();
      final decrypted = _encrypter.decrypt64(encrypted, iv: _iv);
      final userProfile = jsonDecode(decrypted);
      displayName = userProfile['displayName'] ?? displayName;
      photoUrl = userProfile['photoUrl'] ?? photoUrl;
      groupName = userProfile['groupName'] ?? groupName;
    }

    return User(
      username: username,
      password: password ?? '',
      displayName: displayName ?? username,
      groupName: groupName ?? '',
      photoUrl: photoUrl,
    );
  }

  Future<String?> _saveImageLocally(File imageFile, String username) async {
    final directory = await _getLocalPath();
    final imagePath = '$directory/$username.jpg';
    final imageFileCopy = await imageFile.copy(imagePath);
    return imageFileCopy.path;
  }

  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }
}

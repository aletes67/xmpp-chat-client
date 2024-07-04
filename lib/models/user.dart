import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class User {
  String username;
  String password;
  String displayName;
  String? photoBase64;
  String groupName;
  bool isAuthenticated;
  static final encrypt.Key _key = encrypt.Key.fromUtf8('83gtwrqt5432bhsy6543qfag98jjuyt5');
  static final encrypt.Encrypter _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  static String get _profileFilePath => 'user_profile.json';

  User({
    required this.username,
    required this.password,
    required this.displayName,
    required this.groupName,
    this.photoBase64,
    this.isAuthenticated = false,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'displayName': displayName,
    'photoBase64': photoBase64,
    'groupName': groupName,
    'isAuthenticated': isAuthenticated,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'],
    password: json['password'],
    displayName: json['displayName'],
    photoBase64: json['photoBase64'],
    groupName: json['groupName'],
    isAuthenticated: json['isAuthenticated'],
  );

  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> saveToLocalStorage() async {
    final jsonString = jsonEncode(toJson());

    final iv = encrypt.IV.fromLength(16); // Create a new IV
    final encrypted = _encrypter.encrypt(jsonString, iv: iv);

    final encryptedData = jsonEncode({
      'iv': iv.base64,
      'data': encrypted.base64,
    });

    if (kIsWeb) {
      // Save to SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileFilePath, encryptedData);
    } else {
      // Save to file for non-web
      final path = await getLocalPath();
      final file = File('$path/$_profileFilePath');
      await file.writeAsString(encryptedData);
    }
  }

  static Future<User?> loadFromLocalStorage() async {
    try {
      String? encryptedContent;

      if (kIsWeb) {
        // Load from SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        encryptedContent = prefs.getString(_profileFilePath);
      } else {
        // Load from file for non-web
        final path = await getLocalPath();
        final file = File('$path/$_profileFilePath');
        if (!file.existsSync()) throw Exception('Profile not found');
        encryptedContent = await file.readAsString();
      }

      if (encryptedContent == null) throw Exception('Profile not found');

      final Map<String, dynamic> encryptedJson = jsonDecode(encryptedContent);

      final iv = encrypt.IV.fromBase64(encryptedJson['iv']);
      final encryptedData = encryptedJson['data'];

      final decrypted = _encrypter.decrypt64(encryptedData, iv: iv);
      final userProfile = jsonDecode(decrypted);

      return User.fromJson(userProfile);
    } catch (e) {
      // Handle error appropriately
      print('Failed to load user from profile. Error: $e');
      return null;
    }
  }

  Future<void> clearCredentials() async {
    try {
      if (kIsWeb) {
        // Clear SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_profileFilePath);
      } else {
        // Clear file for non-web
        final path = await getLocalPath();
        final file = File('$path/$_profileFilePath');
        if (file.existsSync()) {
          await file.delete();
        }
      }
    } catch (e) {
      // Handle error
      print('Failed to clear credentials. Error: $e');
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class User {
  String username;
  String password;
  String displayName;
  String? photoBase64;
  String groupName;
  bool isAuthenticated;

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

  Future<void> saveToLocalStorage(encrypt.Encrypter encrypter, encrypt.IV iv) async {
    final path = await getLocalPath();
    final file = File('$path/${username}_profile.json');
    final jsonString = jsonEncode(toJson());
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    await file.writeAsString(encrypted.base64);
  }

  static Future<User> loadFromLocalStorage(String username, encrypt.Encrypter encrypter, encrypt.IV iv) async {
    final path = await getLocalPath();
    final file = File('$path/${username}_profile.json');
    if (!file.existsSync()) throw Exception('Profile not found');

    final encrypted = await file.readAsString();
    final decrypted = encrypter.decrypt64(encrypted, iv: iv);
    final userProfile = jsonDecode(decrypted);

    return User.fromJson(userProfile);
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class User {
  String username;
  String password;
  String displayName;
  String groupName;
  String? photoUrl;
  String? photoBase64;

  User({
    required this.username,
    required this.password,
    required this.displayName,
    required this.groupName,
    this.photoUrl,
    this.photoBase64,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'displayName': displayName,
    'groupName': groupName,
    'photoUrl': photoUrl,
    'photoBase64': photoBase64,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'],
    password: json['password'],
    displayName: json['displayName'],
    groupName: json['groupName'],
    photoUrl: json['photoUrl'],
    photoBase64: json['photoBase64'],
  );

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

  Future<String?> saveImageLocally(File imageFile) async {
    final directory = await getLocalPath();
    final imagePath = '$directory/$username.jpg';
    final imageFileCopy = await imageFile.copy(imagePath);
    photoUrl = imageFileCopy.path;
    photoBase64 = base64Encode(imageFile.readAsBytesSync());
    return photoUrl;
  }

  Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> saveToLocalStorage(encrypt.Encrypter encrypter, encrypt.IV iv) async {
    final userProfile = toJson();
    final jsonString = jsonEncode(userProfile);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    final directory = await getLocalPath();
    final resource = generateResource();
    final file = File('$directory/.${resource}chtxmp');
    await file.writeAsString(encrypted.base64);
  }

  static Future<User> loadFromLocalStorage(String username, encrypt.Encrypter encrypter, encrypt.IV iv) async {
    final directory = await getApplicationDocumentsDirectory();
    final resource = User(username: username, password: '', displayName: '', groupName: '').generateResource();
    final file = File('$directory/.${resource}chtxmp');
    if (await file.exists()) {
      final encrypted = await file.readAsString();
      final decrypted = encrypter.decrypt64(encrypted, iv: iv);
      final userProfile = jsonDecode(decrypted);
      return User.fromJson(userProfile);
    } else {
      throw Exception('User profile not found');
    }
  }
}

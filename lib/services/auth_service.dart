import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logging/logging.dart';
import '../models/user.dart';
import 'xmpp_service.dart';

class AuthService {
  final Logger _logger = Logger('AuthService');
  late final encrypt.Key _key;
  final encrypt.IV _iv = encrypt.IV.fromLength(16);
  late final encrypt.Encrypter _encrypter;
  late final XmppService _xmppService;

  AuthService() {
    _key = encrypt.Key.fromUtf8('83gtwrqt5432bhsy6543qfag98jjuyt5');
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    _xmppService = XmppService();
  }

  Future<User?> tryLoadUserFromProfile() async {
    _logger.info('AuthService.tryLoadUserFromProfile: Trying to load user from profile...');
    try {
      String path = await User.getLocalPath();
      File profileFile = File('$path/user_profile.json');
      if (profileFile.existsSync()) {
        String encryptedContent = await profileFile.readAsString();
        String decryptedContent = _encrypter.decrypt64(encryptedContent, iv: _iv);
        Map<String, dynamic> profileData = jsonDecode(decryptedContent);
        User user = User.fromJson(profileData);
        bool authenticated = await authenticate(user.username, user.password);
        if (authenticated) {
          user.isAuthenticated = true;
          return user;
        }
      }
    } catch (e) {
      _logger.warning('AuthService.tryLoadUserFromProfile: Failed to load user from profile. Error: $e');
    }
    return null;
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
      await saveUserProfile(user); // Save the profile if authenticated
      return true;
    } else {
      return false;
    }
  }

  Future<void> saveUserProfile(User user) async {
    _logger.info('AuthService.saveUserProfile: Saving user profile...');
    try {
      String path = await User.getLocalPath();
      File profileFile = File('$path/user_profile.json');
      String jsonString = jsonEncode(user.toJson());
      String encryptedContent = _encrypter.encrypt(jsonString, iv: _iv).base64;
      await profileFile.writeAsString(encryptedContent);
    } catch (e) {
      _logger.warning('AuthService.saveUserProfile: Failed to save user profile. Error: $e');
    }
  }

  Future<User> getUserProfile(String username, String password) async {
    _logger.info('AuthService.getUserProfile: Getting user profile...');
    User user = User(
      username: username,
      password: password,
      displayName: username,
      groupName: '---',
      isAuthenticated: true,
    );
    return user;
  }

  Future<void> clearCredentials() async {
    _logger.info('AuthService.clearCredentials: Clearing credentials...');
    try {
      String path = await User.getLocalPath();
      File profileFile = File('$path/user_profile.json');
      if (profileFile.existsSync()) {
        await profileFile.delete();
      }
    } catch (e) {
      _logger.warning('AuthService.clearCredentials: Failed to clear credentials. Error: $e');
    }
  }

  XmppService get xmppService => _xmppService;
}

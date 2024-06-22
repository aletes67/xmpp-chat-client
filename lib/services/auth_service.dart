import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'password', value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    String? username = await _storage.read(key: 'username');
    String? password = await _storage.read(key: 'password');
    return {'username': username, 'password': password};
  }

  Future<void> saveUserProfile(String displayName, String resource, String photoPath) async {
    await _storage.write(key: 'displayName', value: displayName);
    await _storage.write(key: 'resource', value: resource);
    await _storage.write(key: 'photoPath', value: photoPath);
  }

  Future<Map<String, String?>> getUserProfile() async {
    String? displayName = await _storage.read(key: 'displayName');
    String? resource = await _storage.read(key: 'resource');
    String? photoPath = await _storage.read(key: 'photoPath');
    return {'displayName': displayName, 'resource': resource, 'photoPath': photoPath};
  }

  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }
}

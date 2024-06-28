import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../config.dart';
import '../models/user.dart';

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

  String generateResource() {
    var uuid = Uuid();
    return uuid.v4();
  }

  Future<String?> uploadImage(File imageFile, String group, String username) async {
    final uri = Uri.parse('${Config.imageUploadUrl}/upload'); // L'endpoint del plugin Openfire
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = Config.authToken // Aggiungi l'header di autorizzazione
      ..fields['group'] = group
      ..fields['username'] = username
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      return jsonResponse['url']; // Supponendo che il server Openfire ritorni l'URL dell'immagine
    } else {
      throw Exception('Failed to upload image');
    }
  }

  Future<void> saveUserProfile(User user, String? photoPath) async {
    String? photoUrl;
    if (photoPath != null) {
      photoUrl = await uploadImage(File(photoPath), user.groupName, user.username);
      user.photoUrl = photoUrl;
    }

    // Crea la lista di propriet� utente nel formato corretto
    final userProperties = [
      {'key': 'displayName', 'value': user.displayName},
      if (photoUrl != null) {'key': 'photoUrl', 'value': photoUrl}
    ];

    // Save to Openfire server
    final response = await http.put(
      Uri.parse('${Config.apiUrl}/users/${user.username}'),
      headers: {
        'Authorization': Config.authToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': user.username,
        'password': user.password,
        'name': user.username,
        'email': '', // Aggiungi un campo email vuoto se necessario
        'properties': userProperties
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user profile on server: ${response.body}');
    }

    // Save to local storage
    await _storage.write(key: 'displayName', value: user.displayName);
    if (photoUrl != null) {
      await _storage.write(key: 'photoUrl', value: photoUrl);
    }
    await _storage.write(key: 'groupName', value: user.groupName);
  }

  Future<User> getUserProfile(String username) async {
    String? password = await _storage.read(key: 'password');
    String? displayName = await _storage.read(key: 'displayName');
    String? photoUrl = await _storage.read(key: 'photoUrl');
    String? groupName;

    // Fetch from Openfire server
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/users/$username'),
      headers: {
        'Authorization': Config.authToken,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final userProfile = jsonDecode(response.body);
        final properties = userProfile['properties'] ?? {};

        try {
          displayName = properties['displayName'];
        } catch (e) {
          displayName = "";
        }
        try {
          photoUrl = properties['photoUrl'];
        } catch (e) {
          photoUrl = "";
        }

        // Fetch group information from Openfire
        final groupResponse = await http.get(
          Uri.parse('${Config.apiUrl}/users/$username/groups'),
          headers: {
            'Authorization': Config.authToken,
            'Accept': 'application/json',
          },
        );

        if (groupResponse.statusCode == 200) {
          final groups = jsonDecode(groupResponse.body) as Map<String, dynamic>;
          if (groups.isNotEmpty) {
            groupName = groups.values.elementAt(0).toString(); // Assuming the user belongs to one group
            final grp1 = groupName.toString().replaceFirst(RegExp('\\['), '');
            groupName = grp1.replaceFirst(RegExp('\\]'), '');
            await _storage.write(key: 'groupName', value: groupName);
          }
        }

        return User(
          username: username,
          password: password ?? '',
          displayName: displayName ?? '',
          groupName: groupName ?? '',
          photoUrl: photoUrl,
        );
      } catch (e) {
        throw Exception('Failed to parse user profile response: $e');
      }
    } else {
      throw Exception('Failed to fetch user profile from server');
    }
  }

  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }
}

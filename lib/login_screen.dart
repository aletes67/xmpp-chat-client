import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  void _loadCredentials() async {
    String? username = await _storage.read(key: 'username');
    String? password = await _storage.read(key: 'password');

    if (username != null && password != null) {
      _login(username, password);
    }
  }

  void _login(String username, String password) {
    String domain = dotenv.env['DOMAIN']!;
    int port = int.parse(dotenv.env['PORT']!);

    // Save credentials securely
    _storage.write(key: 'username', value: username);
    _storage.write(key: 'password', value: password);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          username: username,
          password: password,
          domain: domain,
          port: port,
        ),
      ),
    );
  }

  void _handleLogin() {
    String username = _usernameController.text;
    String password = _passwordController.text;
    _login(username, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

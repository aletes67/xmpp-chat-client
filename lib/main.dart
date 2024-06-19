import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_client/login_screen.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:chat_client/pages/chat_screen.dart';

void main() async {
  await dotenv.load(fileName: "config");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authService.getCredentials(),
      builder: (context, AsyncSnapshot<Map<String, String?>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else {
          final credentials = snapshot.data!;
          if (credentials['username'] != null && credentials['password'] != null) {
            return MaterialApp(
              title: 'XMPP Chat',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: ChatScreen(
                username: credentials['username']!,
                password: credentials['password']!,
                domain: dotenv.env['DOMAIN']!,
                port: int.parse(dotenv.env['PORT']!),
              ),
            );
          } else {
            return MaterialApp(
              title: 'XMPP Chat',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: LoginScreen(),
            );
          }
        }
      },
    );
  }
}

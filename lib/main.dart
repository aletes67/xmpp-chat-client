import 'package:chat_client/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:chat_client/pages/chat_screen.dart';
import 'package:chat_client/models/user.dart';

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
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else if (snapshot.hasData) {
          final credentials = snapshot.data!;
          if (credentials['username'] != null && credentials['password'] != null) {
            return FutureBuilder(
              future: _authService.getUserProfile(credentials['username']!),
              builder: (context, AsyncSnapshot<User> profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return MaterialApp(
                    home: Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                  );
                } else if (profileSnapshot.hasError) {
                  return MaterialApp(
                    home: Scaffold(
                      body: Center(child: Text('Error: ${profileSnapshot.error}')),
                    ),
                  );
                } else if (profileSnapshot.hasData) {
                  final user = profileSnapshot.data!;
                  return MaterialApp(
                    title: 'XMPP Chat',
                    theme: ThemeData(
                      primarySwatch: Colors.blue,
                    ),
                    home: ChatScreen(user: user),
                  );
                } else {
                  return MaterialApp(
                    home: Scaffold(
                      body: Center(child: Text('Profile not found')),
                    ),
                  );
                }
              },
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
        } else {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Credentials not found')),
            ),
          );
        }
      },
    );
  }
}

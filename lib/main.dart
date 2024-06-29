import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:chat_client/pages/chat_screen.dart';
import 'package:chat_client/pages/login_screen.dart';
import 'package:chat_client/providers/user_provider.dart';

void main() async {
  await dotenv.load(fileName: "config");
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MyApp(),
    ),
  );
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
            return FutureBuilder(
              future: Provider.of<UserProvider>(context, listen: false).loadUser(credentials['username']!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return MaterialApp(
                    home: Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ),
                  );
                } else {
                  return MaterialApp(
                    title: 'XMPP Chat',
                    theme: ThemeData(
                      primarySwatch: Colors.blue,
                    ),
                    home: Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        return ChatScreen(user: userProvider.user!);
                      },
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
        }
      },
    );
  }
}

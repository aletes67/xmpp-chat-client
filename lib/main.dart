import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:chat_client/pages/chat_screen.dart';
import 'package:chat_client/pages/login_screen.dart';
import 'package:chat_client/providers/user_provider.dart';
import 'package:chat_client/models/user.dart';

void main() async {
  Logger.root.level = Level.INFO; // Cambia il livello di log
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  await dotenv.load(fileName: "config");
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Provider.of<UserProvider>(context, listen: false).tryLoadUserFromProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          return MaterialApp(
            title: 'XMPP Chat',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: ChatScreen(user: user),
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
      },
    );
  }
}

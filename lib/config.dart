import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get groupName => dotenv.env['GROUP_NAME']!;
  static String get domain => dotenv.env['DOMAIN']!;
  static int get port => int.parse(dotenv.env['PORT']!);
}

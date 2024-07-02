import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get domain => dotenv.env['DOMAIN']!;
  static int get port => int.parse(dotenv.env['PORT']!);
  static String get apiUrl => dotenv.env['OPENFIRE_API_URL']!;
  static String get authToken => dotenv.env['OPENFIRE_AUTH_TOKEN']!;
  static String get imageUploadUrl => dotenv.env['UPLOAD_URL']!;
  static int get webPort => int.parse(dotenv.env['WEB_PORT']!);
}

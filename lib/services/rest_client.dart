import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:logging/logging.dart';

class RestClient {
  final Logger _logger = Logger('RestApi');

  final String baseUrl = dotenv.env['OPENFIRE_API_URL']!;
  final String authToken = dotenv.env['OPENFIRE_AUTH_TOKEN']!;

  Future<List<String>> getUserGroups(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$username/groups'),
      headers: {
        'Content-Type':'application/xml',
        'Authorization': authToken,
      },
    );

    if (response.statusCode == 200) {
      _logger.info('RestApi: getUserGroups: ${response.body}'); // Log the response body

      try {
        // Parse the XML response
        final document = xml.XmlDocument.parse(response.body);
        final groups = document.findAllElements('groupname').map((element) => element.text).toList();

        return groups;
      } catch (e) {
        _logger.warning('RestApi: getUserGroups: Failed to parse XML: $e');
        throw Exception('Failed to parse user groups');
      }
    } else {
      _logger.warning('RestApi: getUserGroups: Failed with status code: ${response.statusCode}');
      throw Exception('Failed to load user groups');
    }



  }
}

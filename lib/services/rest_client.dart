import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class RestClient {
  final String _baseUrl = Config.apiUrl;
  final String _authToken = Config.authToken;

  Future<List<String>> getUserGroups(String username) async {
    final url = '$_baseUrl/users/$username/groups';
    final headers = {
      'Authorization': _authToken,
      'accept': 'application/xml',
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      // Assuming the response is in XML format and contains group names
      final xmlResponse = response.body;
      // Parse the XML and extract the group names
      // This example assumes you have a function to parse XML
      return _parseGroupsFromXml(xmlResponse);
    } else {
      throw Exception('Failed to load user groups');
    }
  }

  List<String> _parseGroupsFromXml(String xmlResponse) {
    // Implement XML parsing logic here
    // This is a placeholder for the actual XML parsing code
    return [];
  }
}

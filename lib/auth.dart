import 'dart:convert';

import 'package:http/http.dart' as http;

Future<String> getAuthSessionTicket() async {
    var client = http.Client();
    var response = await client.get(
        Uri.parse('http://host.docker.internal:3001/token/1016950'));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    return decodedResponse['token'];
  }
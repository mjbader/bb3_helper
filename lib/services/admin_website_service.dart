import 'package:http/http.dart' as http;

class AdminWebsiteService {
  static const String baseUrl = 'https://web.cyanide-studio.com/bloodbowl/?env=en&lang=bb3_live_pc';

  String? phpsessid;

  static final instance = AdminWebsiteService();

  Future<String> getPHPSESSID() async {
    final Uri url = Uri.parse(baseUrl);

    final http.Response response = await http.get(
      url
    );

    phpsessid = response.headers['PHPSESSID'];
    return phpsessid!;
  }

  Future<http.Response> login(String username, String password) async {
    final Uri url = Uri.parse(baseUrl);

    final Map<String, String> body = {
      'user_username': username,
      'user_password': password,
      'env': 'bb3_live_pc',
      'login': 'Log+in',
      'PHPSESSID': phpsessid ?? await getPHPSESSID()
    };

    final http.Response response = await http.post(
      url,
      body: body,
    );

    return response;
  }
}
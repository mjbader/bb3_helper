import 'dart:typed_data';

import 'package:bb3_helper/models/competition.dart';
import 'package:bb3_helper/models/gamer.dart';
import 'package:bb3_helper/models/league.dart';
import 'package:bb3_helper/models/team.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class AdminWebsiteService extends ChangeNotifier {
  static const String baseUrl = 'https://web.cyanide-studio.com/bloodbowl/';

  String? _phpsessid;
  String? _username;
  String? _password;

  static final instance = AdminWebsiteService();

  bool _loading = false;
  bool get loading {
    return _loading;
  }

  set loading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  Gamer? user;
  List<League> leagues = [];
  List<Competition> leagueCompetitions = [];
  List<Competition> competitions = [];
  List<Team> compTeams = [];
  List<Team> replacingTeams = [];

  static String? extractPHPSESSID(String cookieString) {
    final RegExp regex = RegExp(r'PHPSESSID=([a-zA-Z0-9]+);');
    final Match? match = regex.firstMatch(cookieString);
    
    if (match != null) {
      return match.group(1);
    }
    
    return null;
  }

  Future<String> getPHPSESSID() async {
    final Uri url = Uri.parse(baseUrl);

    final http.Response response = await http.get(
      url
    );

    final cookie = response.headers['set-cookie'];
    if (cookie != null) {
      _phpsessid = extractPHPSESSID(cookie);
    }
    return _phpsessid!;
  }

  Future<bool> login(String username, String password) async {
    final Uri url = Uri.parse(baseUrl);

    final Map<String, String> body = {
      'user_username': username,
      'user_password': password,
      'env': 'bb3_live_pc',
      'login': 'Log+in',
      // 'PHPSESSID': _phpsessid ?? await getPHPSESSID()
    };

    final http.Response response = await http.post(
      url,
      body: body,
    );

    if (username != _username && password != _password) {
      final logged = await _parse(response, response.bodyBytes);
      if (!logged) {
        return false;
      }
    }

    _username = username;
    _password == password;

    return true;
  }


  Future<void> logout() async {
    Uri url = Uri.parse(baseUrl);
    url = url.replace(queryParameters: {'action': 'logout'});

    await http.get(url);
    _phpsessid = null;
    _username = null;
    _password = null;
    user = null;
    clearParsedData();
    notifyListeners();
  }

  void clearParsedData() {
    leagues.clear();
    competitions.clear();
    leagueCompetitions.clear();
    compTeams.clear();
    replacingTeams.clear();
  }

  Future<void> selectLeague(String leagueId) async {
    loading = true;

    Uri url = Uri.parse(baseUrl);
    var request = http.MultipartRequest('POST', url)
     ..fields['query'] = 'administrate_league'
     ..fields['bb3_administrate_league_League'] = leagueId;

    _applyBaseFields(request.fields);
    _applyCookie(request.headers);

    final response = await request.send();

    final bytes = await response.stream.toBytes();

    if (response.statusCode == 200) {
      await _parse(response, bytes);
    }
    loading = false;
  }

  Future<void> selectCompetition(String compId) async {
    loading = true;

    Uri url = Uri.parse(baseUrl);
    var request = http.MultipartRequest('POST', url)
     ..fields['query'] = 'administrate_competition'
     ..fields['bb3_administrate_competition_Competition'] = compId;

    _applyBaseFields(request.fields);
    _applyCookie(request.headers);

    final response = await request.send();

    final bytes = await response.stream.toBytes();

    if (response.statusCode == 200) {
      await _parse(response, bytes);
    }
    loading = false;
  }

  Future<bool> replaceTeam({required String replacingTeamId, required String replacedTeamId}) async {
    loading = true;
    Uri url = Uri.parse(baseUrl);
    var request = http.MultipartRequest('POST', url)
     ..fields['query'] = 'replace_team'
     ..fields['bb3_replace_team_ReplacedTeam'] = replacedTeamId
     ..fields['bb3_replace_team_ReplacingTeam'] = replacingTeamId;

    _applyBaseFields(request.fields);
    _applyCookie(request.headers);

    final response = await request.send();

    final bytes = await response.stream.toBytes();

    bool isSuccess = false;
    if (response.statusCode == 200) {
      var doc = parse(bytes);
      isSuccess = doc.getElementsByClassName('green success').isNotEmpty;
      await reload();
    } else {
      print("FAILURE!");
    }
    loading = false;
    return isSuccess;
  }

  Future<http.Response> reload() async {
    final Uri url = Uri.parse(baseUrl);
    final http.Response response = await http.get(
      url,
      headers: {
        'Cookie' : 'PHPSESSID=${_phpsessid ?? await getPHPSESSID()}' 
      }
    );

    await _parse(response, response.bodyBytes);

    return response;
  }

  void _applyBaseFields(Map<String, String> fields) {
    fields['game'] = 'bb3';
    fields['cat'] = 'admin';
    fields['debug'] = '';
    fields['t'] = DateTime.now().second.toString();
  }

  void _applyCookie(Map<String, String> headers) async {
    headers['Cookie'] = 'PHPSESSID=${_phpsessid ?? await getPHPSESSID()}';
  }

  Future<bool> _parse(BaseResponse response, Uint8List bytes) async {
    var doc = parse(bytes);
    
    final cookie = response.headers['set-cookie'];
    if (cookie != null) {
      _phpsessid = extractPHPSESSID(cookie);
    }

    final logged = await _parseUser(doc);
    if (!logged) {
      return false;
    }
    
    clearParsedData();

    _parseLeagues(doc);
    _parseCompetitions(doc);
    _parseLeagueCompetitions(doc);
    _parseCompetitionTeams(doc);
    _parseReplacingTeams(doc);
    notifyListeners();
    return true;
  }

  Future<bool> _parseUser(Document doc) async {
    final gamerInfo = doc.getElementsByClassName('gamer-info').firstOrNull;
    if (gamerInfo != null) {
      final gamerName = gamerInfo.children[0].children[1].innerHtml;
      final gamerId = gamerInfo.children[2].children[1].innerHtml;
      user = Gamer(id: gamerId, name: gamerName);
      return true;
    } else if (_username != null && _password != null) {
      // User not logged in.
      await login(_username!, _password!);
      return true;
    } else {
      return false;
    }
  }

  Future<void> _parseLeagues(Document doc) async {
    final leagueSelector = doc.getElementById('bb3_administrate_league_League');

    leagues.clear();

    if (leagueSelector != null) {
      for (var child in leagueSelector.children) {
        final id = child.attributes['value'];
        final name = child.attributes['label'];

        if (id != null && name != null) {
          leagues.add(League(id: id, name: name));
        } 
      }
    }
  }

  Future<void> _parseCompetitions(Document doc) async {
    final compSelector = doc.getElementById('bb3_administrate_competition_Competition');

    competitions.clear();

    if (compSelector != null) {
      for (var child in compSelector.children) {
        final id = child.attributes['value'];
        final name = child.attributes['label'];

        if (id != null && name != null) {
          competitions.add(Competition(id: id, name: name));
        } 
      }
    }
  }

  Future<void> _parseLeagueCompetitions(Document doc) async {
    final compSelectors = doc.querySelectorAll('#bb3_administrate_competition_Competition');

    if (compSelectors.isNotEmpty && compSelectors.length > 1) {
      final compSelector = compSelectors[1];
      for (var child in compSelector.children) {
        final id = child.attributes['value'];
        final name = child.attributes['label'];

        if (id != null && name != null) {
          leagueCompetitions.add(Competition(id: id, name: name));
        } 
      }
    }
  }

  Future<void> _parseCompetitionTeams(Document doc) async {
    final replacedTeamSelector = doc.getElementById('bb3_replace_team_ReplacedTeam');
    if (replacedTeamSelector != null) {
      for (var child in replacedTeamSelector.children) {
        final id = child.attributes['value'];
        final name = child.attributes['label'];

        if (id != null && name != null) {
          compTeams.add(Team(id: id, name: name));
        } 
      }
    }
  }

  Future<void> _parseReplacingTeams(Document doc) async {
    final replacingTeamSelector = doc.getElementById('bb3_replace_team_ReplacingTeam');
    if (replacingTeamSelector != null) {
      for (var child in replacingTeamSelector.children) {
        final id = child.attributes['value'];
        final name = child.attributes['label'];

        if (id != null && name != null) {
          replacingTeams.add(Team(id: id, name: name));
        } 
      }
    }
  }
}
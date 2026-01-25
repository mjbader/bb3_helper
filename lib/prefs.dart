import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Prefs {
  static final Prefs instance = Prefs();

  final storage = FlutterSecureStorage();

  Future<String?> get username => storage.read(key: 'username');

  set username(String? username) {
    storage.write(key: 'username', value: username);
  }

  Future<String?> get password => storage.read(key: 'password');

  set password(String? password) {
    storage.write(key: 'password', value: password);
  }
}
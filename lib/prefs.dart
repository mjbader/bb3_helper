import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Prefs {
  static final Prefs instance = Prefs();

  final storage = FlutterSecureStorage();

  Future<String?> get username => storage.read(key: 'admin_username');

  set username(String? newUsername) {
    storage.write(key: 'admin_username', value: newUsername);
  }

  Future<String?> get password => storage.read(key: 'password');

  set password(String? newPassword) {
    storage.write(key: 'password', value: newPassword);
  }
}
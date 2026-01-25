import 'package:bb3_helper/prefs.dart';
import 'package:bb3_helper/services/admin_website_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _saveLogin = false;
  bool _loggingIn = false;
  bool _loginFailure = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(54.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Blood Bowl 3 Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: .center,
              children: [
                Checkbox(
                  value: _saveLogin,
                  onChanged: (bool? value) {
                    setState(() {
                      _saveLogin = value ?? false;
                    });
                  },
                ),
                Text('Save login data'),
              ],
            ),
            SizedBox(height: 30),
            if (_loginFailure)
              Text(
                'Login Failed',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _loggingIn = true;
                    _loginFailure = false;
                  });
                  bool success = await AdminWebsiteService.instance.login(usernameController.text, passwordController.text);
                  if (success) {
                    if (_saveLogin) {
                      Prefs.instance.username = usernameController.text;
                      Prefs.instance.password = passwordController.text;
                    }
                    if (context.mounted) {
                      context.go('/leagues');
                    }
                  } else {
                    setState(() {
                      _loginFailure = true;
                    });
                  }
                  setState(() {
                    _loggingIn = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _loggingIn ? CircularProgressIndicator() : Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
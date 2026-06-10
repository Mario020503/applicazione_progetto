import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
<<<<<<< HEAD
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzed_buddy/screens/splash_page.dart';
import 'package:buzzed_buddy/screens/register_page.dart';


// LOGIN SCREEN — Schermata di accesso per utenti già registrati.
// Viene mostrata quando:
//   - L'utente ha un account salvato ma isUserLogged è false
//   - L'utente ha fatto logout
//
// Verifica username con Provider e password con SharedPreferences.
// La password NON vive nel Provider per motivi di sicurezza.


=======
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/splash_page.dart';
import 'package:buzzed_buddy/screens/registerf_page.dart';
 
>>>>>>> 306e06eafbed07d0e6b4835e46da1e1c11796a74
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
 
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
 
  Future<String> _getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password') ?? '';
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("Welcome back!"),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
 
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                  hintText: 'Enter your username',
                ),
              ),
            ),
 
            SizedBox(height: 15),
 
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                obscureText: true,
                controller: passwordController,
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
              ),
            ),
 
            SizedBox(height: 30),
 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Color.fromARGB(255, 255, 196, 0),
                minimumSize: Size(250, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final savedPassword = await _getPassword();
 
                if (usernameController.text == userProvider.username &&
                    passwordController.text == savedPassword) {
                  await userProvider.login();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SplashScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('Incorrect username or password')),
                    );
                }
              },
              child: Text(
                'LOG IN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
 
            SizedBox(height: 15),
 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Color.fromARGB(255, 255, 196, 0),
                minimumSize: Size(250, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                );
              },
              child: Text(
                'SIGN UP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
 
          ],
        ),
      ),
    );
  }
}
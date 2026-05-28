import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/schermata_iniziale.dart';
import 'package:buzzed_buddy/screens/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("BENTORNATO!"),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
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
                  labelText: 'Nome utente',
                  hintText: 'Inserisci il tuo nome utente',
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
                  hintText: 'Inserisci la tua password',
                ),
              ),
            ),

            SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.yellow,
                minimumSize: Size(250, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);

                if (usernameController.text == userProvider.username &&
                    passwordController.text == (await _getPassword())) {
                  await userProvider.login();

                  if (!mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SchermataIniziale()),
                  );
                } else {
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('Nome utente o password errati')),
                    );
                }
              },
              child: Text(
                'ACCEDI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 15),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.yellow,
                minimumSize: Size(250, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterPage()),
                );
              },
              child: Text(
                'REGISTRATI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

          ],
        ),
      ),
    );
  }

  // La password rimane su SharedPreferences per sicurezza
  // e non viene mai esposta nel Provider
  Future<String> _getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password') ?? '';
  }
}
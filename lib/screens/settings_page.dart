import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/registerf_page.dart';
import 'package:buzzed_buddy/screens/loginf_page.dart';
import 'package:buzzed_buddy/screens/home_page.dart';
 
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
 
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
 
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color.fromARGB(255, 255, 196, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
 
            Image.asset(
              'assets/images/LogoBB.png',
              fit: BoxFit.contain,
            ),

            if (user.username != null)
              Text(
                "Welcome back, ${user.username}!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
 
            SizedBox(height: 40),
 
            FilledButton(
              onPressed: () {
                if (user.username != null) {
                  // LET'S GO → HomePage (con drawer per Calendar e Settings)

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomePage()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Color.fromARGB(255, 255, 196, 0),
                minimumSize: Size(320, 90),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                user.username != null ? "LET'S GO" : "SIGN UP",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            // Chi ha gia' un account ma non e' ricordato (per esempio dopo aver
            // chiuso l'app sul login) deve poter raggiungere il login dalla
            // splash, non solo la registrazione.
            if (user.username == null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'I already have an account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
 
          ],
        ),
      ),
    );
  }
}

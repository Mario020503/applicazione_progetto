import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/screens/provider_page.dart';
import 'package:buzzed_buddy/screens/registerf_page.dart';


// SPLASH SCREEN — Prima schermata che l'utente vede.
// Si comporta in modo adattivo:
//   - Utente non registrato → mostra SIGN UP → RegisterScreen
//   - Utente registrato     → mostra INIZIAMO → HRVScreen 
// INIZIAMO con la navigazione verso HRVScreen.


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Legge i dati dell'utente dalla bacheca centrale (Provider)
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

            // Logo dell'app 
            Image.asset(
              'assets/images/LogoBB.png',
              width: 600,
              height: 450,
            ),

            // Saluto adattivo: nome utente se registrato, nome app altrimenti
            Text(
              user.username != null
                  ? "Welcome back, ${user.username}!"
                  : "BuzzedBuddy",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 40),

            // Pulsante adattivo, SIGN UP per nuovi utenti, LET'S GO per registrati
            ElevatedButton(
              onPressed: () {
                if (user.username != null) {
                 
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => HRVScreen()));
                } else {
                  // Nuovo utente → schermata di registrazione
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Color.fromARGB(255, 255, 196, 0),
                minimumSize: Size(300, 80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                user.username != null ? "LET'S GO" : "SIGN UP",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

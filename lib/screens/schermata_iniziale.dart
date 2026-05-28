import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/register_page.dart';

class SchermataIniziale extends StatelessWidget {
  const SchermataIniziale({super.key});

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
              width: 600,
              height: 450,
            ),

            Text(
              user.username != null
                  ? "Bentornato, ${user.username}!"
                  : "BuzzedBuddy",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (user.username != null) {
                  // utente registrato → vai alla prossima schermata (HRV)
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => HRVScreen()));
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.yellow,
                minimumSize: Size(300, 80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                user.username != null ? "INIZIAMO" : "SIGN UP",
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/providers/storico_provider.dart';
import 'package:buzzed_buddy/screens/splash_page.dart';
import 'package:buzzed_buddy/screens/registerf_page.dart';
import 'package:buzzed_buddy/widgets/small_app_logo.dart';
 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen> {
 
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: const Text("Welcome back!"),
        backgroundColor: const Color.fromARGB(255, 255, 196, 0),
        elevation: 0,
        actions: const [SmallAppLogo()],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                  hintText: 'Enter your username',
                ),
              ),
            ),
 
            const SizedBox(height: 15),
 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                obscureText: true,
                controller: passwordController,
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
              ),
            ),
 
            const SizedBox(height: 30),
 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: const Color.fromARGB(255, 255, 196, 0),
                minimumSize: const Size(250, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final storicoProvider = Provider.of<StoricoProvider>(context, listen: false);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final username = usernameController.text.trim();
                final password = passwordController.text;
 
                // MODIFICA DI SICUREZZA: Pulisce preventivamente lo storico in memoria RAM 
                // per evitare che tracce del vecchio utente rimangano visibili se il login fallisce.
                await storicoProvider.clear();

                final authenticated = await userProvider.authenticate(username, password);

                if (authenticated) {
                  // Carica il diario specifico usando l'accountId appena validato (ritorna la stringa privata)
                  await storicoProvider.loadForAccount(userProvider.accountId);
                  if (!navigator.mounted) return;
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                  );
                } else {
                  // Se l'autenticazione fallisce, ci assicuriamo che lo storico rimanga blindato e vuoto
                  await storicoProvider.clear();
                  
                  messenger
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Incorrect username or password')),
                    );
                }
              },
              child: const Text(
                'LOG IN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
 
            const SizedBox(height: 15),
 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: const Color.fromARGB(255, 255, 196, 0),
                minimumSize: const Size(250, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text(
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
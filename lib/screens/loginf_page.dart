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
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("Welcome back!"),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
        elevation: 0,
        actions: const [SmallAppLogo()],
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
                final storicoProvider = Provider.of<StoricoProvider>(context, listen: false);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final username = usernameController.text.trim();
                final password = passwordController.text;
 
                final authenticated = await userProvider.authenticate(username, password);

                if (authenticated) {
                  await storicoProvider.loadForAccount(userProvider.accountId);
                  if (!mounted) return;
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => SplashScreen()),
                  );
                } else {
                  messenger
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Incorrect username or password')),
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
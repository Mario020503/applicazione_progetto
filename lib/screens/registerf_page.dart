import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
<<<<<<< HEAD
import 'package:buzzed_buddy/screens/provider_page.dart';
import 'package:buzzed_buddy/screens/loginf_page.dart';


// REGISTER SCREEN — Schermata di registrazione, eseguita una sola volta.
// Raccoglie i dati minimi necessari per il funzionamento dell'app:
//   - Nome reale, usato nel messaggio di emergenza
//   - Username, usato nel saluto e nel login
//   - Password, login
//   - Peso in kg 
//   - Sesso M/F
// Chiede anche il permesso GPS durante la registrazione,
// quando l'utente è sobrio e può dare un consenso informato.


=======
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/loginf_page.dart';
 
>>>>>>> 306e06eafbed07d0e6b4835e46da1e1c11796a74
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
 
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends State<RegisterScreen> {
 
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool termsAccepted = false;
 
  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Terms of Service'),
          content: SingleChildScrollView(
            child: Text(
              'By accepting these terms, you agree to:\n\n'
              '1. Provide accurate personal information\n'
              '2. Use this app without replacing medical advice\n'
              '3. Not share your data with third parties\n'
              '4. Keep your password secure\n'
              '5. Open the app BEFORE you start drinking for accurate BAC tracking\n'
              '6. Allow location access to be used in case of emergency\n\n'
              'For more information, contact us at buzzedbuddy@gmail.com.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Decline'),
            ),
            TextButton(
              onPressed: () {
                setState(() => termsAccepted = true);
                Navigator.pop(context);
              },
              child: Text('Accept'),
            ),
          ],
        );
      },
    );
  }
 
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("Create your account"),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
 
              _field(nameController, 'Full name', 'Enter your real name'),
              _field(usernameController, 'Username', 'Choose a username'),
              _field(weightController, 'Weight (kg)', 'Enter your weight', numbersOnly: true),
              _field(genderController, 'Sex', 'M or F'),
              _field(passwordController, 'Password', 'Choose a password', obscure: true),
              _field(confirmPasswordController, 'Confirm password', 'Repeat your password', obscure: true),
 
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showTerms(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: termsAccepted ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: termsAccepted ? Colors.green : Colors.white,
                        ),
                        child: termsAccepted
                            ? Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTerms(context),
                        child: Text(
                          'I accept the Terms of Service',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
 
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
                  if (nameController.text.isEmpty ||
                      usernameController.text.isEmpty ||
                      weightController.text.isEmpty ||
                      genderController.text.isEmpty ||
                      passwordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Please fill in all fields')));
                    return;
                  }
                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Passwords do not match')));
                    return;
                  }
                  final sesso = genderController.text.toUpperCase();
                  if (sesso != 'M' && sesso != 'F') {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Sex must be M or F')));
                    return;
                  }
                  if (!termsAccepted) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('You must accept the Terms of Service')));
                    return;
                  }
 
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  await userProvider.saveUser(
                    username: usernameController.text,
                    password: passwordController.text,
                    name: nameController.text,
                    gender: sesso,
                    weight: double.parse(weightController.text),
                  );
 
                  await _requestLocationPermission();
 
                  if (!mounted) return;
 
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text('Account created! Please log in.')));
 
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                child: Text(
                  'SIGN UP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
 
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _field(TextEditingController controller, String label, String hint,
      {bool obscure = false, bool numbersOnly = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: obscure
            ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
            : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}

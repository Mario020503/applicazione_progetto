import 'package:flutter/material.dart';
import 'package:applicazione_progetto/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("Registration"),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                    hintText: 'Enter your name'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: surnameController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Surname',
                    hintText: 'Enter your surname'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: usernameController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    hintText: 'Enter your username'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Age',
                    hintText: 'Enter your age'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: genderController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Gender',
                    hintText: 'M/F'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Height (cm)',
                    hintText: 'Enter your height'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Weight (kg)',
                    hintText: 'Enter your weight'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    hintText: 'Enter your email'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                obscureText: true,
                controller: passwordController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter your password'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                obscureText: true,
                controller: confirmPasswordController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 20, bottom: 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Service Terms'),
                            content: SingleChildScrollView(
                              child: Text(
                                'By reading and accepting these terms, you agree to:\n\n'
                                '1. Provide accurate personal information\n'
                                '2. Use the app without replacing medical judgment\n'
                                '3. Not share your data with third parties\n'
                                '4. Protect your password\n'
                                '5. Accept the privacy policy\n\n'
                                'For more details, contact us at buzzedbuddy@gmail.com.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // Rifiuta le condizioni
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                      context, MaterialPageRoute(builder: (_) => LoginPage()));
                                },
                                child: Text('Reject'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Accetta le condizioni
                                  setState(() {
                                    termsAccepted = true;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text('Accept'),
                              ),
                            ],
                          );
                        },
                      );
                    },
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
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Service Terms'),
                              content: SingleChildScrollView(
                                child: Text(
                                  'By reading and accepting these terms, you agree to:\n\n'
                                  '1. Provide accurate personal information\n'
                                  '2. Use the app without replacing medical judgment\n'
                                  '3. Not share your data with third parties\n'
                                  '4. Protect your password\n'
                                  '5. Accept the privacy policy\n\n'
                                  'For more details, contact us at buzzedbuddy@gmail.com.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Rifiuta le condizioni
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                        context, MaterialPageRoute(builder: (_) => LoginPage()));
                                  },
                                  child: Text('Reject'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Accetta le condizioni
                                    setState(() {
                                      termsAccepted = true;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text('Accept'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        'Accept the terms and conditions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 255, 196, 0),
                ),
                onPressed: () async {
                  // Validazione campi vuoti
                  if (nameController.text.isEmpty ||
                      surnameController.text.isEmpty ||
                      usernameController.text.isEmpty ||
                      ageController.text.isEmpty ||
                      genderController.text.isEmpty ||
                      heightController.text.isEmpty ||
                      weightController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      passwordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Compila tutti i campi')));
                    return;
                  }

                  // Validazione password uguali
                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Le password non corrispondono')));
                    return;
                  }

                  // Validazione condizioni
                  if (!termsAccepted) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Devi accettare le condizioni per registrarti')));
                    return;
                  }

                  // Validazione età
                  if(int.parse(ageController.text) < 18){
                    showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Service Terms'),
                                content: SingleChildScrollView(
                                  child: Text(
                                    'Anche se sei minorenne puoi lo stesso utilizzare l\'app! \n ma ricorda che è importante bere responsabilmente e seguire sempre le linee guida per un consumo sicuro.',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      // Accetta le condizioni
                                      setState(() {
                                        termsAccepted = true;
                                      }
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: Text('Ne sono consapevole '),
                                  ),
                                ]);
                            },
                    );
                  }                         

                  final currentContext = context;
                  // Registrazione avvenuta con successo - Salva credenziali
                  final sharedPreferences = await SharedPreferences.getInstance();
                  await sharedPreferences.setString('username', usernameController.text);
                  await sharedPreferences.setString('password', passwordController.text);
                  await sharedPreferences.setString('name', nameController.text);
                  await sharedPreferences.setString('surname', surnameController.text);
                  await sharedPreferences.setString('age', ageController.text);
                  await sharedPreferences.setString('gender', genderController.text);
                  await sharedPreferences.setString('height', heightController.text);
                  await sharedPreferences.setString('weight', weightController.text);
                  await sharedPreferences.setString('email', emailController.text);
                  await sharedPreferences.setString('password', passwordController.text);
                 
                  if (!currentContext.mounted) return;

                  // Torna alla login
                  Navigator.pushReplacement(
                      currentContext, MaterialPageRoute(builder: (_) => LoginPage()));
                },
                child: Text('Registrati'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'package:buzzed_buddy/screens/home_page.dart';
import 'package:buzzed_buddy/screens/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}//LoginPage

class _LoginPageState extends State<LoginPage> {

  TextEditingController userController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("BENVENUTO!"),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: userController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Nome utente',
                    hintText: 'Enter username'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: 
              TextField(
                obscureText: true,
                controller: passwordController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter password'),
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 255, 196, 0),
                ),
                onPressed: () async{
                  final currentContext = context;
                  //Get the instance of SharedPreferences
                  final sharedPreferences = await SharedPreferences.getInstance();
                  //Get saved username and password
                  final savedUsername = sharedPreferences.getString('username') ?? '';
                  final savedPassword = sharedPreferences.getString('password') ?? '';
                  
                  //Check user's credentials...
                  if(userController.text == savedUsername && passwordController.text == savedPassword){
                    //...if they are correct set the isUserLogged flag
                    await sharedPreferences.setBool('isUserLogged', true);
                    //Save the logged in username
                    await sharedPreferences.setString('loggedUsername', userController.text);

                    if (!currentContext.mounted) return;

                    //Finally, navigate to HomePage
                    Navigator.pushReplacement(
                        currentContext, MaterialPageRoute(builder: (_) => HomePage()));
                  }//if
                  else{
                    if (!currentContext.mounted) return;
                    //If the credentials are not correct, say it!
                    ScaffoldMessenger.of(currentContext)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text('Nome utente o password errati')));
                  }//else
                },
                child: Text(
                  'Accedi',
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 255, 196, 0),
                ),
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()));
                },
                child: Text('Registrati'),
              ),
            ),
          ],
        ),
      ),
    );
  }//build
}//_LoginPageState
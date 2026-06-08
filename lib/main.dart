import 'package:flutter/material.dart';
import 'package:applicazione_progetto/screens/home_page.dart';
import 'package:applicazione_progetto/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
// import 'package:applicazione_progetto/providers/user_provider.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inizializza i dati per la lingua italiana in modo asincrono
  await initializeDateFormatting('it_IT', null);
  // Imposta il locale predefinito per tutta l'applicazione
  Intl.defaultLocale = 'it_IT';
  
  runApp(MyApp());
} //main

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //Now the home becomes a FutureBuilder: we need to wait for the instance of SharedPreferences
      home: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          //If the instance is ready...
          if (snapshot.hasData) {
            //...get the instance
            final sharedPreferences = snapshot.data!;
            //Check if the flag isUserLogged exist...
            if (sharedPreferences.getBool('isUserLogged') != null) {
              //..if so, go directly to HomePage
              return HomePage();
            } //if
            else {
              //...otherwise go to LoginPage
              return LoginPage();
            } //else
          } //if
          else {
            //While the instance of SharedPreferences is loading, just show a CircularProgress indicator in the Center
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } //else
        },
      ),
    );
  } //build

} //MyApp
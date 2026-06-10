import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/login_screen.dart';
import 'package:buzzed_buddy/screens/splash_screen.dart';
 
// ============================================================
// MAIN — Flusso completo con bypass HRVScreen per test.
//
// Flusso:
//   isUserLogged == false → LoginScreen (→ RegisterScreen se necessario)
//   isUserLogged == true  → SplashScreen → LET'S GO → SessionScreen
//
// TODO: quando HRVScreen sarà pronta, aggiornare splash_screen.dart
// per navigare verso HRVScreen invece di SessionScreen.
// ============================================================
 
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MyApp(),
    ),
  );
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuzzedBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 255, 196, 0),
        ),
        useMaterial3: true,
      ),
      home: AppEntry(),
    );
  }
}
 
// Widget separato per poter usare il Provider dopo che è stato creato
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});
 
  @override
  State<AppEntry> createState() => _AppEntryState();
}
 
class _AppEntryState extends State<AppEntry> {
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _loadUser();
  }
 
  // Carica i dati salvati da SharedPreferences prima di decidere la schermata
  Future<void> _loadUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadFromSharedPreferences();
    setState(() => _loading = false);
  }
 
  @override
  Widget build(BuildContext context) {
    // Mostra un indicatore di caricamento mentre legge SharedPreferences
    if (_loading) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }
 
    final user = Provider.of<UserProvider>(context);
 
    // Utente loggato → SessionScreen diretta (modalità test)
    // Utente non loggato → LoginScreen (da cui si raggiunge RegisterScreen)
    if (user.isUserLogged) {
      return SplashScreen();
    } else {
      return LoginScreen();
    }
  }
}
 
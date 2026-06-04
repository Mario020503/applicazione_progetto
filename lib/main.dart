import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/login_screen.dart';
import 'package:buzzed_buddy/screens/session_screen.dart';
 

// MAIN — Versione di test per sviluppo.
// Bypassa SplashScreen e HRVScreen e va direttamente a SessionScreen.
// Flusso:
//   isUserLogged == false → LoginScreen (→ RegisterScreen se necessario)
//   isUserLogged == true  → SessionScreen (bypass completo)
// sostituire SessionScreen con SplashScreen nel MaterialApp home.

 
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
      return SessionScreen();
    } else {
      return LoginScreen();
    }
  }
}
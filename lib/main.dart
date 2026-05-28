import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/schermata_iniziale.dart';
import 'package:buzzed_buddy/screens/login_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
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
      home: const AppLoader(),
    );
  }
}

// Schermata di caricamento iniziale — legge i dati salvati e decide dove andare
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.caricaDaSharedPreferences();

    if (!mounted) return;

    if (userProvider.isUserLogged && userProvider.username != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SchermataIniziale()),
      );
    } else if (userProvider.username != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SchermataIniziale()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
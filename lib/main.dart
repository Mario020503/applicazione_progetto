import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/providers/storico_provider.dart';
import 'package:buzzed_buddy/screens/splash_page.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_GB', null);
  Intl.defaultLocale = 'en_GB';
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => StoricoProvider()),
      ],
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
 
// Widget separato per usare il Provider dopo la sua creazione
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
    _init();
  }
 
  Future<void> _init() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final storicoProvider = Provider.of<StoricoProvider>(context, listen: false);
    await userProvider.loadFromSharedPreferences();
    await storicoProvider.caricaStorico();
    setState(() => _loading = false);
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    // La SplashScreen è SEMPRE la prima schermata e si adatta da sola:
    //  - Ha un account  → "Welcome back, username!" + LET'S GO → HomePage
    //                     (nessun login: l'app ti ricorda)
    //  - Nuovo utente   → "BuzzedBuddy" + SIGN UP → registrazione
    return SplashScreen();
  }
}

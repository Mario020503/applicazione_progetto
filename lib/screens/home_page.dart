import 'package:flutter/material.dart';

import 'package:applicazione_progetto/screens/calendar_page.dart';
import 'package:applicazione_progetto/screens/login_page.dart';
import 'package:applicazione_progetto/screens/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String loggedUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      loggedUsername = sharedPreferences.getString('loggedUsername') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text('Principale'),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Benvenuto $loggedUsername',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 50),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  // Aggiungi la logica per il pulsante "Iniziamo"
                  // Vai alla pagina drink-serata
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text('Benvenuto nell\'app!')));
                },
                child: Text(
                  'Iniziamo',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text('Impostazioni e attività'),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Principale'),
              onTap: () {
                _toHomePage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Calendario'),
              onTap: () {
                _toCalendarPage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Impostazioni'),
              onTap: () {
                _toSettingsPage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Esci'),
              onTap: () {
                _toLoginPage(context);
              },
            ),
          ],
        ),
      ),
    );
  } //build

  void _toHomePage(BuildContext context) {
    Navigator.pop(context);
  }

  void _toCalendarPage(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CalendarPage()));
  }

  void _toSettingsPage(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsPage()));
  }

  void _toLoginPage(BuildContext context) async{
    final currentContext = context;
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove('isUserLogged');

    if (!currentContext.mounted) return;

    Navigator.pop(currentContext);
    Navigator.of(currentContext).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }

} //HomePage
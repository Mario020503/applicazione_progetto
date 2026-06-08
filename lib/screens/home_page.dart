import 'package:flutter/material.dart';

import 'package:applicazione_progetto/screens/calendar_page.dart';
import 'package:applicazione_progetto/screens/login_page.dart';
import 'package:applicazione_progetto/screens/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
        title: Text('Home'),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome $loggedUsername',
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
                  // Va alla pagina drink-serata
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text('Welcome in BuzzedBuddy !')));
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
              child: Text('Settings and activities'),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                _toHomePage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Calendar'),
              onTap: () {
                _toCalendarPage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                _toSettingsPage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
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

 //This method allows to check if the IMPACT backend is up
  Future<bool> _isImpactUp() async {

    //Create the request
    final url = Impact.baseUrl + Impact.pingEndpoint;

    //Get the response
    print('Calling: $url');
    final response = await http.get(Uri.parse(url));

    //Just return if the status code is OK
    return response.statusCode == 200;
  } //_isImpactUp



} //HomePage
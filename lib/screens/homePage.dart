import 'package:flutter/material.dart';

import 'package:applicazione_progetto/screens/loginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
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
        title: Text('HomePage'),
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
              onTap: () => _tohomePage(context);
              Navigator.pop(context); // Chiudi il drawer
              
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Calendario'),
              onTap: () => _toCalendarPage(context),
              Navigator.pop(context), // Chiudi il drawer
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Imopostazioni'),
              onTap: () => _toSettingsPage(context),
              Navigator.pop(context), // Chiudi il drawer
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Esci'),
              onTap: () => _toLoginPage(context),
              Navigator.pop(context), // Chiudi il drawer
            ),
          ],
        ),
      ),
    );
  } //build

  void _toLoginPage(BuildContext context) async{
    //Get the instance and remove isUserLogged flag from shared preferences 
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove('isUserLogged');

    //Pop the drawer first 
    Navigator.pop(context);
    //Then pop the HomePage
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }//_toCalendarPage

} //HomePage
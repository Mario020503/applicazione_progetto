<<<<<<< HEAD
<<<<<<< HEAD
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pagina Impostazioni',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Torna indietro'),
            ),
          ],
        ),
      ),
    );
  }
}
=======
import 'package:flutter/material.dart';

import 'package:applicazione_progetto/screens/calendarPage.dart';
import 'package:applicazione_progetto/screens/loginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pagina Impostazioni',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Torna indietro'),
            ),
          ],
        ),
      ),
    );
  }
}
>>>>>>> cdb9ab15415b51189d03dde12caeab8006053f3a
=======
import 'package:flutter/material.dart';

import 'package:applicazione_progetto/screens/calendarPage.dart';
import 'package:applicazione_progetto/screens/loginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pagina Impostazioni',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Torna indietro'),
            ),
          ],
        ),
      ),
    );
  }
}
>>>>>>> 6abb5990412550ed17cd46b4233ddd5fcf22b0e5

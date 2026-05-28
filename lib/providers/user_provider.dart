import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {

  String? username;
  String? sesso;
  double? peso;
  double? altezza;
  int? eta;
  bool isUserLogged = false;

  // Chiamato all'avvio dell'app — carica i dati salvati da SharedPreferences
  Future<void> caricaDaSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
    sesso = prefs.getString('sesso');
    peso = double.tryParse(prefs.getString('peso') ?? '');
    altezza = double.tryParse(prefs.getString('altezza') ?? '');
    eta = int.tryParse(prefs.getString('eta') ?? '');
    isUserLogged = prefs.getBool('isUserLogged') ?? false;
    notifyListeners();
  }

  // Chiamato dalla RegisterPage — salva i dati in memoria e su disco
  Future<void> salvaUtente({
    required String username,
    required String password,
    required String sesso,
    required double peso,
    required double altezza,
    required int eta,
  }) async {
    this.username = username;
    this.sesso = sesso;
    this.peso = peso;
    this.altezza = altezza;
    this.eta = eta;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('sesso', sesso);
    await prefs.setString('peso', peso.toString());
    await prefs.setString('altezza', altezza.toString());
    await prefs.setString('eta', eta.toString());

    notifyListeners();
  }

  // Chiamato dalla LoginPage — imposta il flag di sessione
  Future<void> login() async {
    isUserLogged = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLogged', true);
    notifyListeners();
  }

  // Chiamato dal logout — rimuove solo il flag di sessione
  Future<void> logout() async {
    isUserLogged = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isUserLogged');
    notifyListeners();
  }
}
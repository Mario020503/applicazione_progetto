import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


// SHARED PREFERENCES KEYS, non cambiano
// Usate sempre queste key in ogni schermo che le chiami.
//
// 'username'          → l'username scelto con cui l'app ti saluta
// 'password'          → la password del login
// 'nomeReale'         → il nome vero, usato nel messaggio di emergenza 
// 'peso'              → il peso in kg, usato per la formula del BAC 
// 'sesso'             → sesso M o F, usato sempre per la formula del BAC
// 'isUserLogged'      → vero dopo il login
// 'nomeContatto'      → il nome del contatto, servirà lo screen pre- sessione, ancora non esiste
// 'telefonoContatto'  → il cellulare del contatto, idem con patate
// 'livelloStress'     → il livello di stress, necessario perchè penso possa essere utile per modificare il calcolo del BAC, aggiungendo dei coefficienti "punitivi" nel caso in cui si inizi la sessione con stress alto. Verrà preso dalla home page


class UserProvider extends ChangeNotifier {

  // User data — set during registration
  String? username;
  String? nomeReale;
  String? sesso;
  double? peso;
  bool isUserLogged = false;

  // contatto di emergenza, nullo fino a che non esiste lo schermo dedicato
  String? nomeContatto;
  String? telefonoContatto;

  // livello di stress, grafico dell'HRV/stress
  // Cambia i "limiti" nello schermo della sessione
  // 'normale' → arancione a 0.5, rosso a 1.5
  // 'alto'   → arancione a 0.3, rosso a 1.2
  String livelloStress = 'normal';

  // Carica tutti i dati salvati in SharedPreference 
  Future<void> loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
    nomeReale = prefs.getString('nomeReale');
    sesso = prefs.getString('sesso');
    peso = double.tryParse(prefs.getString('peso') ?? '');
    isUserLogged = prefs.getBool('isUserLogged') ?? false;
    nomeContatto = prefs.getString('nomeContatto');
    telefonoContatto = prefs.getString('telefonoContatto');
    livelloStress = prefs.getString('livelloStress') ?? 'normal';
    notifyListeners();
  }

  // Chiamata dalla registrazione, salva tutti i dati nella memoria
  Future<void> saveUser({
    required String username,
    required String password,
    required String nomeReale,
    required String sesso,
    required double peso,
  }) async {
    this.username = username;
    this.nomeReale = nomeReale;
    this.sesso = sesso;
    this.peso = peso;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('nomeReale', nomeReale);
    await prefs.setString('sesso', sesso);
    await prefs.setString('peso', peso.toString());

    notifyListeners();
  }

  // Chiamata dal login, nel caso in cui il controllo delle credenziali sia andato a buon fine
  Future<void> login() async {
    isUserLogged = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLogged', true);
    notifyListeners();
  }

  // Chiamato nel caso di logout nella pagina del profilo, io la metto qui, Paola se vuoi levartela dalle palle fai pure 
  Future<void> logout() async {
    isUserLogged = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isUserLogged');
    notifyListeners();
  }

  // Salva il contatto, nome e numero 
  Future<void> saveEmergencyContact({
    required String nome,
    required String telefono,
  }) async {
    nomeContatto = nome;
    telefonoContatto = telefono;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nomeContatto', nome);
    await prefs.setString('telefonoContatto', telefono);
    notifyListeners();
  }

  // Salva il livello dello stress, come sempre io la metto qui, poi voi fate quello che vi pare
  Future<void> saveStressLevel(String level) async {
    livelloStress = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('livelloStress', level);
    notifyListeners();
  }
}
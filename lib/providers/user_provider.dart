import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


// SHARED PREFERENCES KEYS
// Usiamo sempre e solo queste 
//
// 'username'                 → l'username scelto con cui l'app ti saluta
// 'password'                 → la password del login
// 'name'                     → il nome vero, usato nel messaggio di emergenza 
// 'weight'                   → il peso in kg, usato per la formula del BAC 
// 'gender'                   → sesso M o F, usato sempre per la formula del BAC
// 'isUserLogged'             → vero dopo il login
// 'EmergenciesContactName'   → il nome del contatto, servirà lo screen pre- sessione, ancora non esiste
// 'EmergenciesContactPhone'  → il cellulare del contatto, idem con patate
// 'StressLevel'              → il livello di stress, necessario perchè penso possa essere utile per modificare il calcolo del BAC, aggiungendo dei coefficienti "punitivi" nel caso in cui si inizi la sessione con stress alto. Verrà preso dalla home page


class UserProvider extends ChangeNotifier {

  //I dati dello user
  String? username;
  String? name;
  String? gender;
  double? weight;
  bool isUserLogged = false;

  // contatto di emergenza, nullo fino a che non esiste lo schermo dedicato
  String? emergenciesContactName;
  String? emergenciesContactPhone;

  // livello di stress, grafico dell'HRV/stress
  // Cambia i "limiti" nello schermo della sessione
  // 'normale' → arancione a 0.5, rosso a 1.5
  // 'alto'   → arancione a 0.3, rosso a 1.2
  String stressLevel = 'normal';

  // Carica tutti i dati salvati in SharedPreference 
  Future<void> loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
    name = prefs.getString('name');
    gender = prefs.getString('gender');
    weight = double.tryParse(prefs.getString('weight') ?? '');
    isUserLogged = prefs.getBool('isUserLogged') ?? false;
    emergenciesContactName = prefs.getString('EmergenciesContactName');
    emergenciesContactPhone = prefs.getString('EmergenciesContactPhone');
    stressLevel = prefs.getString('StressLevel') ?? 'normal';
    notifyListeners();
  }

  // Chiamata dalla registrazione, salva tutti i dati nella memoria
  Future<void> saveUser({
    required String username,
    required String password,
    required String name,
    required String gender,
    required double weight,
  }) async {
    this.username = username;
    this.name = name;
    this.gender = gender;
    this.weight = weight;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('name', name);
    await prefs.setString('gender', gender);
    await prefs.setString('weight', weight.toString());

    notifyListeners();
  }

  Future<String> getPassword() async {
    isUserLogged = true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password') ?? '';

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
    required String emergencyContactName,
    required String emergenciesContactPhone,
  }) async {
    emergenciesContactName = emergencyContactName;
    emergenciesContactPhone = emergenciesContactPhone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('EmergenciesContactName', emergencyContactName);
    await prefs.setString('EmergenciesContactPhone', emergenciesContactPhone);
    notifyListeners();
  }

  // Salva il livello dello stress, come sempre io la metto qui, poi voi fate quello che vi pare
  Future<void> saveStressLevel(String level) async {
    stressLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('StressLevel', level);
    notifyListeners();
  }
}
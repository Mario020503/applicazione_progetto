import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
 

// SHARED PREFERENCES KEYS
// Usiamo sempre e solo queste 
//
// 'username'          → username scelto 
// 'password'          → login password
// 'name'              → per messaggio d'emergenza
// 'weight'            → formula del BAC 
// 'gender'            → idem con patate 
// 'isUserLogged'      → vero dopo il login
// 'nomeContatto'      → per l'emergenza
// 'telefonoContatto'  → idem
// 'livelloStress'     → nel nome, deciderà se viene applicato il coefficiente o meno 
// aggiungi isMinor, per quello di cui abbiamo parlato su WA

 
class UserProvider extends ChangeNotifier {
 
  String? username;
  String? name;
  String? gender;
  double? weight;
  bool isUserLogged = false;
 
  String? nomeContatto;
  String? telefonoContatto;
 
  // 'normal' → arancione a 0.5, rosso a 1.5
  // 'high'   → arancione a 0.3, rosso a 1.2
  String livelloStress = 'normal';
 
  Future<void> loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
    name = prefs.getString('name');
    gender = prefs.getString('gender');
    weight = double.tryParse(prefs.getString('weight') ?? '');
    isUserLogged = prefs.getBool('isUserLogged') ?? false;
    nomeContatto = prefs.getString('nomeContatto');
    telefonoContatto = prefs.getString('telefonoContatto');
    livelloStress = prefs.getString('livelloStress') ?? 'normal';
    notifyListeners();
  }
 
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
 
  // Legge la password da SharedPreferences, usato da SettingsPage
  Future<String> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password') ?? '';
  }
 
  Future<void> login() async {
    isUserLogged = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLogged', true);
    notifyListeners();
  }
 
  Future<void> logout() async {
    isUserLogged = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isUserLogged');
    notifyListeners();
  }
 
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
 
  Future<void> saveStressLevel(String level) async {
    livelloStress = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('livelloStress', level);
    notifyListeners();
  }
}
 

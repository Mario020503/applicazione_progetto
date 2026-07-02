import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {

  static const String _usersPrefsKey = 'usersData';
  static const String _currentUsernameKey = 'currentUsername';
 
  String? username;
  String? accountId;
  String? name;
  String? gender;
  double? weight;
  bool isUserLogged = false;
 
  String? nomeContatto;
  String? telefonoContatto;
 
  // 'normal' → arancione a 0.5, rosso a 1.5
  // 'high'   → arancione a 0.3, rosso a 1.2
  String livelloStress = 'normal';

  Map<String, Map<String, dynamic>> _users = {};

  // --- NUOVE VARIABILI PER LA GESTIONE DELLA SESSIONE DEI DRINK ---
  // Memorizza la lista dei drink consumati nella serata corrente
  List<dynamic> currentSessionDrinks = [];

  // Genera la chiave univoca per la persistenza della sessione corrente del singolo utente
  String _sessionKeyForAccount(String id) => 'current_session_${Uri.encodeComponent(id)}';

  String _createAccountId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final nonce = List<int>.generate(8, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'acc_${timestamp}_$nonce';
  }

  Map<String, Map<String, dynamic>> _decodeUsers(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (username, value) => MapEntry(
        username,
        Map<String, dynamic>.from(value as Map),
      ),
    );
  }

  Map<String, dynamic> _buildProfileMap({
    required String username,
    required String password,
    required String name,
    required String gender,
    required double weight,
  }) {
    final existing = _users[username] ?? <String, dynamic>{};
    return {
      ...existing,
      'accountId': existing['accountId'] ?? _createAccountId(),
      'username': username,
      'password': password,
      'name': name,
      'gender': gender,
      'weight': weight,
      'nomeContatto': existing['nomeContatto'],
      'telefonoContatto': existing['telefonoContatto'],
      'livelloStress': existing['livelloStress'] ?? 'normal',
    };
  }

  void _applyProfile(String? username, Map<String, dynamic>? profile) {
    this.username = username;
    if (profile == null) {
      accountId = null;
      name = null;
      gender = null;
      weight = null;
      nomeContatto = null;
      telefonoContatto = null;
      livelloStress = 'normal';
      currentSessionDrinks = []; // Pulisce lo stato dei drink se non c'è profilo
      return;
    }

    accountId = profile['accountId'] as String? ?? username;
    name = profile['name'] as String?;
    gender = profile['gender'] as String?;
    weight = (profile['weight'] is num) ? (profile['weight'] as num).toDouble() : double.tryParse(profile['weight']?.toString() ?? '');
    nomeContatto = profile['nomeContatto'] as String?;
    telefonoContatto = profile['telefonoContatto'] as String?;
    livelloStress = profile['livelloStress'] as String? ?? 'normal';
  }

  Future<void> _persistUsers(SharedPreferences prefs) async {
    await prefs.setString(_usersPrefsKey, jsonEncode(_users));
  }
 
  Future<void> loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final rawUsers = prefs.getString(_usersPrefsKey);
    if (rawUsers != null && rawUsers.isNotEmpty) {
      _users = _decodeUsers(rawUsers);
    } else {
      final legacyUsername = prefs.getString('username');
      final legacyPassword = prefs.getString('password');
      if (legacyUsername != null && legacyPassword != null) {
        _users = {
          legacyUsername: {
            'accountId': legacyUsername,
            'username': legacyUsername,
            'password': legacyPassword,
            'name': prefs.getString('name'),
            'gender': prefs.getString('gender'),
            'weight': double.tryParse(prefs.getString('weight') ?? ''),
            'nomeContatto': prefs.getString('nomeContatto'),
            'telefonoContatto': prefs.getString('telefonoContatto'),
            'livelloStress': prefs.getString('livelloStress') ?? 'normal',
          },
        };
        await _persistUsers(prefs);
      }
    }

    isUserLogged = prefs.getBool('isUserLogged') ?? false;
    final currentUsername = prefs.getString(_currentUsernameKey);
    if (isUserLogged && currentUsername != null) {
      _applyProfile(currentUsername, _users[currentUsername]);
      // CARICAMENTO AUTOMATICO: Recupera la sessione dei drink salvata per questo account
      await loadCurrentSessionIfAny();
    } else {
      _applyProfile(null, null);
    }

    notifyListeners();
  }
 
  Future<void> saveUser({
    required String username,
    required String password,
    required String name,
    required String gender,
    required double weight,
    bool setAsCurrentUser = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isNewProfile = !_users.containsKey(username) || _users[username]?['accountId'] == null;

    _users[username] = _buildProfileMap(
      username: username,
      password: password,
      name: name,
      gender: gender,
      weight: weight,
    );

    await _persistUsers(prefs);

    if (isNewProfile) {
      final accountId = _users[username]?['accountId'] as String?;
      if (accountId != null && accountId.isNotEmpty) {
        await prefs.remove('storicoBevute_${Uri.encodeComponent(accountId)}');
        await prefs.remove(_sessionKeyForAccount(accountId)); // Rimuove eventuali sessioni sporche
      }
    }

    if (setAsCurrentUser) {
      await prefs.setString(_currentUsernameKey, username);
      _applyProfile(username, _users[username]);
      await loadCurrentSessionIfAny(); // Sincronizza la sessione drink
    } else if (this.username == username) {
      _applyProfile(username, _users[username]);
      await loadCurrentSessionIfAny();
    }
 
    notifyListeners();
  }

  Future<bool> authenticate(String username, String password) async {
    final user = _users[username];
    if (user == null) {
      return false;
    }

    if (user['password'] != password) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    isUserLogged = true;
    await prefs.setBool('isUserLogged', true);
    await prefs.setString(_currentUsernameKey, username);
    _applyProfile(username, user);
    
    // Sincronizza i drink dell'utente appena loggato
    await loadCurrentSessionIfAny();
    
    notifyListeners();
    return true;
  }
 
  Future<String> getPassword() async {
    if (username == null) {
      return '';
    }
    return _users[username]?['password'] as String? ?? '';
  }
 
  Future<void> login() async {
    if (username == null) {
      return;
    }
    isUserLogged = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLogged', true);
    await prefs.setString(_currentUsernameKey, username!);
    await loadCurrentSessionIfAny();
    notifyListeners();
  }
 
  Future<void> logout() async {
    isUserLogged = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isUserLogged');
    await prefs.remove(_currentUsernameKey);
    _applyProfile(null, null);
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

    if (username != null) {
      final profile = _users[username!];
      if (profile != null) {
        profile['nomeContatto'] = nome;
        profile['telefonoContatto'] = telefono;
        await _persistUsers(prefs);
      }
    }

    notifyListeners();
  }
 
  Future<void> saveStressLevel(String level) async {
    livelloStress = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('livelloStress', level);

    if (username != null) {
      final profile = _users[username!];
      if (profile != null) {
        profile['livelloStress'] = level;
        await _persistUsers(prefs);
      }
    }

    notifyListeners();
  }

  // --- NUOVI METODI DI LOGICA CORE PER LA PERSISTENZA DEI DRINK ---

  // 1. Carica la sessione corrente dal disco locale (se esiste)
  Future<void> loadCurrentSessionIfAny() async {
    if (accountId == null || accountId!.isEmpty) {
      currentSessionDrinks = [];
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final String key = _sessionKeyForAccount(accountId!);
    final String? rawJson = prefs.getString(key);

    if (rawJson != null && rawJson.isNotEmpty) {
      currentSessionDrinks = jsonDecode(rawJson) as List<dynamic>;
    } else {
      currentSessionDrinks = [];
    }
    notifyListeners();
  }

  // 2. Aggiunge un drink e lo scrive immediatamente su SharedPreferences
  Future<void> addDrinkToSession(dynamic drink) async {
    currentSessionDrinks.add(drink);
    notifyListeners();

    if (accountId != null && accountId!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final String key = _sessionKeyForAccount(accountId!);
      await prefs.setString(key, jsonEncode(currentSessionDrinks));
    }
  }

  // 3. Rimuove un drink specifico e aggiorna SharedPreferences (opzionale, utile per correzioni)
  Future<void> removeDrinkFromSession(int index) async {
    if (index >= 0 && index < currentSessionDrinks.length) {
      currentSessionDrinks.removeAt(index);
      notifyListeners();

      if (accountId != null && accountId!.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final String key = _sessionKeyForAccount(accountId!);
        await prefs.setString(key, jsonEncode(currentSessionDrinks));
      }
    }
  }

  // 4. FUNZIONE CORE "END THE NIGHT": Cancella definitivamente la sessione offline su SharedPreferences
  Future<void> endTheNight() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (accountId != null && accountId!.isNotEmpty) {
      final String key = _sessionKeyForAccount(accountId!);
      await prefs.remove(key); // Distrugge la sessione sul disco fisso
    }

    currentSessionDrinks = []; // Svuota l'array locale in RAM
    notifyListeners();
  }
}
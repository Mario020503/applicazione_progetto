import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
  String? birthDate; 
  bool isUserLogged = false;
 
  String? nomeContatto;
  String? telefonoContatto;
 
 
  String livelloStress = 'normal';

  bool get isMinor {
    if (birthDate == null) return false;
    final b = DateTime.tryParse(birthDate!);
    if (b == null) return false;
    final now = DateTime.now();
    int age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age < 18;
  }

  Map<String, Map<String, dynamic>> _users = {};

 
  List<dynamic> currentSessionDrinks = [];

  
  String _sessionKeyForAccount(String id) => 'current_session_${Uri.encodeComponent(id)}';

  String _createAccountId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final nonce = List<int>.generate(8, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'acc_${timestamp}_$nonce';
  }

 
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
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
    String? password,
    required String name,
    required String gender,
    required double weight,
    String? birthDate,
  }) {
    final existing = _users[username] ?? <String, dynamic>{};
    
    String? passwordHash = existing['password'] as String?;
    String? salt = existing['salt'] as String?;
    if (password != null && password.isNotEmpty) {
      salt = _generateSalt();
      passwordHash = _hashPassword(password, salt);
    }
    return {
      ...existing,
      'accountId': existing['accountId'] ?? _createAccountId(),
      'username': username,
      'password': passwordHash,
      'salt': salt,
      'name': name,
      'gender': gender,
      'weight': weight,
      'birthDate': birthDate ?? existing['birthDate'],
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
      birthDate = null;
      nomeContatto = null;
      telefonoContatto = null;
      livelloStress = 'normal';
      currentSessionDrinks = []; 
      return;
    }

    accountId = profile['accountId'] as String? ?? username;
    name = profile['name'] as String?;
    gender = profile['gender'] as String?;
    weight = (profile['weight'] is num) ? (profile['weight'] as num).toDouble() : double.tryParse(profile['weight']?.toString() ?? '');
    birthDate = profile['birthDate'] as String?;
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
        
        final legacySalt = _generateSalt();
        _users = {
          legacyUsername: {
            'accountId': legacyUsername,
            'username': legacyUsername,
            'password': _hashPassword(legacyPassword, legacySalt),
            'salt': legacySalt,
            'name': prefs.getString('name'),
            'gender': prefs.getString('gender'),
            'weight': double.tryParse(prefs.getString('weight') ?? ''),
            'nomeContatto': prefs.getString('nomeContatto'),
            'telefonoContatto': prefs.getString('telefonoContatto'),
            'livelloStress': prefs.getString('livelloStress') ?? 'normal',
          },
        };
        await _persistUsers(prefs);
        await prefs.remove('password');
      }
    }

    isUserLogged = prefs.getBool('isUserLogged') ?? false;
    final currentUsername = prefs.getString(_currentUsernameKey);
    if (isUserLogged && currentUsername != null) {
      _applyProfile(currentUsername, _users[currentUsername]);
      await loadCurrentSessionIfAny();
    } else {
      _applyProfile(null, null);
    }

    notifyListeners();
  }
 
  
  bool usernameExists(String username) => _users.containsKey(username);

 
  bool matchesCurrentPassword(String password) {
    if (username == null) return false;
    final user = _users[username!];
    if (user == null) return false;
    final salt = user['salt'] as String?;
    final storedHash = user['password'] as String?;
    if (salt == null || storedHash == null) return false;
    return _hashPassword(password, salt) == storedHash;
  }

  Future<void> saveUser({
    required String username,
    String? password,
    required String name,
    required String gender,
    required double weight,
    String? birthDate,
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
      birthDate: birthDate,
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

    final salt = user['salt'] as String?;
    final storedHash = user['password'] as String?;
    if (salt == null || storedHash == null) {
      return false; 
    }
    if (_hashPassword(password, salt) != storedHash) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    isUserLogged = true;
    await prefs.setBool('isUserLogged', true);
    await prefs.setString(_currentUsernameKey, username);
    _applyProfile(username, user);
    
    
    await loadCurrentSessionIfAny();
    
    notifyListeners();
    return true;
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

    
    if (username != null) {
      final prefs = await SharedPreferences.getInstance();
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

    
    if (username != null) {
      final prefs = await SharedPreferences.getInstance();
      final profile = _users[username!];
      if (profile != null) {
        profile['livelloStress'] = level;
        await _persistUsers(prefs);
      }
    }

    notifyListeners();
  }

  
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

  
  Future<void> addDrinkToSession(dynamic drink) async {
    currentSessionDrinks.add(drink);
    notifyListeners();

    if (accountId != null && accountId!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final String key = _sessionKeyForAccount(accountId!);
      await prefs.setString(key, jsonEncode(currentSessionDrinks));
    }
  }

 
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

  Future<void> endTheNight() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (accountId != null && accountId!.isNotEmpty) {
      final String key = _sessionKeyForAccount(accountId!);
      await prefs.remove(key); 
    }

    currentSessionDrinks = []; 
    await _clearEmergencyContact(prefs);

    notifyListeners();
  }

 
  Future<void> _clearEmergencyContact(SharedPreferences prefs) async {
    nomeContatto = null;
    telefonoContatto = null;

    if (username != null) {
      final profile = _users[username!];
      if (profile != null) {
        profile['nomeContatto'] = null;
        profile['telefonoContatto'] = null;
        await _persistUsers(prefs);
      }
    }

    await prefs.remove('nomeContatto');
    await prefs.remove('telefonoContatto');
  }
}

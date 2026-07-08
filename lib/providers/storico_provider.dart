import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoricoProvider extends ChangeNotifier {

  static const String _prefsKey = 'storicoBevute';

  Map<String, double> _storico = {};

  Map<String, double> get storico => Map.unmodifiable(_storico);

  String? _accountId;

 
  String _key() => _accountId == null ? _prefsKey : '${_prefsKey}_$_accountId';

 
  String _chiave(DateTime data) {
    final m = data.month.toString().padLeft(2, '0');
    final g = data.day.toString().padLeft(2, '0');
    return '${data.year}-$m-$g';
  }


  Future<void> salvaSerata(DateTime data, double bac) async {
    if (bac <= 0) return;                 
    final k = _chiave(data);
    final attuale = _storico[k] ?? 0;
    if (bac <= attuale) return;           

    _storico[k] = bac;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(), jsonEncode(_storico));
    notifyListeners();
  }

  
  Future<void> loadForAccount(String? accountId) async {
    _accountId = accountId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key());
    if (raw == null || raw.isEmpty) {
      _storico = {};
    } else {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _storico = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    notifyListeners();
  }


  Future<void> clear() async {
    _accountId = null;
    _storico = {};
    notifyListeners();
  }


  double? bacDelGiorno(DateTime data) => _storico[_chiave(data)];


  bool get bevutoIeri {
    final ieri = DateTime.now().subtract(const Duration(days: 1));
    return _storico.containsKey(_chiave(ieri));
  }

  int get giorniPuliti {
    if (_storico.isEmpty) return 0;

    final chiaviOrdinate = _storico.keys.toList()..sort();
    final primaData = DateTime.parse(chiaviOrdinate.first);

    int conta = 0;
    var giorno = DateTime.now().subtract(const Duration(days: 1));
    while (!_storico.containsKey(_chiave(giorno)) && !giorno.isBefore(primaData)) {
      conta++;
      giorno = giorno.subtract(const Duration(days: 1));
    }
    return conta;
  }
}

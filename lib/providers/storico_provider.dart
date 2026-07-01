import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tiene una mappa data → picco BAC di quella sera, salvata in
// SharedPreferences come stringa JSON in modo isolato per account.
class StoricoProvider extends ChangeNotifier {
  static const String _legacyPrefsKey = 'storico_key';

  // data ('yyyy-MM-dd'), salva il picco BAC di quella serata
  Map<String, double> _storico = {};
  String? _activeUsername; 

  // Espone una copia in sola lettura, in modo che il calendario la legga e non la tocchi
  Map<String, double> get storico => Map.unmodifiable(_storico);

  // Trasforma una data nella chiave della mappa, ignorando l'ora
  String _chiave(DateTime data) {
    final m = data.month.toString().padLeft(2, '0');
    final g = data.day.toString().padLeft(2, '0');
    return '${data.year}-$m-$g';
  }

  // Genera la chiave univoca per il singolo utente
  String _prefsKeyForAccount(String accountId) =>
      'storicoBevute_${Uri.encodeComponent(accountId)}';

  // Carica il diario dell'account corrente da SharedPreferences.
  Future<void> loadForAccount(String? accountId) async {
    _activeUsername = accountId;
    final prefs = await SharedPreferences.getInstance();
    
    if (accountId == null || accountId.isEmpty) {
      _storico = {};
      notifyListeners();
      return;
    }

    final userKey = _prefsKeyForAccount(accountId);
    final raw = prefs.getString(userKey);

    // Eliminazione della vecchia chiave globale legacy se presente
    if (prefs.containsKey(_legacyPrefsKey)) {
      await prefs.remove(_legacyPrefsKey);
    }

    if (raw == null || raw.isEmpty) {
      _storico = {};
    } else {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _storico = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    print("StoricoProvider: Dati caricati per l'utente $_activeUsername. Serate registrate: ${_storico.length}");
    notifyListeners();
  }

  Future<void> clear() async {
    _activeUsername = null;
    _storico = {};
    notifyListeners();
  }

  // Salva il picco BAC di una serata in modo ISOLATO per l'utente attivo.
  Future<void> salvaSerata(DateTime data, double bac) async {
    if (bac <= 0) return;                 // niente da registrare se non si è bevuto
    if (_activeUsername == null || _activeUsername!.isEmpty) return; // Sicurezza

    final k = _chiave(data);
    final attuale = _storico[k] ?? 0;
    if (bac <= attuale) return;           // già salvato un picco uguale o maggiore

    _storico[k] = bac;
    
    final prefs = await SharedPreferences.getInstance();
    // CORRETTO: Salviamo usando la chiave specifica dell'account attivo!
    final userKey = _prefsKeyForAccount(_activeUsername!);
    await prefs.setString(userKey, jsonEncode(_storico));
    
    print("StoricoProvider: Salvata serata per $_activeUsername su chiave $userKey");
    notifyListeners();
  }

  // Picco BAC di una certa data, o null se quel giorno non si è bevuto.
  double? bacDelGiorno(DateTime data) => _storico[_chiave(data)];

  // True se IERI risulta una serata con alcol 
  bool get bevutoIeri {
    final ieri = DateTime.now().subtract(const Duration(days: 1));
    return _storico.containsKey(_chiave(ieri));
  }

  // Giorni consecutivi senza bere, contati a ritroso partendo da ieri.
  int get giorniPuliti {
    int conta = 0;
    var giorno = DateTime.now().subtract(const Duration(days: 1));
    while (!_storico.containsKey(_chiave(giorno))) {
      conta++;
      giorno = giorno.subtract(const Duration(days: 1));
      if (conta > 365) break; 
    }
    return conta;
  }
}
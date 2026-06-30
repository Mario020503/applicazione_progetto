import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tiene una mappa  data → picco BAC di quella sera, salvata in
// SharedPreferences come stringa JSON sotto la chiave 'storicoBevute'.
//
// A cosa serve:
//   - colorare il calendario in base alla gravità della serata
//   - alimentare i suggerimenti della home (hai bevuto ieri?
//     quanti giorni puliti di fila?)
//
// La registrazione è automatica: SessionScreen chiama salvaSerata()
// ogni volta che il BAC tocca un nuovo picco.
class StoricoProvider extends ChangeNotifier {
  static const String _legacyPrefsKey = 'storico_key';

  // Chiave SharedPreferences dove vive il diario in formato JSON
  static const String _prefsKey = 'storicoBevute';

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

    // Lo storico legacy globale non va mai riutilizzato per un account nuovo:
    // se esiste ancora, lo ignoriamo e lo eliminiamo per evitare leakage.
    if (prefs.containsKey(_legacyPrefsKey)) {
      await prefs.remove(_legacyPrefsKey);
    }

    if (raw == null || raw.isEmpty) {
      _storico = {};
    } else {
      // jsonDecode restituisce Map<String, dynamic>:
      // riconvertiamo ogni valore in double
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _storico = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    notifyListeners();
  }

  Future<void> clear() async {
    _activeUsername = null;
    _storico = {};
    notifyListeners();
  }

  // Salva il picco BAC di una serata.
  // Idempotente: tiene sempre il valore più alto per quella data, quindi
  // richiamarlo più volte la stessa sera non crea doppioni né regressioni.
  Future<void> salvaSerata(DateTime data, double bac) async {
    if (bac <= 0) return;                 // niente da registrare se non si è bevuto
    final k = _chiave(data);
    final attuale = _storico[k] ?? 0;
    if (bac <= attuale) return;           // già salvato un picco uguale o maggiore

    _storico[k] = bac;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_storico));
    notifyListeners();
  }

  // Picco BAC di una certa data, o null se quel giorno non si è bevuto.
  // Usato dal calendario per scegliere il colore della cella.
  double? bacDelGiorno(DateTime data) => _storico[_chiave(data)];

  // True se IERI risulta una serata con alcol 
  bool get bevutoIeri {
    final ieri = DateTime.now().subtract(const Duration(days: 1));
    return _storico.containsKey(_chiave(ieri));
  }

  // Giorni consecutivi senza bere, contati a ritroso partendo da ieri.
  // Oggi è escluso di proposito: la serata di oggi potrebbe non essere
  // ancora cominciata
  int get giorniPuliti {
    int conta = 0;
    var giorno = DateTime.now().subtract(const Duration(days: 1));
    while (!_storico.containsKey(_chiave(giorno))) {
      conta++;
      giorno = giorno.subtract(const Duration(days: 1));
      if (conta > 365) break;             // tetto di sicurezza, evita loop infiniti
    }
    return conta;
  }
}

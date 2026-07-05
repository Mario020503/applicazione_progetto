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

  // Chiave SharedPreferences dove vive il diario in formato JSON
  static const String _prefsKey = 'storicoBevute';

  // data ('yyyy-MM-dd'), salva il picco BAC di quella serata
  Map<String, double> _storico = {};

  // Espone una copia in sola lettura, in modo che il calendario la legga e non la tocchi
  Map<String, double> get storico => Map.unmodifiable(_storico);

  // Account attualmente caricato: lo storico è separato per ogni account.
  String? _accountId;

  // Chiave SharedPreferences dell'account corrente (globale se nessuno è caricato).
  String _key() => _accountId == null ? _prefsKey : '${_prefsKey}_$_accountId';

  // Trasforma una data nella chiave della mappa, ignorando l'ora
  String _chiave(DateTime data) {
    final m = data.month.toString().padLeft(2, '0');
    final g = data.day.toString().padLeft(2, '0');
    return '${data.year}-$m-$g';
  }

  // caricaStorico() e' stato rimosso: era codice morto e per giunta leggeva
  // dalla chiave globale invece che da quella per account. Il caricamento del
  // diario passa sempre da loadForAccount(), che usa _key().

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
    await prefs.setString(_key(), jsonEncode(_storico));
    notifyListeners();
  }

  // Carica lo storico di uno specifico account. Chiamato al login.
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

  // Svuota lo storico IN MEMORIA (al logout o login fallito).
  // Non cancella i dati su disco: azzera solo ciò che è caricato in RAM.
  Future<void> clear() async {
    _accountId = null;
    _storico = {};
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
    // Diario vuoto: nessuna storia, quindi nessuna serie da festeggiare.
    if (_storico.isEmpty) return 0;

    // La data piu' vecchia registrata segna il confine oltre il quale non
    // abbiamo dati: prima di allora non ha senso contare giorni "puliti".
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

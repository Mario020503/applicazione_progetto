import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/heart_rate.dart';
import '../models/resting_hr.dart';

/// Livello di rete: unico punto in cui l'app parla col server IMPACT.
///
/// Segue lo schema insegnato nel corso (repo gcappon/bwthw): autenticazione
/// a coppia di token JWT (access + refresh), rinnovo del token scaduto tramite
/// l'endpoint di refresh invece di rifare il login, e risposta dati sempre
/// nella forma { "data": { "date": ..., "data": [ ... ] } }.
class ImpactService {
  static const String _baseUrl = 'https://impact.dei.unipd.it/bwthw/';

  static const String _tokenEndpoint = 'gate/v1/token/';
  static const String _refreshEndpoint = 'gate/v1/refresh/';
  static const String _heartRateEndpoint = 'data/v1/heart_rate/patients/';
  static const String _restingHeartRateEndpoint = 'data/v1/resting_heart_rate/patients/';

  // Chiavi con cui i due token vivono in SharedPreferences.
  static const String _accessKey = 'access';
  static const String _refreshKey = 'refresh';

  // Ogni chiamata si arrende dopo questo tempo: senza timeout, su rete lenta
  // il Future non si chiuderebbe mai e la UI resterebbe a caricare all'infinito.
  static const Duration _timeout = Duration(seconds: 15);

  // 1) AUTORIZZAZIONE
  // Manda username e password, riceve la coppia di token e la salva.
  // Ritorna true se l'autenticazione e' andata a buon fine.
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl$_tokenEndpoint');
    try {
      // body come mappa: http lo invia come form (application/x-www-form-urlencoded),
      // esattamente come nel codice di riferimento del corso.
      final response = await http
          .post(url, body: {'username': username, 'password': password})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        await _storeTokens(
          decoded['access'] as String?,
          decoded['refresh'] as String?,
        );
        return true;
      }
    } catch (_) {
      // rete assente, timeout o risposta non valida: trattiamo tutto come
      // fallimento di autenticazione.
    }
    return false;
  }

  Future<void> _storeTokens(String? access, String? refresh) async {
    final sp = await SharedPreferences.getInstance();
    if (access != null) await sp.setString(_accessKey, access);
    if (refresh != null) await sp.setString(_refreshKey, refresh);
  }

  // 2) TOKEN VALIDO
  // Restituisce un access token utilizzabile: se quello salvato e' scaduto,
  // prova a rinnovarlo col refresh. Null se non e' recuperabile.
  Future<String?> _validAccessToken() async {
    final sp = await SharedPreferences.getInstance();
    final access = sp.getString(_accessKey);
    if (access == null) return null;

    bool expired;
    try {
      expired = JwtDecoder.isExpired(access);
    } catch (_) {
      expired = true; // token illeggibile: lo trattiamo come scaduto
    }
    if (!expired) return access;

    final refreshed = await _refreshTokens();
    if (!refreshed) return null;
    return sp.getString(_accessKey);
  }

  // 3) REFRESH
  // Usa il solo refresh token (non servono username e password) per ottenere
  // una coppia nuova.
  Future<bool> _refreshTokens() async {
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString(_refreshKey);
    if (refresh == null) return false;

    final url = Uri.parse('$_baseUrl$_refreshEndpoint');
    try {
      final response = await http
          .post(url, body: {'refresh': refresh})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        await _storeTokens(
          decoded['access'] as String?,
          decoded['refresh'] as String?,
        );
        return true;
      }
    } catch (_) {
      // refresh scaduto o errore: chi chiama dovra' rifare il login.
    }
    return false;
  }

  // 4) DATI: battiti di un giorno per un paziente.
  Future<List<HeartRate>?> fetchHeartRateByDay({
    required String patient,
    required String day,
  }) async {
    final access = await _validAccessToken();
    if (access == null) return null;

    final url = Uri.parse('$_baseUrl$_heartRateEndpoint$patient/day/$day/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $access'},
      ).timeout(_timeout);

      if (response.statusCode != 200) return null;

      // Forma nota dal contratto del corso: { data: { date, data: [...] } }.
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final envelope = decoded['data'] as Map<String, dynamic>?;
      if (envelope == null) return [];

      final String date = (envelope['date'] as String?) ?? day;
      final List<dynamic> list = (envelope['data'] as List<dynamic>?) ?? [];

      return list
          .map((item) => HeartRate.fromJson(date, item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // 5) DATI: frequenza a riposo di un giorno per un paziente.
  Future<List<RestingHeartRate>?> fetchRestingHeartRateByDay({
    required String patient,
    required String day,
  }) async {
    final access = await _validAccessToken();
    if (access == null) return null;

    final url = Uri.parse('$_baseUrl$_restingHeartRateEndpoint$patient/day/$day/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $access'},
      ).timeout(_timeout);

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final envelope = decoded['data'] as Map<String, dynamic>?;
      if (envelope == null) return [];

      final String date = (envelope['date'] as String?) ?? day;
      final dynamic inner = envelope['data'];

      // La frequenza a riposo puo' arrivare come lista di punti oppure come
      // singolo oggetto giornaliero: gestiamo entrambi restando ancorati allo
      // stesso involucro data/data.
      if (inner is List) {
        return inner
            .map((item) => RestingHeartRate.fromJson(date, item as Map<String, dynamic>))
            .toList();
      } else if (inner is Map<String, dynamic>) {
        return [RestingHeartRate.fromJson(date, inner)];
      }
      return [];
    } catch (_) {
      return null;
    }
  }
}

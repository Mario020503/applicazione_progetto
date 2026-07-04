import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/heart_rate.dart';

class ImpactService {
  final String baseUrl = "https://impact.dei.unipd.it/bwthw";

  Future<String?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/gate/v1/token/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access'] as String;
      }
    } catch (e) {
      debugPrint('Errore login: $e');
    }
    return null;
  }

  Future<List<HeartRate>?> fetchHeartRateByDay({
    required String token,
    required String username,
    required String day,
  }) async {
    final url = Uri.parse('$baseUrl/data/v1/heart_rate/patients/$username/day/$day/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        List<dynamic> rawData = [];

        if (decodedBody is Map<String, dynamic>) {
          // --- LOG TEMPORANEO DI ISPEZIONE CHIAVI ---
          debugPrint("DEBUG IMPACT: Il server ha risposto con una Mappa. Le chiavi presenti sono: ${decodedBody.keys.toList()}");
          
          // Estrazione dinamica provando le chiavi standard del server IMPACT
          if (decodedBody['data'] != null) {
            rawData = decodedBody['data'] is List ? decodedBody['data'] : (decodedBody['data']['data'] ?? []);
          } else if (decodedBody['records'] != null) {
            rawData = decodedBody['records'];
          } else {
            // Se le chiavi standard falliscono, proviamo a cercare la prima lista disponibile nella mappa
            for (var val in decodedBody.values) {
              if (val is List) {
                rawData = val;
                break;
              }
            }
          }
        } else if (decodedBody is List<dynamic>) {
          rawData = decodedBody;
        }
        
        return rawData.map((json) => HeartRate.fromJson(day, json as Map<String, dynamic>)).toList();
      } else {
        debugPrint("Errore server in fetchHeartRateByDay: StatusCode ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Errore fetchHeartRateByDay (Blocco Catch): $e');
    }
    return null;
  }
}

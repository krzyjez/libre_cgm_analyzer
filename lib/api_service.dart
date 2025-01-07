import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'model.dart';
import 'logger.dart';

class ApiService {
  static const _baseUrl = 'http://localhost:8000';
  final _logger = Logger('ApiService');

  /// Pobiera dane debugowe z pliku
  Future<String> loadDebugData() async {
    try {
      final data = await rootBundle.loadString('data_source/KrzysztofJeż_glucose_12-12-2024.csv');
      _logger.info('Pobrano dane debugowe');
      return data;
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych debugowych: $e');
      rethrow;
    }
  }

  /// Pobiera dane użytkownika i CSV z serwera
  Future<(UserInfo, String)> loadDataFromApi(int defaultTreshold) async {
    try {
      // Pobieranie danych CSV
      final csvResponse = await http.get(Uri.parse('$_baseUrl/csv-data'));
      _logger.info('kod pobieranie danyc csv: ${csvResponse.statusCode}');
      if (csvResponse.statusCode != 200) {
        throw Exception('Failed to load CSV data');
      }
      final csvData = utf8.decode(csvResponse.bodyBytes);
      _logger.info('Pobrano dane CSV');

      // Pobieranie danych użytkownika
      UserInfo userData;
      final userResponse = await http.get(Uri.parse('$_baseUrl/user-data'));

      if (userResponse.statusCode == 200) {
        // Dane użytkownika istnieją
        userData = UserInfo.fromJson(jsonDecode(userResponse.body));
        _logger.info('Pobrano dane użytkownika');
      } else if (userResponse.statusCode == 404) {
        // Tylko gdy serwer jawnie potwierdzi, że nie ma danych użytkownika
        _logger.info('Brak danych użytkownika na serwerze - tworzenie nowego profilu');
        userData = UserInfo(
          treshold: defaultTreshold,
          days: [],
        );
      } else {
        // Każdy inny błąd (500, timeout, brak połączenia itp.) powinien być zgłoszony
        _logger.error('Błąd podczas pobierania danych użytkownika: ${userResponse.statusCode}');
        throw Exception('Nie udało się pobrać danych użytkownika. Kod: ${userResponse.statusCode}');
      }

      return (userData, csvData);
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych z API: $e');
      rethrow;
    }
  }

  /// Zapisuje dane użytkownika na serwerze
  Future<void> saveUserData(UserInfo userData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save user data');
      } else {
        _logger.info('Dane usera zapisane pomyślnie');
      }
    } catch (e) {
      _logger.error('Błąd podczas zapisywania danych użytkownika: $e');
      rethrow;
    }
  }
}

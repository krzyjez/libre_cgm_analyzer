import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logger.dart';
import 'model.dart';

class ApiService {
  final String baseUrl;
  final _logger = Logger('ApiService');

  ApiService({required this.baseUrl});

  /// Pobiera plik CSV z danymi pomiarów glukozy
  Future<String> fetchGlucoseData() async {
    _logger.info('Próba pobrania danych z $baseUrl/data/glucose.csv');

    try {
      final response = await http.get(Uri.parse('$baseUrl/data/glucose.csv'));

      if (response.statusCode == 200) {
        _logger.info('Pobrano dane pomyślnie (${response.body.length} bajtów)');
        return response.body;
      } else {
        _logger.error('Błąd HTTP ${response.statusCode}');
        throw Exception('Błąd pobierania danych: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Wyjątek podczas pobierania: $e');
      rethrow;
    }
  }

  /// Pobiera dane użytkownika
  Future<UserInfo> fetchUserData() async {
    _logger.info('Pobieranie danych użytkownika');

    try {
      final response = await http.get(Uri.parse('$baseUrl/data/user'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.info('Pobrano dane użytkownika');
        return UserInfo.fromJson(data);
      } else {
        _logger.error('Błąd HTTP ${response.statusCode}');
        throw Exception('Błąd pobierania danych użytkownika: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych użytkownika: $e');
      rethrow;
    }
  }

  /// Zapisuje dane użytkownika
  Future<void> saveUserData(UserInfo userInfo) async {
    _logger.info('Zapisywanie danych użytkownika');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/data/user'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userInfo.toJson()),
      );

      if (response.statusCode == 200) {
        _logger.info('Dane użytkownika zapisane pomyślnie');
      } else {
        _logger.error('Błąd HTTP ${response.statusCode}');
        throw Exception('Błąd zapisu danych użytkownika: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Błąd podczas zapisu danych użytkownika: $e');
      rethrow;
    }
  }
}

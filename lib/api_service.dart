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
      return data;
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych debugowych: $e');
      rethrow;
    }
  }

  /// Pobiera dane użytkownika i CSV z serwera
  Future<(UserInfo, String)> loadDataFromApi() async {
    try {
      // Pobieranie danych użytkownika
      final userResponse = await http.get(Uri.parse('$_baseUrl/user-data'));
      if (userResponse.statusCode != 200) {
        throw Exception('Failed to load user data');
      }
      final userData = UserInfo.fromJson(jsonDecode(userResponse.body));

      // Pobieranie danych CSV
      final csvResponse = await http.get(Uri.parse('$_baseUrl/csv-data'));
      if (csvResponse.statusCode != 200) {
        throw Exception('Failed to load CSV data');
      }
      final csvData = csvResponse.body;

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
      }
    } catch (e) {
      _logger.error('Błąd podczas zapisywania danych użytkownika: $e');
      rethrow;
    }
  }
}

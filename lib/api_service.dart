import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'logger.dart';
import 'model.dart';

class ApiService {
  static const _baseUrl = 'https://libre-cgm-analyzer-api-e7bsfghgdtdscka2.polandcentral-01.azurewebsites.net/api';
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

  /// Pobiera dane użytkownika z API
  ///
  /// Parametry:
  /// - `defaultTreshold`: Domyślny próg dla pomiarów glukozy
  Future<UserInfo> loadUserInfo(int defaultTreshold) async {
    try {
      // Najpierw pobierz dane użytkownika
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

      return userData;
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych użytkownika: $e');
      throw Exception('Błąd podczas pobierania danych użytkownika');
    }
  }

  /// Pobiera dane CSV z API
  Future<String> loadCsvData() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/csv-data'));
      if (response.statusCode != 200) {
        throw Exception('Nie udało się pobrać danych CSV. Kod: ${response.statusCode}');
      }
      final csvData = utf8.decode(response.bodyBytes);
      _logger.info('Pobrano dane CSV');

      return csvData;
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych CSV: $e');
      throw Exception('Błąd podczas pobierania danych CSV');
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

  /// Wysyła obrazek na serwer
  Future<String> uploadImage(ImageDto image) async {
    try {
      final uri = Uri.parse('$_baseUrl/images');
      final request = http.MultipartRequest('POST', uri);

      // Dodajemy plik do formularza
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          image.bytes,
          filename: 'image.png', // Dodajemy nazwę pliku
          contentType: MediaType.parse('image/png'), // Zakładamy PNG, serwer i tak sprawdzi prawdziwy typ
        ),
      );

      _logger.info('Wysyłanie żądania: uri=${uri.toString()}, size=${image.bytes.length}');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        _logger.info('Wysłano obrazek: ${data['filename']}');
        return data['filename'];
      }
      throw Exception('Błąd podczas wysyłania obrazka');
    } catch (e) {
      _logger.error('Błąd podczas wysyłania obrazka: $e');
      rethrow;
    }
  }

  /// Usuwa obrazek z serwera
  Future<bool> deleteImage(String filename) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/images/$filename'));
      if (response.statusCode == 200) {
        _logger.info('Usunięto obrazek: $filename');
        return true;
      } else {
        _logger.error('Nie udało się usunąć obrazka: $filename (kod: ${response.statusCode})');
        return false;
      }
    } catch (e) {
      _logger.error('Błąd podczas usuwania obrazka: $e');
      return false;
    }
  }

  /// Zwraca URL do obrazka
  String getImageUrl(String filename) {
    return '$_baseUrl/images/$filename';
  }

  /// Pobiera obrazek z serwera
  Future<List<int>> downloadImage(String filename) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/images/$filename'));
      if (response.statusCode == 200) {
        _logger.info('Pobrano obrazek: $filename');
        return response.bodyBytes;
      }
      throw Exception('Błąd podczas pobierania obrazka');
    } catch (e) {
      _logger.error('Błąd podczas pobierania obrazka: $e');
      rethrow;
    }
  }

  /// Zapisuje dane CSV na serwerze
  Future<void> saveCsvData(String csvContent) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/csv-data'),
        headers: {'Content-Type': 'text/plain'},
        body: csvContent,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save CSV data');
      }
      _logger.info('Zapisano dane CSV na serwerze');
    } catch (e) {
      _logger.error('Błąd podczas zapisywania danych CSV: $e');
      rethrow;
    }
  }

  /// Pobiera wersję API
  Future<String> getApiVersion() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/version'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['version'];
      }
      throw Exception('Failed to load API version');
    } catch (e) {
      _logger.error('Błąd podczas pobierania wersji API: $e');
      rethrow;
    }
  }
}

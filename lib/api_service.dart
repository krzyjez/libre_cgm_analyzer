import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'logger.dart';
import 'model.dart';

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
      //_logger.info('kod pobieranie danyc csv: ${csvResponse.statusCode}');
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

  /// Wysyła obrazek na serwer
  Future<String> uploadImage(ImageDto image) async {
    try {
      final uri = Uri.parse('$_baseUrl/images');
      final request = http.MultipartRequest('POST', uri);

      // Określamy typ MIME na podstawie rozszerzenia pliku
      String contentType = 'image/jpeg'; // domyślnie
      if (image.filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (image.filename.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      }

      // Dodajemy plik do formularza z określonym typem MIME
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          image.bytes,
          filename: image.filename,
          contentType: MediaType.parse(contentType),
        ),
      );

      // Dodajemy dodatkowe pola formularza
      request.fields['filename'] = image.filename;

      _logger.info(
          'Wysyłanie żądania: uri=${uri.toString()}, filename=${image.filename}, size=${image.bytes.length}, contentType=$contentType');

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

  /// Pobiera listę dostępnych obrazków
  Future<List<String>> getImages() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/images'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final images = List<String>.from(data['images']);
        _logger.info('Pobrano listę ${images.length} obrazków');
        return images;
      }
      throw Exception('Błąd podczas pobierania listy obrazków');
    } catch (e) {
      _logger.error('Błąd podczas pobierania listy obrazków: $e');
      rethrow;
    }
  }
}

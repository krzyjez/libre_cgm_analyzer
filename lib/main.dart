// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'csv_parser.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'day_card_builder.dart';
import 'api_service.dart';
import 'logger.dart';
import 'version.dart';
import 'model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Libre CGM Analyzer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const defaultTreshold = 140;
  String? _fileName;
  UserInfo? _userInfo;
  final CsvParser _csvParser = CsvParser();
  final ApiService _apiService = ApiService(baseUrl: 'http://localhost:8000');
  final _logger = Logger('MyHomePage');

  Future<void> pickCsvFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final fileBytes = result.files.first.bytes;
        if (fileBytes != null) {
          final csvContent = utf8.decode(fileBytes);
          setState(() {
            _fileName = result.files.first.name;
            _csvParser.parseCsv(csvContent, defaultTreshold);
          });

          // Wyświetlanie SnackBar tylko jeśli kontekst jest aktualny
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Wczytano plik: ${result.files.first.name}')),
          );
        }
      }
    } catch (e) {
      _logger.error('Błąd podczas wybierania pliku: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas wczytywania pliku: $e')),
        );
      }
    }
  }

  Future<void> _loadDebugData() async {
    try {
      final bytes = await rootBundle.load('data_source/KrzysztofJeż_glucose_12-12-2024.csv');
      final String response = utf8.decode(bytes.buffer.asUint8List());
      setState(() {
        _fileName = 'Dane debugowe';
        _csvParser.parseCsv(response, defaultTreshold);
      });
      print('Preloaded debug data: ${_csvParser.rowCount} wierszy');
    } catch (e) {
      _logger.error('Błąd podczas wczytywania danych debugowych: $e');
    }
  }

  Future<void> _loadDataFromApi() async {
    try {
      // Pobierz równolegle dane CSV i dane użytkownika
      final results = await Future.wait([
        _apiService.fetchGlucoseData(),
        _apiService.fetchUserData(),
      ]);

      final csvData = results[0] as String;
      final userData = results[1] as UserInfo;

      setState(() {
        _fileName = 'Dane z serwera';
        _userInfo = userData;
        _csvParser.parseCsv(csvData, userData.treshold); // używamy progu z danych użytkownika
      });
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych z API: $e');
      // W przypadku błędu, wczytaj dane debugowe
      print('Błąd pobierania danych z API: $e');
      _loadDebugData();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDataFromApi(); // Próbujemy najpierw pobrać z API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Libre CGM Analyzer v$appVersion'),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'Dodaj plik CSV',
              onPressed: () => pickCsvFile(context),
            ),
          ],
        ),
        body: Center(
          child: _fileName == null
              ? const Text('Wybierz plik CSV')
              : ListView.builder(
                  itemCount: _csvParser.days.length,
                  itemBuilder: (context, index) {
                    final day = _csvParser.days[index];
                    // Znajdź DayUser dla danej daty
                    final dayUser = _findUserDayByDate(day.date);

                    return DayCardBuilder.buildDayCard(
                      context,
                      day,
                      _userInfo?.treshold ?? defaultTreshold,
                      dayUser,
                    );
                  },
                ),
        ));
  }

  DayUser? _findUserDayByDate(DateTime date) {
    if (_userInfo == null) return null;

    for (var dayUser in _userInfo!.days) {
      if (dayUser.date.year == date.year && dayUser.date.month == date.month && dayUser.date.day == date.day) {
        return dayUser;
      }
    }

    return null;
  }
}

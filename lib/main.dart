// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'logger.dart';
import 'api_service.dart';
import 'csv_parser.dart';
import 'day_controller.dart';
import 'day_card_builder.dart';
import 'version.dart';

/// Domyślny próg dla pomiarów glukozy (w mg/dL)
const defaultTreshold = 140;

/// Punkt wejścia aplikacji
void main() {
  runApp(const MyApp());
}

/// Główna aplikacja do analizy danych CGM
///
/// Konfiguruje główne ustawienia aplikacji takie jak:
/// - Tytuł
/// - Motyw (kolory, czcionki)
/// - Strona główna
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

/// Główny ekran aplikacji
///
/// Zawiera:
/// - Przycisk do wyboru pliku CSV
/// - Listę dni z pomiarami
/// - Wykresy dla każdego dnia
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// Stan głównego ekranu aplikacji
///
/// Zarządza:
/// - Wczytywaniem danych z API
/// - Parsowaniem plików CSV
/// - Wyświetlaniem danych w postaci kart dla każdego dnia
class _MyHomePageState extends State<MyHomePage> {
  static const defaultTreshold = 140;
  String? _fileName;
  final CsvParser _csvParser = CsvParser();
  final _logger = Logger('MyHomePage');
  final _apiService = ApiService();
  late final DayController _dayController;

  /// Pozwala użytkownikowi wybrać plik CSV z danymi
  ///
  /// Używa file_picker do wyboru pliku, następnie wysyła go na serwer
  /// i dopiero po potwierdzeniu zapisu wyświetla dane
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

          try {
            // Najpierw próbujemy zapisać na serwerze
            await _apiService.saveCsvData(csvContent);

            // Tylko jeśli zapis się udał, parsujemy i wyświetlamy dane
            setState(() {
              _csvParser.parseCsv(csvContent, defaultTreshold);
              _fileName = 'Dane z serwera'; // Dodajemy nazwę pliku do stanu
            });

            // Wyświetlanie SnackBar tylko jeśli kontekst jest aktualny
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Zapisano plik na serwerze'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            _logger.error('Błąd podczas zapisywania na serwerze: $e');
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nie udało się zapisać pliku na serwerze. Spróbuj ponownie.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      _logger.error('Błąd podczas wybierania pliku: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas wybierania pliku: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Wczytuje przykładowe dane do debugowania
  ///
  /// Używane podczas developmentu do szybkiego testowania
  /// funkcjonalności bez konieczności łączenia z API
  // Future<void> _loadDebugData() async {
  //   try {
  //     final csvContent = await _apiService.loadDebugData();
  //     setState(() {
  //       _fileName = 'Dane debugowe';
  //       _csvParser.parseCsv(csvContent, defaultTreshold);
  //     });
  //     print('Preloaded debug data: ${_csvParser.rowCount} wierszy');
  //   } catch (e) {
  //     _logger.error('Błąd podczas pobierania danych debugowych: $e');
  //   }
  // }

  /// Wczytuje dane z API
  ///
  /// Pobiera:
  /// - Dane użytkownika (ustawienia, offsety)
  /// - Dane CSV z pomiarami
  ///
  /// Po pobraniu danych:
  /// - Aktualizuje dane użytkownika w kontrolerze
  /// - Parsuje dane CSV
  Future<void> _loadDataFromApi() async {
    try {
      final (userInfo, csvData) = await _apiService.loadDataFromApi(defaultTreshold);
      _logger.info('Wczytano dane z API - userInfo: $userInfo');
      setState(() {
        _fileName = 'Dane z serwera';
        _dayController.userInfo = userInfo;
        if (csvData.isNotEmpty) {
          _csvParser.parseCsv(csvData, userInfo.treshold);
        }
      });
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych z API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Na serwerze brak danych glukozy. Wgraj plik CSV. (przycisk w prawym górnym rogu)'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Ponów',
              textColor: Colors.white,
              onPressed: () => _loadDataFromApi(),
            ),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _dayController = DayController(_apiService, defaultTreshold);
    _loadDataFromApi(); // Próbujemy najpierw pobrać z API
  }

  @override
  Widget build(BuildContext context) {
    // Przygotowanie tytułu z podsumowaniem danych
    String title = 'Libre CGM Analyzer v$appVersion';
    if (_csvParser.days.isNotEmpty) {
      final daysCount = _csvParser.days.length;
      final lastDay = _csvParser.days.last;
      final dateFormat = DateFormat('dd.MM.yyyy');
      final lastDate = dateFormat.format(lastDay.date);
      title = '$daysCount dni (ostatni pomiar: $lastDate)';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Dodaj plik CSV',
            onPressed: () => pickCsvFile(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _dayController,
        builder: (context, _) {
          return Center(
            child: _fileName == null
                ? const Text('Wybierz plik CSV')
                : ListView.builder(
                    itemCount: _csvParser.days.length,
                    itemBuilder: (context, index) {
                      final day = _csvParser.days[index];

                      return DayCardBuilder.buildDayCard(
                        context,
                        _dayController,
                        day,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

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
import 'model.dart';

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
  final _logger = Logger('_MyHomePageState');
  final _apiService = ApiService();
  late final DayController _dayController;

  String? _fileName;
  String _apiVersion = '';
  List<DayData> _days = []; // Lista dni z danymi z csv

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
              _days = CsvParser.parseCsv(csvContent, defaultTreshold, _dayController.userInfo);
              _dayController.csvData = _days;
              _fileName = 'Dane z serwera'; // Dodajemy nazwę pliku do stanu
            });

            // Wyświetlanie SnackBar tylko jeśli kontekst jest aktualny
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Zapisano plik na serwerze'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            _logger.error('Błąd podczas zapisywania na serwerze: $e');
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
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
          // Parsujemy dane CSV
          _days = CsvParser.parseCsv(csvData, userInfo.treshold, userInfo);
          // Przekazujemy sparsowane dane do kontrolera
          _dayController.csvData = _days;
        }
      });
    } catch (e) {
      _logger.error('Błąd podczas pobierania danych z API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Na serwerze brak danych glukozy. Wgraj plik CSV. (przycisk w prawym górnym rogu)'),
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

  Future<void> _loadApiVersion() async {
    try {
      final version = await _apiService.getApiVersion();
      setState(() {
        _apiVersion = version;
      });
    } catch (e) {
      // Błąd pobierania wersji - zostawiamy pustą
    }
  }

  @override
  void initState() {
    super.initState();
    _dayController = DayController(_apiService, defaultTreshold);
    _loadDataFromApi(); // Próbujemy najpierw pobrać z API
    _loadApiVersion();
  }

  @override
  Widget build(BuildContext context) {
    // Przygotowanie tytułu z podsumowaniem danych
    String title = 'Libre CGM Analyzer v$appVersion';
    if (_days.isNotEmpty) {
      final daysCount = _days.length;
      final lastDay = _days.last;
      final dateFormat = DateFormat('dd.MM.yyyy');
      final lastDate = dateFormat.format(lastDay.date);
      title = '$daysCount dni (ostatni pomiar: $lastDate)';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Text(title),
            const SizedBox(width: 10),
            Text(
              'APP v$appVersion | API $_apiVersion',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
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
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      final day = _days[index];

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

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'csv_parser.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

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
  String? _fileName;
  final CsvParser _csvParser = CsvParser();

  Future<void> pickCsvFile(BuildContext context) async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement()..accept = '.csv';

    // Otwórz okno wyboru pliku
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final reader = html.FileReader();

        reader.onLoad.listen((e) {
          // Bezpieczne aktualizowanie stanu
          setState(() {
            _fileName = file.name;
            _csvParser.parseCsv(reader.result as String);
          });

          // Wyświetlanie SnackBar tylko jeśli kontekst jest aktualny
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Wczytano plik: ${file.name}')),
          );
        });

        reader.onError.listen((error) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Błąd podczas wczytywania pliku')),
          );
        });

        reader.readAsText(file);
      } else {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie wybrano pliku')),
        );
      }
    });
  }

  Future<void> _loadDebugData() async {
    final String response = await rootBundle
        .loadString('data_source/KrzysztofJeż_glucose_12-12-2024.csv');
    setState(() {
      _fileName = 'Dane debugowe';
      _csvParser.parseCsv(response);
    });
    print('Preloaded debug data: ${_csvParser.rowCount} wierszy');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Libre CGM Analyzer 4'),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'Dodaj plik CSV',
              onPressed: () => pickCsvFile(context),
            ),
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Preload Debug Data',
              onPressed: _loadDebugData,
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
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nagłówek
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                              ),
                              child: Container(
                                width: double.infinity,
                                color: Colors.grey[800],
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Data: ${DateFormat('yyyy-MM-dd').format(day.date)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            // Obszar roboczy
                            const Text("Buba"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ));
  }
}

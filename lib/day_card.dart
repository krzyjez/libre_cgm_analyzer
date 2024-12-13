import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'csv_parser.dart';

class DayCardBuilder {
  /// Buduje widżet karty dla danego dnia.
  ///
  /// Zawiera nagłówek z datą i obszar roboczy z trzema wierszami.
  static Widget buildDayCard(Day day) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 10.0, top: 10.0, right: 10.0, bottom: 0.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek
            _buildHeader(day.date),
            // Odstęp między nagłówkiem i obszarem roboczym
            const SizedBox(height: 4.0),
            // Obszar roboczy
            _buildWorkingArea(day),
          ],
        ),
      ),
    );
  }

  /// Buduje nagłówek dla karty dnia.
  ///
  /// Zawiera datę z zaokrąglonymi rogami i ciemnozielonym tłem.
  static Widget _buildHeader(DateTime date) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12.0),
        topRight: Radius.circular(12.0),
      ),
      child: Container(
        width: double.infinity,
        color: Colors.green[900],
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Data: ${DateFormat('yyyy-MM-dd').format(date)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Buduje obszar roboczy dla karty dnia.
  /// Zawiera trzy wiersze z tekstem.
  static Widget _buildWorkingArea(Day day) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Komentarze dzienne
          _buildDailyComments(day),
          // wykres i statystyki
          _buildChartAndStats(day),
          // notatki
          _buildNotes(day),
        ],
      ),
    );
  }

  /// Buduje sekcję komentarzy dziennych.
  static Widget _buildDailyComments(Day day) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blue[100], // Kolor tła dla pierwszego kontenera
      child: const Text('wiersz 1'),
    );
  }

  /// Buduje sekcję wykresu i statystyk.
  static Widget _buildChartAndStats(Day day) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.red[100], // Kolor tła dla drugiego kontenera
      child: Row(
        children: [
          Container(
            color: Colors.green[100],
            padding: const EdgeInsets.all(8.0),
            child: const Text('wykres'),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: const Text('statystyka'),
          ),
        ],
      ),
    );
  }

  /// Buduje sekcję notatek.
  static Widget _buildNotes(Day day) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.yellow[100], // Kolor tła dla trzeciego kontenera
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: day.notes
            .map((note) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        _createTextSpan(
                            '${DateFormat('HH:mm').format(note.timestamp)} ',
                            fontWeight: FontWeight.bold),
                        _createTextSpan(note.note),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// Tworzy obiekt TextSpan z podanym tekstem i stylami.
  ///
  /// [text] - tekst do wyświetlenia.
  /// [fontSize] - rozmiar czcionki, domyślnie 14.
  /// [color] - kolor tekstu, domyślnie czarny.
  /// [fontWeight] - grubość czcionki, domyślnie normalna.
  static TextSpan _createTextSpan(String text,
      {double fontSize = 14,
      Color color = Colors.black,
      FontWeight fontWeight = FontWeight.normal}) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'csv_parser.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'chart_data.dart';
import 'model.dart';

class DayCardBuilder {
  /// Buduje widżet karty dla danego dnia.
  ///
  /// Zawiera nagłówek z datą i obszar roboczy z trzema wierszami.
  static Widget buildDayCard(DayData day, int treshold) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0, bottom: 0.0),
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
            _buildWorkingArea(day, treshold),
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
  static Widget _buildWorkingArea(DayData day, int treshold) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Komentarze dzienne
          _buildDailyComments(day),
          // wykres i statystyki
          _buildChartAndStats(day, treshold),
          // notatki
          _buildNotes(day),
        ],
      ),
    );
  }

  /// Buduje sekcję komentarzy dziennych.
  static Widget _buildDailyComments(DayData day) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blue[100], // Kolor tła dla pierwszego kontenera
      child: const Text('wiersz 1'),
    );
  }

  /// Buduje sekcję wykresu i statystyk.
  static Widget _buildChartAndStats(DayData day, int treshold) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.red[100], // Kolor tła dla drugiego kontenera
      child: Row(
        children: [
          _buildChart(day, treshold),
          _buildStats(),
        ],
      ),
    );
  }

  /// Buduje wykres na podstawie danych dnia.
  static Widget _buildChart(DayData day, int treshold) {
    List<ChartData> chartData = day.measurements.map((measurement) {
      return ChartData(
        DateFormat('HH:mm').format(measurement.timestamp),
        measurement.glucoseValue as double,
      );
    }).toList();

    double minY = chartData.map((data) => data.y).reduce((a, b) => a < b ? a : b);
    double maxY = chartData.map((data) => data.y).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          minimum: minY < 80 ? minY : 80,
          maximum: maxY > 180 ? maxY : 180,
          plotBands: <PlotBand>[
            PlotBand(
              start: 100,
              end: 100,
              borderColor: Colors.black,
              borderWidth: 2,
            ),
            PlotBand(
              start: treshold.toDouble(),
              end: treshold.toDouble(),
              borderColor: Colors.red,
              borderWidth: 2,
            ),
          ],
        ),
        series: <LineSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
          )
        ],
      ),
    );
  }

  /// Buduje sekcję statystyk.
  static Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: const Text('statystyka'),
    );
  }

  /// Buduje sekcję notatek.
  static Widget _buildNotes(DayData day) {
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
                        _createTextSpan('${DateFormat('HH:mm').format(note.timestamp)} ', fontWeight: FontWeight.bold),
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
      {double fontSize = 14, Color color = Colors.black, FontWeight fontWeight = FontWeight.normal}) {
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

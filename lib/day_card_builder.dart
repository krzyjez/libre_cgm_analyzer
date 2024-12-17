import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          Expanded(
            child: _buildChart(day, treshold),
          ),
          SizedBox(
            width: 200,
            child: _buildStats(),
          ),
        ],
      ),
    );
  }

  /// Buduje wykres na podstawie danych dnia.
  static Widget _buildChart(DayData day, int treshold) {
    List<ChartData> chartData = day.measurements.map((measurement) {
      return ChartData(
        measurement.timestamp,
        measurement.glucoseValue as double,
      );
    }).toList();

    // Znajdujemy minimalny i maksymalny czas
    DateTime minX = chartData.map((data) => data.x).reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime maxX = chartData.map((data) => data.x).reduce((a, b) => a.isAfter(b) ? a : b);

    // Ustawiamy domyślny zakres (7:00 - 24:00)
    DateTime defaultMinX = DateTime(day.date.year, day.date.month, day.date.day, 7, 0);
    DateTime defaultMaxX = DateTime(day.date.year, day.date.month, day.date.day, 23, 59);

    // Używamy wcześniejszego czasu jeśli dane wykraczają poza 7:00
    DateTime visibleMinX = minX.isBefore(defaultMinX) ? minX : defaultMinX;
    // Używamy późniejszego czasu jeśli dane wykraczają poza 24:00
    DateTime visibleMaxX = maxX.isAfter(defaultMaxX) ? maxX : defaultMaxX;

    double minY = chartData.map((data) => data.y).reduce((a, b) => a < b ? a : b);
    double maxY = chartData.map((data) => data.y).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SfCartesianChart(
        enableAxisAnimation: false,
        primaryXAxis: DateTimeAxis(
          intervalType: DateTimeIntervalType.hours,
          dateFormat: DateFormat('HH'),
          majorGridLines: const MajorGridLines(width: 0),
          visibleMinimum: visibleMinX,
          visibleMaximum: visibleMaxX,
        ),
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
        series: <ChartSeries<ChartData, DateTime>>[
          LineSeries<ChartData, DateTime>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            animationDuration: 0,
          ),
          ScatterSeries<ChartData, DateTime>(
            dataSource: day.notes.map((note) {
              return ChartData(
                note.timestamp,
                100, // Set note markers Y value to 100
              );
            }).toList(),
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              color: Colors.blue,
            ),
            animationDuration: 0,
          ),
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

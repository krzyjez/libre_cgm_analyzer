import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'chart_data.dart';
import 'model.dart';

class DayCardBuilder {
  /// Buduje widżet karty dla danego dnia.
  ///
  /// Zawiera nagłówek z datą i obszar roboczy z trzema wierszami.
  static Widget buildDayCard(BuildContext context, DayData day, int treshold) {
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
            _buildHeader(context, day),
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
  static Widget _buildHeader(BuildContext context, DayData day) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12.0),
        topRight: Radius.circular(12.0),
      ),
      child: Container(
        width: double.infinity,
        color: Colors.green[900],
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data: ${DateFormat('yyyy-MM-dd').format(day.date)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () {
                // Przygotowanie tekstu z wartościami
                String values = day.measurements
                    .map((m) => '${DateFormat('HH:mm').format(m.timestamp)}: ${m.glucoseValue} mg/dL')
                    .join('\n');

                // Wyświetlenie dialogu
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Pomiary z dnia ${DateFormat('yyyy-MM-dd').format(day.date)}'),
                    content: SingleChildScrollView(
                      child: Text(values),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Zamknij'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
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
      color: Colors.white, // Kolor tła dla drugiego kontenera
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Wyrównanie do góry
        children: [
          Expanded(
            child: _buildChart(day, treshold),
          ),
          SizedBox(
            width: 200,
            child: _buildStats(day),
          ),
        ],
      ),
    );
  }

  /// Buduje wykres na podstawie danych dnia.
  static Widget _buildChart(DayData day, int treshold) {
    // Przygotowanie danych do wykresu
    final chartData = day.measurements
        .map((measurement) => ChartData(measurement.timestamp, measurement.glucoseValue as double))
        .toList();

    // Tworzenie wykresu SfCartesianChart z dwoma seriami danych
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: 300,
      child: SfCartesianChart(
        plotAreaBackgroundColor: Colors.white, // Ustawienie białego tła
        primaryXAxis: _buildXAxis(chartData, day.date),
        primaryYAxis: _buildYAxis(chartData, treshold),
        series: <ChartSeries<ChartData, DateTime>>[
          // Seria liniowa - pokazuje odczyty glukozy w czasie
          LineSeries<ChartData, DateTime>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            markerSettings:
                MarkerSettings(isVisible: true, shape: DataMarkerType.circle, color: Colors.blue, height: 4, width: 4),
            animationDuration: 0,
          ),
          // Seria punktowa - pokazuje miejsca, gdzie dodano notatki
          ScatterSeries<ChartData, DateTime>(
            dataSource: day.notes.map((note) => ChartData(note.timestamp, 100)).toList(),
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            markerSettings: MarkerSettings(isVisible: true, shape: DataMarkerType.circle, color: Colors.amber),
            animationDuration: 0,
          ),
        ],
      ),
    );
  }

  /// Konfiguracja osi X (czasu)
  static DateTimeAxis _buildXAxis(List<ChartData> chartData, DateTime date) {
    // Obliczenie zakresu osi X
    DateTime minX = chartData.map((data) => data.x).reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime maxX = chartData.map((data) => data.x).reduce((a, b) => a.isAfter(b) ? a : b);

    // Domyślny zakres (7:00 - 24:00)
    DateTime defaultMinX = DateTime(date.year, date.month, date.day, 7, 0);
    DateTime defaultMaxX = DateTime(date.year, date.month, date.day, 23, 59);

    minX = minX.isBefore(defaultMinX) ? minX : defaultMinX;
    maxX = maxX.isAfter(defaultMaxX) ? maxX : defaultMaxX;

    return DateTimeAxis(
      minimum: minX,
      maximum: maxX,
      intervalType: DateTimeIntervalType.hours,
      interval: 1,
      dateFormat: DateFormat('HH'),
    );
  }

  /// Konfiguracja osi Y (poziomu glukozy)
  static NumericAxis _buildYAxis(List<ChartData> chartData, int treshold) {
    // Obliczenie zakresu osi Y
    double minY = chartData.map((data) => data.y).reduce((a, b) => a < b ? a : b);
    double maxY = chartData.map((data) => data.y).reduce((a, b) => a > b ? a : b);

    // Używamy 80 i 180 jako minimalne zakresy
    minY = minY < 80 ? minY : 80;
    maxY = maxY > 180 ? maxY : 180;

    return NumericAxis(
      minimum: minY,
      maximum: maxY,
      plotBands: <PlotBand>[
        PlotBand(start: 100, end: 100, borderColor: Colors.black, borderWidth: 2),
        PlotBand(start: treshold.toDouble(), end: treshold.toDouble(), borderColor: Colors.red, borderWidth: 2),
      ],
    );
  }

  /// Buduje sekcję statystyk pokazującą przekroczenia poziomu glukozy.
  static Widget _buildStats(DayData day) {
    // Jeśli nie ma przekroczeń, pokazujemy komunikat
    if (day.periods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: const Text('Brak przekroczeń progu'),
      );
    }

    // Lista widgetów z przekroczeniami
    List<Widget> periodWidgets = [];

    // Dodajemy nagłówek
    periodWidgets.add(Text('Przekroczenia: ${day.periods.length}', style: TextStyle(fontWeight: FontWeight.bold)));
    // odstęp
    periodWidgets.add(const SizedBox(height: 8));

    // Dodajemy każde przekroczenie do listy
    for (int i = 0; i < day.periods.length; i++) {
      var period = day.periods[i];
      periodWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text('${i + 1}. Przekroczenie ${period.highestMeasure}/${period.points}'),
        ),
      );
    }

    // Zwracamy kontener z listą przekroczeń
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.red[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: periodWidgets,
      ),
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

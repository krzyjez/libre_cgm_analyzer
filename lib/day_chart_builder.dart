import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';
import 'chart_data.dart';
import 'model.dart';
import 'day_controller.dart';

/// Klasa odpowiedzialna za budowanie wykresu dla karty dnia
class DayChartBuilder {
  // Stałe wykresu
  static const double chartHeight = 300.0;
  
  // Kolory
  static const noteColor = Colors.amber;
  static const glucoseColor = Colors.blue;
  
  // Zakresy osi Y
  static const double minYDefault = 80.0;  // minimalna wartość osi Y
  static const double maxYDefault = 180.0;  // maksymalna wartość osi Y
  static const double extraSpaceForLabel = 20.0;  // dodatkowa przestrzeń na etykietę

  // Zakresy osi X
  static const int defaultStartHour = 7;    // domyślna godzina początkowa
  static const int defaultEndHour = 23;     // domyślna godzina końcowa
  static const int defaultEndMinute = 59;   // domyślna minuta końcowa dla ostatniej godziny

  /// Buduje wykres na podstawie danych dnia
  static Widget build(BuildContext context, DayController controller, DayData day) {
    // Przygotowanie danych do wykresu
    final chartData = day.measurements
        .map((measurement) => ChartData(
              measurement.timestamp,
              controller.getAdjustedGlucoseValue(day.date, measurement.glucoseValue) as double,
            ))
        .toList();

    final tooltipBehavior = _buildTooltipBehavior(day);

    // Tworzenie wykresu SfCartesianChart z seriami danych
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: chartHeight,
      child: SfCartesianChart(
        plotAreaBackgroundColor: Colors.white,
        primaryXAxis: _buildXAxis(chartData, day.date),
        primaryYAxis: _buildYAxis(chartData, controller.treshold),
        tooltipBehavior: tooltipBehavior,
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
            dataSource: day.notes.map((note) => ChartData(note.timestamp, 100, tooltipText: "buba")).toList(),
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            dataLabelMapper: (ChartData data, _) => data.tooltipText,
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              color: noteColor,
              width: 10,
              height: 10,
            ),
            animationDuration: 0,
          ),
          // Seria dla punktów maksymalnych
          ScatterSeries<ChartData, DateTime>(
            dataSource: day.periods.map((period) => ChartData(
              period.periodMeasurements.firstWhere((m) => 
                m.glucoseValue == period.highestMeasure).timestamp,
              controller.getAdjustedGlucoseValue(day.date, period.highestMeasure) as double,
              tooltipText: period.points.toString()
            )).toList(),
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            dataLabelMapper: (ChartData data, _) => data.tooltipText,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.top,
              textStyle: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              color: Colors.red,
              width: 6,
              height: 6,
            ),
            animationDuration: 0,
          ),
        ],
      ),
    );
  }

  /// Buduje zachowanie tooltipa dla wykresu.
  ///
  /// Metoda tworzy tooltipa, który wyświetla różne informacje w zależności od serii danych:
  /// - dla notatek (seriesIndex == 1) wyświetla czas i treść notatki na żółtym tle
  /// - dla pomiarów glukozy (seriesIndex == 0) wyświetla czas i wartość pomiaru na niebieskim tle
  static TooltipBehavior _buildTooltipBehavior(DayData day) {
    return TooltipBehavior(
      enable: true,
      color: Colors.white, // daje biały kolor gdyż gdy później przychodzi kontener z decoration
      //i właściwym kolorem to widać minimalną czarną ramkę, która jest nierwówna

      /// Builder jest wywoływany za każdym razem, gdy ma być wyświetlony tooltip.
      /// Parametry:
      /// - data: dane punktu (ChartData dla pomiarów glukozy)
      /// - point: fizyczne współrzędne punktu na wykresie (x,y)
      /// - series: cała seria danych do której należy punkt
      /// - pointIndex: indeks punktu w danej serii (np. która to notatka)
      /// - seriesIndex: numer serii (0: pomiary glukozy, 1: notatki)
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
        // Wybór koloru tła w zależności od typu serii
        final color = seriesIndex == 1 ? noteColor : glucoseColor;

        // Formatowanie tekstu w zależności od typu serii
        final text = seriesIndex == 1
            ? "${DateFormat('HH:mm').format(day.notes[pointIndex].timestamp)} ${day.notes[pointIndex].note}" // format dla notatek
            : "${DateFormat('HH:mm').format((data as ChartData).x)} ${data.y.toStringAsFixed(1)} mg/dL"; // format dla pomiarów

        // Zwracamy kontener z odpowiednim kolorem tła i sformatowanym tekstem
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color),
          child: Text(text, style: TextStyle(color: seriesIndex == 1 ? Colors.black : Colors.white)),
        );
      },
    );
  }

  /// Konfiguracja osi X (czasu)
  static DateTimeAxis _buildXAxis(List<ChartData> chartData, DateTime date) {
    // Obliczenie zakresu osi X na podstawie danych
    DateTime minX = chartData.map((data) => data.x).reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime maxX = chartData.map((data) => data.x).reduce((a, b) => a.isAfter(b) ? a : b);

    // Domyślny zakres
    DateTime defaultMinX = DateTime(date.year, date.month, date.day, defaultStartHour, 0);
    DateTime defaultMaxX = DateTime(date.year, date.month, date.day, defaultEndHour, defaultEndMinute);

    // Używamy szerszego zakresu: albo domyślnego, albo wynikającego z danych
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

    // Używamy domyślnych zakresów
    minY = minY < minYDefault ? minY : minYDefault;
    
    // Maksimum to większa z wartości: maxYDefault lub maksymalna wartość + miejsce na etykietę
    maxY = max(maxYDefault, maxY + extraSpaceForLabel);

    return NumericAxis(
      minimum: minY,
      maximum: maxY,
      plotBands: <PlotBand>[
        PlotBand(start: 100, end: 100, borderColor: Colors.black, borderWidth: 2),
        PlotBand(start: treshold.toDouble(), end: treshold.toDouble(), borderColor: Colors.red, borderWidth: 2),
      ],
    );
  }
}

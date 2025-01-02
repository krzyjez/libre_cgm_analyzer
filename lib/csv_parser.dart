// Klasa parsuje plik CSV i tworzy obiekty Measurement i Note
// CSV zaweira trzy rodzaje wierszy które nas interesują:
// 1. wiersz z wartością glukozy typu 1 - to przykładowy wers:
// FreeStyle LibreLink,ec45824e-2cd0-4a9b-9dd5-57d606627749,10-12-2024 17:22,1,,104,,,,,,,,,,,,,,
// Glucose value is at index 5
// 2. oraz drugi wiersz z wartością glukozy typu 0 - to przykładowy wiersz:
// FreeStyle LibreLink,ec45824e-2cd0-4a9b-9dd5-57d606627749,11-12-2024 16:05,0,123,,,,,,,,,,,,,,
// Prawdopodobnie typy te odpowiadają pomiarowi automatycznemu (zapisanemu w urządzeniu) oraz ręcznemu
// Glucose value is at index 4
// 3. wiersz z notą - to przykładowy wiersz:
// FreeStyle LibreLink,ec45824e-2cd0-4a9b-9dd5-57d606627749,10-12-2022 14:12,6,,,,,,,,,,Kasza bulgur,,,,,
// Note is at index 13
import 'package:intl/intl.dart';
import 'dart:convert';
import 'model.dart';
import 'logger.dart';
import 'glucose_calculator.dart';

class CsvParser {
  final _logger = Logger('CsvParser');

  // private fields
  List<List<String>> _data = []; // Surowe dane z pliku CSV
  List<DayData> _days = []; // Przetworzone dane pogrupowane po dniach

  // getters
  /// Zwraca niemutowalną listę dni z danymi
  List<DayData> get days => List.unmodifiable(_days);

  /// Zwraca liczbę wierszy w pliku CSV
  int get rowCount => _data.length;

  /// Parsuje zawartość pliku CSV i tworzy strukturę danych.
  ///
  /// Parametry:
  /// - `csvContent`: Zawartość pliku CSV jako string
  /// - `glucoseThreshold`: Próg wysokiego poziomu glukozy używany do analizy
  void parseCsv(String csvContent, int glucoseThreshold) {
    // Dekodujemy zawartość CSV z UTF-8
    final decodedContent = utf8.decode(csvContent.codeUnits, allowMalformed: true);
    _data = decodedContent.split('\n').map((line) => line.split(',')).toList();

    // Przetwarzanie wierszy CSV
    Map<DateTime, DayData> daysMap = {};

    for (var line in _data) {
      if (line.length < 12) continue; // Skip malformed lines

      var timestamp = _parseDate(line[2]);

      if (timestamp == null) continue;

      var dateOnly = DateTime(timestamp.year, timestamp.month, timestamp.day);

      var measurement = _tryParseMeasurement(line);
      if (measurement != null) {
        if (!daysMap.containsKey(dateOnly)) {
          daysMap[dateOnly] = DayData(dateOnly);
        }
        daysMap[dateOnly]?.measurements.add(measurement);
      }

      if (line[13].isNotEmpty) {
        // Note
        String noteText = line[13];
        Note note = Note(timestamp, noteText);
        if (!daysMap.containsKey(dateOnly)) {
          daysMap[dateOnly] = DayData(dateOnly);
        }
        daysMap[dateOnly]?.notes.add(note);
      }
    }

    _days = daysMap.values.toList();
    // sotujemy dni po dacie pierwsza jest najnowsza
    _days.sort((a, b) => b.date.compareTo(a.date));

    // Analizujemy okresy wysokiego poziomu glukozy dla każdego dnia
    for (var day in _days) {
      day.periods.addAll(analyzeHighGlucose(day.measurements, glucoseThreshold));
    }

    // wypisujemy liczbe dni
    _logger.info('Parsed ${_days.length} days');
  }

  /// Parsuje datę w formacie dd-MM-yyyy HH:mm.
  ///
  /// Przykład: "10-12-2024 17:22"
  ///
  /// Zwraca:
  /// - DateTime jeśli parsowanie się powiodło
  /// - null jeśli format daty jest nieprawidłowy
  DateTime? _parseDate(String dateTimeString) {
    try {
      final dateTime = DateFormat('dd-MM-yyyy HH:mm').parse(dateTimeString);
      return dateTime;
    } catch (e) {
      _logger.error('Invalid date format: $dateTimeString');
      return null;
    }
  }

  /// Próbuje sparsować wiersz jako pomiar glukozy.
  /// Obsługuje dwa typy pomiarów:
  /// - Typ 0 (automatyczny) - wartość glukozy w indeksie 4
  /// - Typ 1 (ręczny) - wartość glukozy w indeksie 5
  ///
  /// Zwraca:
  /// - Measurement jeśli wiersz zawiera poprawny pomiar
  /// - null jeśli wiersz nie jest pomiarem lub jest niepoprawny
  Measurement? _tryParseMeasurement(List<String> line) {
    if (line.length < 6) return null;

    var timestamp = _parseDate(line[2]);
    if (timestamp == null) return null;

    var type = int.tryParse(line[3]);
    if (type == null || (type != 0 && type != 1)) return null;

    // Wybierz odpowiedni indeks w zależności od typu pomiaru
    var glucoseIndex = type == 0 ? 4 : 5;

    var glucoseStr = line[glucoseIndex];
    if (glucoseStr.isEmpty) return null;

    var glucose = int.tryParse(glucoseStr);
    if (glucose == null) return null;

    return Measurement(timestamp, glucose);
  }

  /// Analizuje okresy wysokiego poziomu glukozy i oblicza ich nasilenie.
  ///
  /// Parametry:
  /// - `measurements`: Lista obiektów `Measurement`, zawierająca dane pomiarowe z danego dnia.
  /// - `glucoseThreshold`: Wartość progowa glukozy, powyżej której pomiary są uznawane za wysokie.
  ///
  /// Zwraca listę obiektów `Period` z czasem rozpoczęcia i zakończenia, punktami i najwyższym pomiarem.
  List<Period> analyzeHighGlucose(List<Measurement> measurements, int glucoseThreshold) {
    List<Period> highPeriods = [];
    DateTime? periodStartTime;
    int highestMeasure = 0;
    List<Measurement> periodMeasurements = [];
    bool wasAboveThreshold = false;

    // Sort measurements by timestamp
    measurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var i = 0; i < measurements.length; i++) {
      var measurement = measurements[i];
      bool isAboveThreshold = measurement.glucoseValue > glucoseThreshold;

      // Jeśli przekraczamy próg, a poprzednio byliśmy poniżej
      if (isAboveThreshold && !wasAboveThreshold && i > 0) {
        // Dodaj poprzedni pomiar (poniżej progu) do okresu
        periodStartTime = measurements[i - 1].timestamp;
        periodMeasurements.add(measurements[i - 1]);
        periodMeasurements.add(measurement);
        highestMeasure = measurement.glucoseValue;
      }
      // Jeśli kontynuujemy okres powyżej progu
      else if (isAboveThreshold && wasAboveThreshold) {
        periodMeasurements.add(measurement);
        if (measurement.glucoseValue > highestMeasure) {
          highestMeasure = measurement.glucoseValue;
        }
      }
      // Jeśli schodzimy poniżej progu, a poprzednio byliśmy powyżej
      else if (!isAboveThreshold && wasAboveThreshold && periodStartTime != null) {
        // Dodaj aktualny pomiar (poniżej progu) do okresu
        periodMeasurements.add(measurement);

        var periodEndTime = measurement.timestamp;
        int points = calculatePoints(periodMeasurements, glucoseThreshold);
        var period = Period(
          startTime: periodStartTime,
          endTime: periodEndTime,
          points: points,
          highestMeasure: highestMeasure,
        );
        period.periodMeasurements.addAll(periodMeasurements);
        highPeriods.add(period);

        // Reset zmiennych na potrzeby następnego okresu
        periodStartTime = null;
        periodMeasurements = [];
        highestMeasure = 0;
      }

      wasAboveThreshold = isAboveThreshold;
    }

    // Obsłuż przypadek, gdy okres wysokiego poziomu kończy się ostatnim pomiarem dnia
    if (periodStartTime != null && periodMeasurements.isNotEmpty && wasAboveThreshold) {
      // Dodajemy sztuczny punkt końcowy na tym samym poziomie co ostatni pomiar
      var lastMeasurement = measurements.last;
      periodMeasurements.add(lastMeasurement);

      int points = calculatePoints(periodMeasurements, glucoseThreshold);
      var period = Period(
        startTime: periodStartTime,
        endTime: lastMeasurement.timestamp,
        points: points,
        highestMeasure: highestMeasure,
      );
      period.periodMeasurements.addAll(periodMeasurements);
      highPeriods.add(period);
    }

    return highPeriods;
  }

  /// Oblicza punkty dla okresu wysokiego poziomu glukozy.
  ///
  /// Parametry:
  /// - `measurements`: Lista pomiarów w danym okresie
  /// - `glucoseThreshold`: Próg, powyżej którego glukoza jest uznawana za wysoką
  ///
  /// Zwraca:
  /// Liczbę punktów reprezentującą ważone pole powierzchni nad linią threshold
  int calculatePoints(List<Measurement> measurements, int glucoseThreshold) {
    if (measurements.length < 2) return 0;

    double points = GlucoseAreaCalculator.calculateAreaAboveThreshold(measurements, glucoseThreshold);
    return points.round();
  }
}

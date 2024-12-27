// Klasa parsuje plik CSV i tworzy obiekty Measurement i Note
// CSV zaweira trzy rodzaje wierszy które nas interesują:
// 1. wiersz z wartością glukozy typu 1 - to przykładowy wers:
// FreeStyle LibreLink,ec45824e-2cd0-4a9b-9dd5-57d606627749,10-12-2024 17:22,1,,104,,,,,,,,,,,,,
// Glucose value is at index 5
// 2. oraz drugi wiersz z wartością glukozy typu 0 - to przykładowy wiersz:
// FreeStyle LibreLink,ec45824e-2cd0-4a9b-9dd5-57d606627749,11-12-2024 16:05,0,123,,,,,,,,,,,,,,
// Prawdopodobnie typy te odpowiadają pomiarowi automatycznemu (zapisanemu w urządzeniu) oraz ręcznemu
// Glucose value is at index 4
// 3. wiersz z notą - to przykładowy wiersz:
// FreeStyle LibreLink,ec45824e-2cd0-4a9b-9dd5-57d606627749,10-12-2022 14:12,6,,,,,,,,,,Kasza bulgur,,,,,
// Note is at index 13
import 'package:intl/intl.dart';
import 'model.dart';

class CsvParser {
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
    _data = csvContent.split('\n').map((line) => line.split(',')).toList();

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
    print('Parsed ${_days.length} days');
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
      print('Invalid date format: $dateTimeString');
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

    // Sort measurements by timestamp
    measurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var i = 0; i < measurements.length; i++) {
      var measurement = measurements[i];

      if (measurement.glucoseValue > glucoseThreshold) {
        // Rozpocznij nowy okres lub kontynuuj istniejący
        periodStartTime ??= measurement.timestamp;
        periodMeasurements.add(measurement);
        // Aktualizuj najwyższy pomiar w okresie
        if (measurement.glucoseValue > highestMeasure) {
          highestMeasure = measurement.glucoseValue.toInt();
        }
      } else if (periodStartTime != null) {
        // Zakończ bieżący okres wysokiego poziomu glukozy
        var periodEndTime = measurement.timestamp;
        int points = calculatePoints(periodMeasurements, glucoseThreshold);
        highPeriods.add(Period(
          startTime: periodStartTime,
          endTime: periodEndTime,
          points: points,
          highestMeasure: highestMeasure,
        ));
        // Reset zmiennych na potrzeby następnego okresu
        periodStartTime = null;
        periodMeasurements.clear();
        highestMeasure = 0;
      }
    }

    // Obsłuż przypadek, gdy okres wysokiego poziomu kończy się ostatnim pomiarem dnia
    if (periodStartTime != null) {
      int points = calculatePoints(periodMeasurements, glucoseThreshold);
      highPeriods.add(Period(
        startTime: periodStartTime,
        endTime: measurements.last.timestamp,
        points: points,
        highestMeasure: highestMeasure,
      ));
    }

    return highPeriods;
  }

  /// Oblicza punkty dla okresu wysokiego poziomu glukozy.
  ///
  /// Punkty są obliczane jako suma pól powierzchni nad linią threshold.
  /// Dla każdej minuty między pomiarami:
  /// 1. Interpoluje wartość glukozy
  /// 2. Jeśli wartość > threshold, dodaje (wartość - threshold) do sumy
  ///
  /// Parametry:
  /// - `measurements`: Lista pomiarów w danym okresie
  /// - `glucoseThreshold`: Próg, powyżej którego glukoza jest uznawana za wysoką
  ///
  /// Zwraca:
  /// Liczbę punktów reprezentującą pole powierzchni nad linią threshold
  int calculatePoints(List<Measurement> measurements, int glucoseThreshold) {
    if (measurements.length < 2) return 0;
    int totalPoints = 0;

    for (var i = 0; i < measurements.length - 1; i++) {
      var start = measurements[i];
      var end = measurements[i + 1];

      // Oblicz różnicę czasu w minutach
      var minutesDiff = end.timestamp.difference(start.timestamp).inMinutes;
      if (minutesDiff <= 0) continue;

      // Oblicz współczynnik zmiany glukozy na minutę
      var glucoseChange = (end.glucoseValue - start.glucoseValue) / minutesDiff;

      // Dla każdej minuty w przedziale
      for (var minute = 0; minute < minutesDiff; minute++) {
        // Interpoluj wartość glukozy dla danej minuty
        var interpolatedGlucose = start.glucoseValue + (glucoseChange * minute);

        // Jeśli wartość przekracza threshold, dodaj różnicę do sumy
        if (interpolatedGlucose > glucoseThreshold) {
          totalPoints += (interpolatedGlucose - glucoseThreshold).round();
        }
      }
    }

    return totalPoints;
  }
}

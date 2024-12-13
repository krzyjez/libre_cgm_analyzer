// Klasa parsuje plik CSV i tworzy obiekty Measurement i Note
// CSV zaweira dwa rodzaje wierszy które nas interesują:
// 1. wiersz z wartością glukozy - to przykładowy wers:
// FreeStyle LibreLink,ec45824e-2cd0-4a9b-9dd5-57d606627749,10-12-2024 17:22,1,,104,,,,,,,,,,,,,
// Glucose value is at index 5
// 2. wiersz z notą - to przykładowy wiersz:
// FreeStyle LibreLink,ec45824e-2cd0-4a9b-9dd5-57d606627749,10-12-2022 14:12,6,,,,,,,,,,Kasza bulgur,,,,,
// Note is at index 13
import 'package:intl/intl.dart';

class CsvParser {
  // private
  List<List<String>> _data = [];
  List<DayData> _days = [];

  // getters
  List<DayData> get days => List.unmodifiable(_days);
  int get rowCount => _data.length;

  void parseCsv(String csvContent) {
    _data = csvContent.split('\n').map((line) => line.split(',')).toList();

    // Przetwarzanie wierszy CSV
    Map<DateTime, DayData> daysMap = {};

    for (var line in _data) {
      if (line.length < 14) continue; // Skip malformed lines

      var timestamp = _parseDate(line[2]);

      if (timestamp == null) continue;

      var dateOnly = DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (line[5].isNotEmpty) {
        // Glucose measurement
        int glucoseValue = int.parse(line[5]);
        Measurement measurement = Measurement(timestamp, glucoseValue);
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
    // wypisujemy liczbe dni
    print('Parsed ${_days.length} days');
  }

  // Parsuje date w formcie 10-12-2024 17:22
  DateTime? _parseDate(String dateTimeString) {
    try {
      final dateTime = DateFormat('dd-MM-yyyy HH:mm').parse(dateTimeString);
      return dateTime;
    } catch (e) {
      print('Invalid date format: $dateTimeString');
      return null;
    }
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
      bool isHigh = measurement.glucoseValue > glucoseThreshold;

      if (isHigh) {
        periodStartTime ??= measurement.timestamp;
        periodMeasurements.add(measurement);
        if (measurement.glucoseValue > highestMeasure) {
          highestMeasure = measurement.glucoseValue;
        }
      } else if (periodStartTime != null) {
        // End current period
        var periodEndTime = measurement.timestamp;
        int points = calculatePoints(periodMeasurements, glucoseThreshold);
        highPeriods.add(Period(
          startTime: periodStartTime,
          endTime: periodEndTime,
          points: points,
          highestMeasure: highestMeasure,
        ));
        periodStartTime = null;
        periodMeasurements.clear();
        highestMeasure = 0;
      }
    }

    // Handle case where period extends to the end of the day
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

  int calculatePoints(List<Measurement> measurements, int glucoseThreshold) {
    int points = 0;
    for (var i = 0; i < measurements.length - 1; i++) {
      var currentValue = measurements[i].glucoseValue;
      var currentTime = measurements[i].timestamp;
      var nextTime = measurements[i + 1].timestamp;
      var durationMinutes = nextTime.difference(currentTime).inMinutes;
      points += (currentValue - glucoseThreshold) * durationMinutes;
    }
    return points;
  }
}

class Measurement {
  final DateTime timestamp;
  final int glucoseValue;

  Measurement(this.timestamp, this.glucoseValue);
}

class Note {
  final DateTime timestamp;
  final String note;

  Note(this.timestamp, this.note);
}

/// Dane dla pojedyczego dnia - z systemu LibreCGM
class DayData {
  final DateTime date;
  final List<Measurement> measurements = [];
  final List<Note> notes = [];
  final List<Period> periods = [];

  DayData(this.date);
}

/// Dane dla pojedynczego dnia - pochodzące od użytkownika
class DayUser {
  final DateTime date;
  final List<String> comments = [];
  final List<Note> notes = [];

  DayUser(this.date);
}

/// Wszystkie dane związane z użytkownikiem
class UserInfo {
  final int treshold = 140;
  final List<DayUser> days = [];
}

/// Zawiera dane pojedynczego okresu - przekroczenia progru bezpieczeństwa wysokości glukozy
class Period {
  final DateTime startTime;
  final DateTime endTime;

  final int points;
  final int highestMeasure;

  Period({required this.startTime, required this.endTime, required this.points, required this.highestMeasure});
}

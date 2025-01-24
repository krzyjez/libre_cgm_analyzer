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
import 'model.dart';
import 'logger.dart';

class CsvParser {
  static final _logger = Logger('CsvParser');
  static const dayEndHour = 4;

  /// Parsuje zawartość pliku CSV i zwraca listę dni z danymi.
  ///
  /// Parametry:
  /// - `csvContent`: Zawartość pliku CSV jako string
  /// - `glucoseThreshold`: Próg wysokiego poziomu glukozy używany do analizy
  /// - `userInfo`: Dane użytkownika zawierające offsety dla dni
  static List<DayData> parseCsv(String csvContent, int glucoseThreshold, UserInfo userInfo) {
    List<List<String>> data;
    try {
      // Przetwarzanie wierszy CSV
      data = csvContent.split('\n').map((line) => line.split(',')).toList();
    } catch (e) {
      _logger.error('Nie udało się przetworzyć pliku CSV: $e');
      return [];
    }

    // Przetwarzanie wierszy CSV
    Map<DateTime, DayData> daysMap = {};

    for (var line in data) {
      if (line.length < 12) continue; // Skip malformed lines

      var timestamp = _parseDate(line[2]);
      if (timestamp == null) continue;

      // Pobierz lub stwórz dzień dla tego timestampa
      // Pomiary przed dayEndHour są traktowane jako część poprzedniego dnia
      final displayDate = timestamp.hour < dayEndHour ? 
          timestamp.subtract(const Duration(days: 1)) : timestamp;
      var date = DateTime(displayDate.year, displayDate.month, displayDate.day);
      var day = daysMap[date] ?? DayData(date);

      var measurement = _tryParseMeasurement(line);
      if (measurement != null) {
        day.measurements.add(measurement);
      }

      if (line[13].isNotEmpty) {
        // Note
        String noteText = line[13];
        Note note = Note(timestamp, noteText);
        day.notes.add(note);
      }
      daysMap[date] = day;
    }

    List<DayData> days = daysMap.values.toList();
    // sotujemy dni po dacie pierwsza jest najnowsza
    days.sort((a, b) => b.date.compareTo(a.date));

    // Analizujemy okresy wysokiego poziomu glukozy dla każdego dnia
    for (var day in days) {
      day.periods.addAll(_analyzeHighGlucose(
        day.measurements,
        glucoseThreshold,
        day.date,
        userInfo,
      ));
    }

    // wypisujemy liczbe dni
    _logger.info('Parsed ${days.length} days');

    return days;
  }

  /// Parsuje datę w formacie dd-MM-yyyy HH:mm.
  ///
  /// Przykład: "10-12-2024 17:22"
  ///
  /// Zwraca:
  /// - DateTime jeśli parsowanie się powiodło
  /// - null jeśli format daty jest nieprawidłowy
  static DateTime? _parseDate(String dateTimeString) {
    try {
      final dateTime = DateFormat('dd-MM-yyyy HH:mm').parse(dateTimeString);
      return dateTime;
    } catch (e) {
      //_logger.error('Invalid date format: $dateTimeString');
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
  static Measurement? _tryParseMeasurement(List<String> line) {
    try {
      var timestamp = _parseDate(line[2]);
      if (timestamp == null) return null;

      var type = int.tryParse(line[3]);
      if (type == null) return null;

      int? glucoseValue;
      if (type == 0) {
        glucoseValue = int.tryParse(line[4]);
      } else if (type == 1) {
        glucoseValue = int.tryParse(line[5]);
      }

      if (glucoseValue == null) return null;

      // Używamy oryginalnego timestamp'a
      return Measurement(timestamp, glucoseValue);
    } catch (e) {
      _logger.error('Błąd podczas parsowania pomiaru: $e');
      return null;
    }
  }

  /// Analizuje okresy wysokiego poziomu glukozy i oblicza ich nasilenie.
  ///
  /// Parametry:
  /// - `measurements`: Lista obiektów `Measurement`, zawierająca dane pomiarowe z danego dnia.
  /// - `glucoseThreshold`: Wartość progowa glukozy, powyżej której pomiary są uznawane za wysokie.
  /// - `date`: Data dnia dla któryiego analizujemy pomiary (potrzebna do znalezienia offsetu)
  /// - `userInfo`: Dane użytkownika zawierające offsety dla dni
  ///
  /// Zwraca listę obiektów `Period` z czasem rozpoczęcia i zakończenia, punktami i najwyższym pomiarem.
  static List<Period> _analyzeHighGlucose(
      List<Measurement> measurements, int glucoseThreshold, DateTime date, UserInfo userInfo) {
    List<Period> highPeriods = [];
    DateTime? periodStartTime;
    int highestMeasure = 0;
    List<Measurement> periodMeasurements = [];
    bool wasAboveThreshold = false;

    // Znajdź offset dla tego dnia
    int offset = 0;

    final dayUser = userInfo.days.firstWhere(
      (d) => d.date.year == date.year && d.date.month == date.month && d.date.day == date.day,
      orElse: () => DayUser(date),
    );
    offset = dayUser.offset;

    // Sort measurements by timestamp
    measurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var i = 0; i < measurements.length; i++) {
      var measurement = measurements[i];
      // Uwzględnij offset przy sprawdzaniu przekroczenia progu
      bool isAboveThreshold = (measurement.glucoseValue + offset) > glucoseThreshold;

      // Jeśli przekraczamy próg, a poprzednio byliśmy poniżej
      if (isAboveThreshold && !wasAboveThreshold && i > 0) {
        // Dodaj poprzedni pomiar (poniżej progu) do okresu
        periodStartTime = measurements[i - 1].timestamp;
        periodMeasurements.add(measurements[i - 1]);
        periodMeasurements.add(measurement);
        highestMeasure = measurement.glucoseValue + offset;
      }
      // Jeśli kontynuujemy okres powyżej progu
      else if (isAboveThreshold && wasAboveThreshold) {
        periodMeasurements.add(measurement);
        if (measurement.glucoseValue + offset > highestMeasure) {
          highestMeasure = measurement.glucoseValue + offset;
        }
      }
      // Jeśli schodzimy poniżej progu, a poprzednio byliśmy powyżej
      else if (!isAboveThreshold && wasAboveThreshold && periodStartTime != null) {
        // Dodaj aktualny pomiar (poniżej progu) do okresu
        periodMeasurements.add(measurement);

        var periodEndTime = measurement.timestamp;
        int points = _calculatePoints(periodMeasurements, glucoseThreshold, offset);
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
    if (wasAboveThreshold && periodStartTime != null && periodMeasurements.isNotEmpty) {
      var lastMeasurement = measurements.last;
      periodMeasurements.add(lastMeasurement);

      int points = _calculatePoints(periodMeasurements, glucoseThreshold, offset);
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
  /// - `glucoseThreshold`: Próg, powyżej któryego glukoza jest uznawana za wysoką
  /// - `offset`: Offset do dodania do każdego pomiaru
  ///
  /// Zwraca:
  /// Liczbę punktów reprezentującą ważone pole powierzchni nad linią threshold
  static int _calculatePoints(List<Measurement> measurements, int glucoseThreshold, int offset) {
    if (measurements.isEmpty) return 0;

    int points = 0;
    for (var i = 0; i < measurements.length - 1; i++) {
      var current = measurements[i];
      var next = measurements[i + 1];

      // Dodaj offset do wartości glukozy
      var currentValue = current.glucoseValue + offset;
      var nextValue = next.glucoseValue + offset;

      // Oblicz pole powierzchni tylko jeśli przynajmniej jedna wartość jest powyżej progu
      if (currentValue > glucoseThreshold || nextValue > glucoseThreshold) {
        // Weź wartości powyżej progu
        var currentAbove = (currentValue > glucoseThreshold) ? currentValue - glucoseThreshold : 0;
        var nextAbove = (nextValue > glucoseThreshold) ? nextValue - glucoseThreshold : 0;

        // Oblicz średnią wysokość i czas trwania w minutach
        var avgHeight = (currentAbove + nextAbove) / 2;
        var durationMinutes = next.timestamp.difference(current.timestamp).inMinutes;

        // Dodaj punkty (pole powierzchni * waga)
        points += (avgHeight * durationMinutes).round();
      }
    }

    return points;
  }
}

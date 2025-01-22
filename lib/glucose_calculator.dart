import 'dart:math' as math;
import 'model.dart';

// Klasa obliczająca zważoną powierzchnią powyżej progu
// więcej info można znaleźć w pliku: doc/calculations.md
class GlucoseAreaCalculator {
  /// Metoda obliczająca zważoną powierzchnię powyżej zadanego progu.
  static double calculateAreaAboveThreshold(List<Measurement> measurements, int threshold) {
    // Sortujemy pomiary po czasie.
    measurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalArea = 0.0;

    // Iterujemy po parach kolejnych pomiarów
    for (var i = 0; i < measurements.length - 1; i++) {
      final current = measurements[i];
      final next = measurements[i + 1];

      // Wyznaczamy odstęp czasu pomiędzy kolejnymi pomiarami (w minutach).
      final double deltaTime = next.timestamp.difference(current.timestamp).inMinutes.toDouble();
      if (deltaTime <= 0) {
        continue;
      }

      // Obliczamy przekroczenie progu dla obu pomiarów.
      final double excessCurrent =
          (current.glucoseValue > threshold) ? (current.glucoseValue - threshold).toDouble() : 0.0;

      final double excessNext = (next.glucoseValue > threshold) ? (next.glucoseValue - threshold).toDouble() : 0.0;

      final double weightedExcessCurrent = _weightFunction(excessCurrent);
      final double weightedExcessNext = _weightFunction(excessNext);

      final bool currentAbove = current.glucoseValue > threshold;
      final bool nextAbove = next.glucoseValue > threshold;

      if (currentAbove && nextAbove) {
        // Odcinek w całości powyżej progu
        final double area = ((weightedExcessCurrent + weightedExcessNext) / 2.0) * deltaTime;
        totalArea += area;
      } else if (currentAbove && !nextAbove) {
        // Krzywa schodzi poniżej progu w środku odcinka
        final DateTime intersectionTime = _findIntersectionTime(
            current.timestamp, current.glucoseValue, next.timestamp, next.glucoseValue, threshold);

        final double partialDelta = intersectionTime.difference(current.timestamp).inMinutes.toDouble();
        final double area = ((weightedExcessCurrent + _weightFunction(0)) / 2.0) * partialDelta;
        totalArea += area;
      } else if (!currentAbove && nextAbove) {
        // Krzywa wchodzi powyżej progu w środku odcinka
        final DateTime intersectionTime = _findIntersectionTime(
            current.timestamp, current.glucoseValue, next.timestamp, next.glucoseValue, threshold);

        final double partialDelta = next.timestamp.difference(intersectionTime).inMinutes.toDouble();
        final double area = ((weightedExcessNext + _weightFunction(0)) / 2.0) * partialDelta;
        totalArea += area;
      }
    }

    return totalArea;
  }

  /// Funkcja wagująca przekroczenie.
  /// Przykładowo: W(e) = e^(1.585), gdzie 20 punktów nad progiem jest ~3x "gorsze" niż 10 punktów.
  static double _weightFunction(double excess) {
    // Możesz dobrać alpha, aby spełnić konkretne wymagania skalowania.
    const double alpha = 1.2;
    if (excess <= 0) return 0.0;
    return math.pow(excess, alpha).toDouble();
  }

  /// Metoda znajdująca punkt przecięcia z progiem (threshold) przy liniowej interpolacji.
  static DateTime _findIntersectionTime(
    DateTime time1,
    int glucose1,
    DateTime time2,
    int glucose2,
    int threshold,
  ) {
    final double fraction = (threshold - glucose1) / (glucose2 - glucose1);
    final Duration deltaTime = time2.difference(time1);
    final int offsetMicroseconds = (deltaTime.inMicroseconds * fraction).round();

    return time1.add(Duration(microseconds: offsetMicroseconds));
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'chart_data.dart';
import 'model.dart';
import 'logger.dart';

class DayCardBuilder {
  /// Buduje widżet karty dla danego dnia.
  ///
  /// Zawiera nagłówek z datą i obszar roboczy z trzema wierszami.
  static const double chartHeight = 300.0;
  static const noteColor = Colors.amber;
  static const glucoseColor = Colors.blue;

  static Widget buildDayCard(
    BuildContext context,
    DayData dayData,
    int treshold,
    DayUser? dayUser, {
    required Function(DateTime date, int offset) onOffsetChanged,
  }) {
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
            _buildHeader(context, dayData, dayUser),
            // Odstęp między nagłówkiem i obszarem roboczym
            const SizedBox(height: 4.0),
            // Obszar roboczy
            _buildWorkingArea(context, dayData, treshold),
          ],
        ),
      ),
    );
  }

  /// Buduje nagłówek dla karty dnia.
  ///
  /// Zawiera datę z zaokrąglonymi rogami i ciemnozielonym tłem.
  static Widget _buildHeader(BuildContext context, DayData dayData, DayUser? dayUser) {
    final offsetStr = dayUser?.offset != 0 ? ' (offset: ${dayUser?.offset})' : '';

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
              'Data: ${DateFormat('yyyy-MM-dd').format(dayData.date)}$offsetStr',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  tooltip: 'Ustaw offset',
                  onPressed: () => _showOffsetDialog(
                    context,
                    dayData.date,
                    dayUser?.offset ?? 0,
                    (date, offset) {},
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    // Przygotowanie tekstu z wartościami
                    String values = dayData.measurements
                        .map((m) => '${DateFormat('HH:mm').format(m.timestamp)}: ${m.glucoseValue} mg/dL')
                        .join('\n');

                    // Wyświetlenie dialogu
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Material(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Pomiary z dnia ${DateFormat('yyyy-MM-dd').format(dayData.date)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  child: Text(values),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Zamknij'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pokazuje dialog do ustawienia offsetu dla danego dnia
  static void _showOffsetDialog(
    BuildContext context,
    DateTime date,
    int currentOffset,
    Function(DateTime date, int offset) onOffsetChanged,
  ) {
    final controller = TextEditingController(text: currentOffset.toString());
    final logger = Logger('DayCardBuilder');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ustaw offset dla ${DateFormat('yyyy-MM-dd').format(date)}'),
        content: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): () {
              final newOffset = int.tryParse(controller.text) ?? 0;
              logger.info('Ustawiono nowy offset: $newOffset');
              onOffsetChanged(date, newOffset);
              Navigator.pop(context);
            },
            const SingleActivator(LogicalKeyboardKey.escape): () {
              Navigator.pop(context);
            },
          },
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Offset',
              hintText: 'Wprowadź wartość offsetu',
            ),
            onSubmitted: (value) {
              final newOffset = int.tryParse(value) ?? 0;
              logger.info('Ustawiono nowy offset: $newOffset');
              onOffsetChanged(date, newOffset);
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              final newOffset = int.tryParse(controller.text) ?? 0;
              logger.info('Ustawiono nowy offset: $newOffset');
              onOffsetChanged(date, newOffset);
              Navigator.pop(context);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  /// Buduje obszar roboczy dla karty dnia.
  /// Zawiera trzy wiersze z tekstem.
  static Widget _buildWorkingArea(BuildContext context, DayData day, int treshold) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Komentarze dzienne
          _buildDailyComments(context, day),
          // wykres i statystyki
          _buildChartAndStats(context, day, treshold),
          // notatki
          _buildNotes(context, day),
        ],
      ),
    );
  }

  /// Buduje sekcję komentarzy dziennych.
  static Widget _buildDailyComments(BuildContext context, DayData day) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blue[100], // Kolor tła dla pierwszego kontenera
      child: const Text('wiersz 1'),
    );
  }

  /// Buduje sekcję wykresu i statystyk.
  static Widget _buildChartAndStats(BuildContext context, DayData day, int treshold) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wykres
        Expanded(
          child: SizedBox(
            height: chartHeight,
            child: _buildChart(context, day, treshold),
          ),
        ),
        // Odstęp między wykresem a statystykami
        const SizedBox(width: 8),
        // Statystyki
        SizedBox(
          width: 220,
          height: chartHeight,
          child: _buildStats(context, day),
        ),
      ],
    );
  }

  /// Buduje wykres na podstawie danych dnia.
  static Widget _buildChart(BuildContext context, DayData day, int treshold) {
    // Przygotowanie danych do wykresu
    final chartData = day.measurements
        .map((measurement) => ChartData(measurement.timestamp, measurement.glucoseValue as double))
        .toList();

    final tooltipBehavior = _buildTooltipBehavior(day);

    // Tworzenie wykresu SfCartesianChart z dwoma seriami danych
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: chartHeight,
      child: SfCartesianChart(
        plotAreaBackgroundColor: Colors.white,
        primaryXAxis: _buildXAxis(chartData, day.date),
        primaryYAxis: _buildYAxis(chartData, treshold),
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
  static Widget _buildStats(BuildContext context, DayData day) {
    if (day.periods.isEmpty) {
      return Container(
          padding: const EdgeInsets.all(8.0),
          child: const Center(child: Icon(Icons.thumb_up, size: 90, color: Colors.green)));
    }

    // Lista widgetów z przekroczeniami
    List<Widget> periodWidgets = [];

    // Obliczamy sumę punktów
    final totalPoints = day.periods.fold(0, (sum, period) => sum + period.points);

    // Dodajemy nagłówek z liczbą przekroczeń i sumą punktów
    periodWidgets.add(Text('Przekroczenia: ${day.periods.length}/$totalPoints',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    // odstęp
    periodWidgets.add(const SizedBox(height: 8));

    // Dodajemy informacje o przekroczeniach
    for (var i = 0; i < day.periods.length; i++) {
      final period = day.periods[i];
      periodWidgets.add(
        InkWell(
          onTap: () => _showMeasurementsDialog(context, period),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '${i + 1}. Czas: ${DateFormat('HH:mm').format(period.startTime)} - ${DateFormat('HH:mm').format(period.endTime)}'
              '\nMax: ${period.highestMeasure} mg/dL'
              '\nPunkty: ${period.points}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      );
    }

    // Dodajemy odstęp
    periodWidgets.add(const SizedBox(height: 8));

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.red[50],
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: chartHeight, // używamy tej samej wysokości co wykres
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: periodWidgets,
          ),
        ),
      ),
    );
  }

  /// Wyświetla dialog z pomiarami dla danego okresu
  static void _showMeasurementsDialog(BuildContext context, Period period) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Material(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pomiary ${DateFormat('HH:mm').format(period.startTime)} - ${DateFormat('HH:mm').format(period.endTime)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: period.periodMeasurements
                          .map((m) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  '${DateFormat('HH:mm').format(m.timestamp)}: ${m.glucoseValue} mg/dL',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('Zamknij'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Buduje sekcję notatek.
  static Widget _buildNotes(BuildContext context, DayData day) {
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

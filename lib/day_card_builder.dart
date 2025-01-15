import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'chart_data.dart';
import 'model.dart';
import 'day_controller.dart';
import 'dialogs/comment_dialog.dart';
import 'dialogs/offset_dialog.dart';
import 'dialogs/measurements_dialog.dart';
import 'dialogs/note_dialog.dart';
import 'dialogs/image_dialog.dart';

class DayCardBuilder {
  static const double chartHeight = 300.0;
  static const noteColor = Colors.amber;
  static const glucoseColor = Colors.blue;

  /// Buduje widżet karty dla danego dnia
  /// To jest główny punkt wejścia - tworzy StatefulBuilder który pozwala na odświeżanie karty
  static Widget buildDayCard(BuildContext context, DayController controller, DayData day) {
    final dayUser = controller.findUserDayByDate(day.date);
    final isHidden = dayUser?.hidden ?? false;

    if (isHidden) {
      return _buildHiddenDayCard(context, controller, day);
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return _buildCardContent(context, controller, day, dayUser, setState);
      },
    );
  }

  /// Buduje uproszczony widok karty dla ukrytego dnia
  static Widget _buildHiddenDayCard(BuildContext context, DayController controller, DayData day) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 8.0,
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: Colors.grey[300],
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd').format(day.date),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Dzień wyłączony z powodu błędnych pomiarów',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'Przywróć wyświetlanie dnia',
                onPressed: () async {
                  final success = await controller.changeDayVisibility(day.date, false);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nie udało się przywrócić dnia'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tworzy zawartość karty dnia - to jest właściwy builder wywoływany przy każdym odświeżeniu
  /// [context] - kontekst Fluttera
  /// [controller] - kontroler danych
  /// [day] - dane dla danego dnia
  /// [setStateCallback] - funkcja do wymuszenia przerysowania karty
  static Widget _buildCardContent(
    BuildContext context,
    DayController controller,
    DayData day,
    DayUser? dayUser,
    StateSetter setStateCallback,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 8.0,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek karty (z offsetem)
            _buildHeader(context, controller, day, dayUser, setStateCallback),
            // Główna zawartość (wykres itp.)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: _buildWorkingArea(context, controller, day, dayUser, setStateCallback),
            ),
          ],
        ),
      ),
    );
  }

  /// Buduje nagłówek dla karty dnia
  static Widget _buildHeader(
    BuildContext context,
    DayController controller,
    DayData day,
    DayUser? dayUser,
    StateSetter setStateCallback,
  ) {
    // Te zmienne są przeliczane na nowo przy każdym wywołaniu setStateCallback
    final offsetStr = (dayUser?.offset != null && dayUser!.offset != 0) ? ' (offset: ${dayUser.offset})' : '';

    return Container(
      width: double.infinity,
      color: Colors.green[900],
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Data: ${DateFormat('yyyy-MM-dd').format(day.date)}$offsetStr',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.comment, color: Colors.white),
                tooltip: 'Dodaj komentarz',
                onPressed: () => CommentDialog.show(
                  context: context,
                  controller: controller,
                  date: day.date,
                  setStateCallback: setStateCallback,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Ustaw offset',
                onPressed: () => OffsetDialog.show(
                  context: context,
                  controller: controller,
                  date: day.date,
                  setStateCallback: setStateCallback,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  String values = day.measurements
                      .map((m) => '${DateFormat('HH:mm').format(m.timestamp)}: ${m.glucoseValue} mg/dL')
                      .join('\n');
                  MeasurementsDialog.show(
                    context: context,
                    title: 'Pomiary',
                    values: values,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Ukryj dzień z powodu błędnych pomiarów',
                onPressed: () async {
                  final success = await controller.changeDayVisibility(day.date, true);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nie udało się ukryć dnia'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Buduje obszar roboczy dla karty dnia
  static Widget _buildWorkingArea(
    BuildContext context,
    DayController controller,
    DayData day,
    DayUser? dayUser,
    StateSetter setStateCallback,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Komentarz użytkownika
        _buildUserComment(context, controller, day, dayUser, setStateCallback),
        // wykres i statystyki
        _buildChartAndStats(context, controller, day, dayUser),
        if (day.notes.isNotEmpty) _buildNotes(context, controller, day, dayUser, setStateCallback),
      ],
    );
  }

  /// Buduje sekcję wykresu i statystyk.
  static Widget _buildChartAndStats(BuildContext context, DayController controller, DayData day, DayUser? dayUser) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wykres
        Expanded(
          child: SizedBox(
            height: chartHeight,
            child: _buildChart(context, controller, day),
          ),
        ),
        // Odstęp między wykresem a statystykami
        const SizedBox(width: 8),
        // Statystyki
        SizedBox(
          width: 220,
          height: chartHeight,
          child: _buildStats(context, controller, day),
        ),
      ],
    );
  }

  /// Buduje wykres na podstawie danych dnia.
  static Widget _buildChart(BuildContext context, DayController controller, DayData day) {
    // Przygotowanie danych do wykresu
    final chartData = day.measurements
        .map((measurement) => ChartData(
              measurement.timestamp,
              controller.getAdjustedGlucoseValue(day.date, measurement.glucoseValue) as double,
            ))
        .toList();

    final tooltipBehavior = _buildTooltipBehavior(day);

    // Tworzenie wykresu SfCartesianChart z dwoma seriami danych
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
  static Widget _buildStats(BuildContext context, DayController controller, DayData day) {
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
          onTap: () => MeasurementsDialog.show(
            context: context,
            title: 'Przekroczenie (${period.points} pkt)',
            values: period.periodMeasurements
                .map((m) => '${DateFormat('HH:mm').format(m.timestamp)}: ${m.glucoseValue} mg/dL')
                .join('\n'),
          ),
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

  /// Buduje sekcję notatek.
  static Widget _buildNotes(
      BuildContext context, DayController controller, DayData day, DayUser? dayUser, StateSetter setStateCallback) {
    // Pobieramy notatki użytkownika dla tego dnia

    // Tworzymy mapę timestamp -> notatka dla notatek użytkownika
    final userNotes = <DateTime, Note>{};
    if (dayUser != null) {
      for (var note in dayUser.notes) {
        userNotes[note.timestamp] = note;
      }
    }

    // Grupujemy notatki systemowe po timestamp
    final systemNotesByTime = <DateTime, List<String>>{};
    for (var note in day.notes) {
      systemNotesByTime.putIfAbsent(note.timestamp, () => []).add(note.note!);
    }

    // Tworzymy końcową listę notatek
    final allNotes = <Note>[];

    // Dodajemy wszystkie timestampy do zbioru
    final allTimestamps = {...systemNotesByTime.keys, ...userNotes.keys};

    // Iterujemy po wszystkich timestampach
    for (var timestamp in allTimestamps) {
      final userNote = userNotes[timestamp];

      if (userNote != null) {
        // Jeśli jest notatka użytkownika
        if (userNote.note != null) {
          // Jeśli notatka nie jest pusta (null), dodajemy ją
          allNotes.add(userNote);
        }
        // Jeśli notatka jest pusta (null), pomijamy zarówno ją jak i notatkę systemową
      } else if (systemNotesByTime.containsKey(timestamp)) {
        // Jeśli nie ma notatki użytkownika (nawet pustej), używamy notatki systemowej
        final combinedNote = systemNotesByTime[timestamp]!.join('\n');
        allNotes.add(Note(timestamp, combinedNote));
      }
    }

    // Sortujemy notatki po czasie
    allNotes.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Nie tworzymy widgetu jeśli nie ma notatek
    if (allNotes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () {
                NoteDialog.show(
                  context: context,
                  controller: controller,
                  date: day.date,
                  initialTime: TimeOfDay.now(),
                  setStateCallback: setStateCallback,
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Dodaj notatkę'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...allNotes.map((note) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: InkWell(
                  onTap: () {
                    NoteDialog.show(
                      context: context,
                      controller: controller,
                      date: day.date,
                      initialTime: TimeOfDay.fromDateTime(note.timestamp),
                      originalNote: note,
                      setStateCallback: setStateCallback,
                    );
                  },
                  mouseCursor: SystemMouseCursors.click,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            _createTextSpan(
                              '${DateFormat('HH:mm').format(note.timestamp)} ',
                              fontWeight: FontWeight.bold,
                              color: userNotes.containsKey(note.timestamp) ? Colors.indigo : Colors.black,
                            ),
                            _createTextSpan(
                              note.note,
                              color: userNotes.containsKey(note.timestamp) ? Colors.indigo : Colors.black,
                            ),
                          ],
                        ),
                      ),
                      if (note.images.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...note.images.map((imageName) => Tooltip(
                              message: 'Kliknij aby zobaczyć obrazek',
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    ImageDialog.show(
                                      context: context,
                                      controller: controller,
                                      imageName: imageName,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Icon(
                                      Icons.image,
                                      size: 16,
                                      color: userNotes.containsKey(note.timestamp) ? Colors.indigo : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              NoteDialog.show(
                context: context,
                controller: controller,
                date: day.date,
                initialTime: TimeOfDay.now(),
                setStateCallback: setStateCallback,
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Dodaj notatkę'),
          ),
        ],
      ),
    );
  }

  /// Buduje sekcję z komentarzem użytkownika
  static Widget _buildUserComment(
      BuildContext context, DayController controller, DayData day, DayUser? dayUser, StateSetter setStateCallback) {
    // Pobieramy dane użytkownika dla tego dnia
    final comments = dayUser?.comments ?? '';

    if (comments.isEmpty) {
      return const SizedBox.shrink(); // Nie wyświetlamy nic jeśli nie ma komentarza
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => CommentDialog(
              controller: controller,
              date: day.date,
              setStateCallback: setStateCallback,
            ),
          );
        },
        mouseCursor: SystemMouseCursors.click,
        child: Text(
          comments,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  /// Tworzy obiekt TextSpan z podanym tekstem i stylami.
  ///
  /// [text] - tekst do wyświetlenia.
  /// [fontSize] - rozmiar czcionki, domyślnie 14.
  /// [color] - kolor tekstu, domyślnie czarny.
  /// [fontWeight] - grubość czcionki, domyślnie normalna.
  static TextSpan _createTextSpan(
    String? text, {
    double fontSize = 14,
    Color color = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextSpan(
      text: text ?? '',
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      ),
    );
  }
}

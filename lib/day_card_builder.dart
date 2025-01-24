import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model.dart';
import 'day_controller.dart';
import 'dialogs/comment_dialog.dart';
import 'dialogs/offset_dialog.dart';
import 'dialogs/measurements_dialog.dart';
import 'dialogs/note_dialog.dart';
import 'dialogs/image_dialog.dart';
import 'day_chart_builder.dart';
import 'logger.dart';

class DayCardBuilder {
  static final _logger = Logger('DayCardBuilder');
  static const double chartHeight = 300.0;
  static const noteColor = Colors.amber;
  static const glucoseColor = Colors.blue;
  static const dayEndHour = 23; // godzina końca dnia

  /// Loguje kolejność notatek dla danego dnia
  static void _logNotes(DateTime date, List<Note> notes, String info) {
    final thatDay = (date.year == 2025 && date.month == 1 && date.day == 19);
    if (!thatDay) return;
    _logger.info('=== $info ===');
    for (var note in notes) {
      _logger.info('${note.timestamp}: ${note.note}');
    }
    _logger.info('===================================');
  }

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
      color: Colors.green[700], // Jaśniejszy odcień zieleni
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Data: ${DateFormat('yyyy-MM-dd').format(day.date)} (${DateFormat('EEEE').format(day.date)})$offsetStr',
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
    final notesToShow = controller.prepareNotesToShow(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Komentarz użytkownika
        _buildUserComment(context, controller, day, dayUser, setStateCallback),
        // wykres i statystyki
        _buildChartAndStats(context, controller, day, dayUser),
        // buduję sekcję notatek
        _buildNotes(context, controller, day, setStateCallback, notesToShow)
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
    return DayChartBuilder.build(context, controller, day);
  }

  /// Buduje sekcję statystyk pokazującą przekroczenia poziomu glukozy.
  static Widget _buildStats(BuildContext context, DayController controller, DayData day) {
    // Pobieramy okresy z uwzględnieniem offsetu
    var adjustedPeriods = controller.getAdjustedPeriods(day);

    if (adjustedPeriods.isEmpty) {
      return Container(
          padding: const EdgeInsets.all(8.0),
          child: const Center(child: Icon(Icons.thumb_up, size: 90, color: Colors.green)));
    }

    // Lista widgetów z przekroczeniami
    List<Widget> periodWidgets = [];

    // Obliczamy sumę punktów
    final totalPoints = adjustedPeriods.fold(0, (sum, period) => sum + period.points);

    // Dodajemy nagłówek z liczbą przekroczeń i sumą punktów
    periodWidgets.add(Text('Przekroczenia: ${adjustedPeriods.length}/$totalPoints',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

    // odstęp
    periodWidgets.add(const SizedBox(height: 8));

    // Dodajemy informacje o przekroczeniach
    for (var i = 0; i < adjustedPeriods.length; i++) {
      final period = adjustedPeriods[i];
      periodWidgets.add(
        InkWell(
          onTap: () => MeasurementsDialog.show(
            context: context,
            title: 'Przekroczenie (${period.points} pkt)',
            values: period.periodMeasurements
                .map((m) =>
                    '${DateFormat('HH:mm').format(m.timestamp)}: ${controller.getAdjustedGlucoseValue(day.date, m.glucoseValue)} mg/dL')
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
        constraints: const BoxConstraints(
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
      BuildContext context, DayController controller, DayData day, StateSetter setStateCallback, List<Note> notes) {
    // Nie tworzymy widgetu jeśli nie ma notatek
    if (notes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: const Column(
          children: [
            Divider(),
            Text(
              'Brak notatek',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
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
          const Divider(),
          const Text(
            'Notatki:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          ...notes.map((note) => Padding(
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
                  child: Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              _createTextSpan(
                                '${DateFormat('HH:mm').format(note.timestamp)} ',
                                fontWeight: FontWeight.bold,
                                color: note.userNote ? Colors.indigo : Colors.black,
                              ),
                              _createTextSpan(
                                note.note,
                                color: note.userNote ? Colors.indigo : Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (note.images.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.image,
                            size: 16,
                            color: note.userNote ? Colors.indigo : Colors.black54,
                          ),
                          onPressed: () {
                            ImageDialog.show(
                              context: context,
                              controller: controller,
                              imageName: note.images.first,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              )),
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

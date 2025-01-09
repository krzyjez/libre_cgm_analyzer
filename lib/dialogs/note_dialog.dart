import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../day_controller.dart';
import '../model.dart';
import 'base_dialog.dart';

/// Dialog do edycji lub dodawania notatki
@immutable
class NoteDialog extends StatelessWidget {
  final DayController controller;
  final DateTime date;
  final Note? originalNote;
  final StateSetter setStateCallback;
  final TimeOfDay? initialTime;

  const NoteDialog({
    super.key,
    required this.controller,
    required this.date,
    this.originalNote,
    this.initialTime,
    required this.setStateCallback,
  });

  /// Wyświetla dialog do edycji lub dodania notatki
  static Future<void> show({
    required BuildContext context,
    required DayController controller,
    required DateTime date,
    Note? originalNote,
    TimeOfDay? initialTime,
    required StateSetter setStateCallback,
  }) {
    return BaseDialog.show(
      context: context,
      builder: (context) => NoteDialog(
        controller: controller,
        date: date,
        originalNote: originalNote,
        initialTime: initialTime,
        setStateCallback: setStateCallback,
      ),
    );
  }

  String _formatTimeOfDay(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: true);
  }

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: originalNote?.note ?? '');
    final timeController = TextEditingController(
      text: originalNote != null 
          ? DateFormat('HH:mm').format(originalNote!.timestamp)
          : _formatTimeOfDay(context, initialTime ?? TimeOfDay.now())
    );

    // Pobieramy notatki użytkownika dla tego dnia
    final dayUser = controller.findUserDayByDate(date);
    final userNotes = <DateTime, Note>{};
    if (dayUser != null) {
      for (var note in dayUser.notes) {
        userNotes[note.timestamp] = note;
      }
    }

    // Funkcja zapisująca notatkę
    Future<void> saveNote() async {
      // Parsujemy czas
      final timeParts = timeController.text.split(':');
      if (timeParts.length != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nieprawidłowy format czasu. Użyj HH:mm')),
        );
        return;
      }

      try {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
          throw FormatException('Nieprawidłowa godzina lub minuta');
        }

        final timestamp = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        final newNote = Note(timestamp, textController.text);
        await controller.saveUserNote(date, newNote);
        setStateCallback(() {}); // Odświeżamy widok
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nieprawidłowy format czasu. Użyj HH:mm')),
          );
        }
      }
    }

    return BaseDialog(
      title: originalNote != null 
          ? 'Edycja notatki'
          : 'Dodawanie notatki',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pole do wprowadzenia czasu
          TextField(
            controller: timeController,
            decoration: const InputDecoration(
              labelText: 'Czas (HH:mm)',
              hintText: 'np. 14:30',
            ),
          ),
          const SizedBox(height: 8),
          // Pole do wprowadzenia treści notatki
          TextField(
            controller: textController,
            autofocus: true,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Notatka',
              hintText: 'Wprowadź treść notatki',
            ),
          ),
        ],
      ),
      onCancel: () => Navigator.pop(context),
      onSave: saveNote,
      onDelete: originalNote != null
          ? () async {
              // Sprawdzamy czy to notatka systemowa czy użytkownika
              final isSystemNote = !userNotes.containsKey(originalNote!.timestamp);
              final success = await controller.deleteUserNote(
                date,
                originalNote!.timestamp,
                isSystemNote: isSystemNote,
              );
              if (success) {
                setStateCallback(() {});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSystemNote 
                          ? 'Notatka systemowa została ukryta'
                          : 'Notatka została usunięta'
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nie udało się usunąć notatki'),
                    ),
                  );
                }
              }
            }
          : null,
      additionalShortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): saveNote,
      },
    );
  }
}

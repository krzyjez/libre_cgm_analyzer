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
  final Note? originalNote; // Może być null dla nowej notatki
  final StateSetter setStateCallback;
  final TimeOfDay? initialTime; // Początkowy czas dla nowej notatki

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

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: originalNote?.note ?? '');
    final timeController = TextEditingController(
      text: originalNote != null 
          ? DateFormat('HH:mm').format(originalNote!.timestamp)
          : initialTime?.format(context) ?? TimeOfDay.now().format(context)
    );

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
      additionalShortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): saveNote,
      },
    );
  }
}

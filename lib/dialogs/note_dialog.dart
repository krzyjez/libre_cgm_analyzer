import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../day_controller.dart';
import '../model.dart';
import 'base_dialog.dart';

/// Dialog do edycji notatki
@immutable
class NoteDialog extends StatelessWidget {
  final DayController controller;
  final DateTime date;
  final Note originalNote;
  final StateSetter setStateCallback;

  const NoteDialog({
    super.key,
    required this.controller,
    required this.date,
    required this.originalNote,
    required this.setStateCallback,
  });

  /// Wyświetla dialog do edycji notatki
  static Future<void> show({
    required BuildContext context,
    required DayController controller,
    required DateTime date,
    required Note originalNote,
    required StateSetter setStateCallback,
  }) {
    return BaseDialog.show(
      context: context,
      builder: (context) => NoteDialog(
        controller: controller,
        date: date,
        originalNote: originalNote,
        setStateCallback: setStateCallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: originalNote.note);

    // Funkcja zapisująca notatkę
    Future<void> saveNote() async {
      final newNote = Note(originalNote.timestamp, textController.text);
      await controller.saveUserNote(date, newNote);
      setStateCallback(() {}); // Odświeżamy widok
      if (context.mounted) Navigator.pop(context);
    }

    return BaseDialog(
      title: 'Edycja notatki z ${DateFormat('HH:mm').format(originalNote.timestamp)}',
      content: TextField(
        controller: textController,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(
          labelText: 'Notatka',
          hintText: 'Wprowadź nową treść notatki',
        ),
      ),
      onCancel: () => Navigator.pop(context),
      onSave: saveNote,
      additionalShortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): saveNote,
      },
    );
  }
}

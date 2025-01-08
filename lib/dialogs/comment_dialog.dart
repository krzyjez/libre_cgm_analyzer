import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../day_controller.dart';
import '../logger.dart';
import 'base_dialog.dart';

/// Dialog do dodawania/edycji komentarzy dla danego dnia
@immutable
class CommentDialog extends StatelessWidget {
  final DayController controller;
  final DateTime date;
  final StateSetter setStateCallback;

  const CommentDialog({
    super.key,
    required this.controller,
    required this.date,
    required this.setStateCallback,
  });

  /// Wyświetla dialog do dodania/edycji komentarza
  static Future<void> show({
    required BuildContext context,
    required DayController controller,
    required DateTime date,
    required StateSetter setStateCallback,
  }) {
    return BaseDialog.show(
      context: context,
      builder: (context) => CommentDialog(
        controller: controller,
        date: date,
        setStateCallback: setStateCallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logger = Logger('CommentDialog');
    final dayUser = controller.findUserDayByDate(date);
    final textController = TextEditingController(text: dayUser?.comments ?? '');

    // Funkcja zapisująca komentarz
    Future<void> saveComment() async {
      final newComment = textController.text;
      logger.info('Zapisuję nowy komentarz: $newComment');
      
      if (await controller.updateComment(date, newComment)) {
        if (context.mounted) {
          Navigator.pop(context);
          setStateCallback(() {}); // Odświeżamy kartę
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nie udało się zapisać komentarza. Spróbuj ponownie później.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return BaseDialog(
      title: 'Komentarz dla ${DateFormat('yyyy-MM-dd').format(date)}',
      content: TextField(
        controller: textController,
        autofocus: true,
        maxLines: null,
        decoration: InputDecoration(
          labelText: 'Komentarz',
          hintText: 'Wprowadź komentarz dla tego dnia',
        ),
      ),
      onCancel: () => Navigator.pop(context),
      onSave: saveComment,
      additionalShortcuts: {
        SingleActivator(LogicalKeyboardKey.enter, control: true): saveComment,
      },
    );
  }
}

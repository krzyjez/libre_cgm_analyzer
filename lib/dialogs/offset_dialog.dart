import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../day_controller.dart';
import '../logger.dart';
import 'base_dialog.dart';

/// Dialog do ustawiania offsetu dla danego dnia
@immutable
class OffsetDialog extends StatelessWidget {
  final DayController controller;
  final DateTime date;
  final StateSetter setStateCallback;

  const OffsetDialog({
    super.key,
    required this.controller,
    required this.date,
    required this.setStateCallback,
  });

  /// Wyświetla dialog do ustawienia offsetu
  static Future<void> show({
    required BuildContext context,
    required DayController controller,
    required DateTime date,
    required StateSetter setStateCallback,
  }) {
    return BaseDialog.show(
      context: context,
      builder: (context) => OffsetDialog(
        controller: controller,
        date: date,
        setStateCallback: setStateCallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logger = Logger('OffsetDialog');
    final currentOffset = controller.getOffsetForDate(date);
    final textController = TextEditingController(text: currentOffset.toString());

    // Funkcja zapisująca offset
    Future<void> saveOffset() async {
      final newOffset = int.tryParse(textController.text) ?? 0;
      logger.info('Zapisuję nowy offset: $newOffset');
      
      if (await controller.updateOffset(date, newOffset)) {
        if (context.mounted) {
          Navigator.pop(context);
          setStateCallback(() {}); // Odświeżamy kartę
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nie udało się zapisać offsetu. Spróbuj ponownie później.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return BaseDialog(
      title: 'Ustaw offset dla ${DateFormat('yyyy-MM-dd').format(date)}',
      content: TextField(
        controller: textController,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Offset',
          hintText: 'Wprowadź wartość offsetu',
        ),
      ),
      onCancel: () => Navigator.pop(context),
      onSave: saveOffset,
      additionalShortcuts: {
        SingleActivator(LogicalKeyboardKey.enter): saveOffset,
      },
    );
  }
}

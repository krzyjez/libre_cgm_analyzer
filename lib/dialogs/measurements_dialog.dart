import 'package:flutter/material.dart';
import 'base_dialog.dart';

/// Dialog wyświetlający listę pomiarów
@immutable
class MeasurementsDialog extends StatelessWidget {
  final String title;
  final String values;

  const MeasurementsDialog({
    super.key,
    required this.title,
    required this.values,
  });

  /// Wyświetla dialog z listą pomiarów
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String values,
  }) {
    return BaseDialog.show(
      context: context,
      builder: (context) => MeasurementsDialog(
        title: title,
        values: values,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: title,
      content: SingleChildScrollView(
        child: Text(values),
      ),
      onCancel: () => Navigator.pop(context),
      onSave: () => Navigator.pop(context),
      showSaveButton: false, // Ten dialog ma tylko przycisk zamknięcia
    );
  }
}

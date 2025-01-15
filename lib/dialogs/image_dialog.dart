import 'package:flutter/material.dart';
import '../day_controller.dart';
import 'base_dialog.dart';

/// Dialog wyświetlający obrazek w pełnym rozmiarze
class ImageDialog extends StatelessWidget {
  final DayController controller;
  final String imageName;

  const ImageDialog({
    super.key,
    required this.controller,
    required this.imageName,
  });

  /// Wyświetla dialog z obrazkiem
  static Future<void> show({
    required BuildContext context,
    required DayController controller,
    required String imageName,
  }) {
    return BaseDialog.show(
      context: context,
      builder: (context) => ImageDialog(
        controller: controller,
        imageName: imageName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pobieramy rozmiar ekranu
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.8;
    final maxHeight = screenSize.height * 0.8;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      controller.getImageUrl(imageName),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text('Nie udało się załadować obrazka'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kliknij aby zamknąć',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

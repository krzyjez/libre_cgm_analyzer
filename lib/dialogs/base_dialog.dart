import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bazowa klasa dla wszystkich dialogów w aplikacji.
/// Zapewnia spójny wygląd i zachowanie dla wszystkich dialogów.
/// 
/// Funkcjonalności:
/// - Jednolity styl tytułu i przycisków
/// - Obsługa klawisza ESC do zamykania
/// - Możliwość dodawania własnych skrótów klawiszowych
/// - Przyciski Anuluj/Zapisz (opcjonalnie)
@immutable
class BaseDialog extends StatelessWidget {
  /// Tytuł wyświetlany w nagłówku dialogu
  final String title;

  /// Główna zawartość dialogu
  final Widget content;

  /// Funkcja wywoływana po kliknięciu Anuluj lub ESC
  final VoidCallback onCancel;

  /// Funkcja wywoływana po kliknięciu Zapisz
  final VoidCallback onSave;

  /// Czy pokazywać przycisk Zapisz
  /// Domyślnie true. Ustaw false dla dialogów tylko do odczytu
  final bool showSaveButton;

  /// Dodatkowe skróty klawiszowe specyficzne dla konkretnego dialogu
  /// Na przykład: CTRL+ENTER dla zapisywania komentarza
  /// 
  /// Przykład użycia:
  /// ```dart
  /// additionalShortcuts: {
  ///   SingleActivator(LogicalKeyboardKey.enter, control: true): saveComment,
  /// }
  /// ```
  final Map<ShortcutActivator, VoidCallback>? additionalShortcuts;

  const BaseDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onCancel,
    required this.onSave,
    this.showSaveButton = true,
    this.additionalShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    // Opakowujemy cały dialog w CallbackShortcuts aby ESC działał zawsze,
    // niezależnie od tego, który element ma fokus
    return CallbackShortcuts(
      bindings: {
        // ESC zawsze zamyka dialog bez zapisywania
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop(); // Bezpośrednie zamknięcie dialogu
        },
        // Operator spread (...?) dodaje skróty z additionalShortcuts
        // jeśli nie jest null
        ...?additionalShortcuts,
      },
      child: AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: content,
        actions: [
          // Przycisk Anuluj - zawsze obecny
          TextButton(
            onPressed: onCancel,
            child: const Text('Anuluj'),
          ),
          // Przycisk Zapisz - opcjonalny
          if (showSaveButton)
            TextButton(
              onPressed: onSave,
              child: const Text('Zapisz'),
            ),
        ],
      ),
    );
  }

  /// Pomocnicza metoda do wyświetlania dialogu
  /// 
  /// Parametry:
  /// - [context] - kontekst Fluttera potrzebny do wyświetlenia dialogu
  /// - [builder] - funkcja budująca zawartość dialogu
  /// 
  /// Przykład użycia:
  /// ```dart
  /// BaseDialog.show(
  ///   context: context,
  ///   builder: (context) => MojDialog(),
  /// );
  /// ```
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showDialog<T>(
      context: context,
      builder: builder,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../day_controller.dart';
import '../model.dart';
import '../logger.dart';
import 'base_dialog.dart';

/// Dialog do edycji lub dodawania notatki
class NoteDialog extends StatefulWidget {
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

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  /// Lista tymczasowych obrazków
  final List<ImageDto> _newImages = [];

  /// Lista obrazków do usunięcia
  final List<String> _imagesToDelete = [];

  static final _logger = Logger('NoteDialog');

  late TextEditingController timeController;
  late TextEditingController textController;

  @override
  void initState() {
    super.initState();

    // Używamy DateFormat zamiast _formatTimeOfDay w initState
    if (widget.originalNote != null) {
      timeController = TextEditingController(
        text: DateFormat('HH:mm').format(widget.originalNote!.timestamp),
      );
    } else if (widget.initialTime != null) {
      timeController = TextEditingController(
        text:
            '${widget.initialTime!.hour.toString().padLeft(2, '0')}:${widget.initialTime!.minute.toString().padLeft(2, '0')}',
      );
    } else {
      final now = TimeOfDay.now();
      timeController = TextEditingController(
        text: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
    }

    textController = TextEditingController(text: widget.originalNote?.note ?? '');
  }

  @override
  void dispose() {
    timeController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayUser = widget.controller.findUserDayByDate(widget.date);
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nieprawidłowy format czasu. Użyj HH:mm')),
          );
        }
        return;
      }

      try {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
          throw const FormatException('Nieprawidłowa godzina lub minuta');
        }

        final date = widget.date;
        _logger.info('notatka dla dnia $date}');
        var newTimestamp = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        // Jeśli godzina jest przed dayEndHour, używamy daty następnego dnia

        if (hour < dayEndHour) {
          newTimestamp = newTimestamp.add(const Duration(days: 1));
        }
        _logger.info('notatka po korekcie $newTimestamp}');
        // Tworzymy nową notatkę z oryginalnym timestampem (jeśli to edycja)
        Note note;
        if (widget.originalNote != null) {
          // Przy edycji używamy oryginalnego timestampa
          note = Note(widget.originalNote!.timestamp, textController.text);
          // i kopiujemy do niej obrazki ze starej notatki
          note.images.addAll(widget.originalNote!.images);
        } else {
          // Przy tworzeniu nowej notatki używamy nowego timestampa
          note = Note(newTimestamp, textController.text);
        }

        // Sprawdzamy czy zmienił się czas notatki
        final timestampChanged =
            widget.originalNote != null && !widget.originalNote!.timestamp.isAtSameMomentAs(newTimestamp);

        // Zapisujemy notatkę wraz z obrazkami
        final success = await widget.controller.saveNoteWithImages(widget.date, note, _newImages, _imagesToDelete,
            newTimestamp: timestampChanged ? newTimestamp : null);

        if (success) {
          widget.setStateCallback(() {});
          if (context.mounted) {
            Navigator.pop(context);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Błąd podczas zapisywania notatki')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nieprawidłowy format czasu')),
          );
        }
      }
    }

    return DefaultTabController(
      length: 2,
      child: BaseDialog(
        title: widget.originalNote != null ? 'Edycja notatki' : 'Dodawanie notatki',
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              // Pole do wprowadzenia czasu
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  hintText: 'np. 14:30',
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                tabs: const [
                  Tab(text: 'Tekst'),
                  Tab(text: 'Obrazki'),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    // Zakładka z tekstem
                    TextField(
                      controller: textController,
                      autofocus: true,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Wprowadź tekst notatki',
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                    // Zakładka z obrazkami
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );

                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.first;
                              setState(() {
                                _newImages.add(ImageDto(
                                  bytes: file.bytes!,
                                ));
                              });
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Dodaj obrazek'),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: (widget.originalNote?.images.length ?? 0) + _newImages.length,
                            itemBuilder: (context, index) {
                              final existingImagesCount = widget.originalNote?.images.length ?? 0;
                              if (index < existingImagesCount) {
                                final imageUrl = widget.controller.getImageUrl(widget.originalNote!.images[index]);
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            setState(() {
                                              _imagesToDelete.add(widget.originalNote!.images[index]);
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                final image = _newImages[index - existingImagesCount];
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          image.bytes,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            setState(() {
                                              _newImages.removeAt(index - existingImagesCount);
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onCancel: () => Navigator.pop(context),
        onSave: saveNote,
        onDelete: widget.originalNote != null
            ? () async {
                // Sprawdzamy czy to notatka systemowa czy użytkownika
                final isSystemNote = !userNotes.containsKey(widget.originalNote!.timestamp);
                final success = await widget.controller.deleteUserNote(
                  widget.date,
                  widget.originalNote!.timestamp,
                  isSystemNote: isSystemNote,
                );
                if (success) {
                  widget.setStateCallback(() {});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isSystemNote ? 'Notatka systemowa została ukryta' : 'Notatka została usunięta'),
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
      ),
    );
  }
}

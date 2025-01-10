import 'package:flutter/material.dart';
import 'model.dart';
import 'logger.dart';
import 'api_service.dart';

/// Kontroler zarządzający danymi i operacjami dla dni
class DayController extends ChangeNotifier {
  final ApiService _apiService;
  final Logger _logger = Logger('DayController');

  UserInfo? _userInfo;
  final int _defaultTreshold;

  DayController(this._apiService, this._defaultTreshold);

  /// Pobiera threshold dla użytkownika
  int get treshold => _userInfo?.treshold ?? _defaultTreshold;

  /// Ustawia dane użytkownika
  set userInfo(UserInfo value) {
    _userInfo = value;
    notifyListeners();
  }

  /// Znajduje DayUser dla danej daty
  DayUser? findUserDayByDate(DateTime date) {
    if (_userInfo == null) return null;

    for (var dayUser in _userInfo!.days) {
      if (dayUser.date.year == date.year && dayUser.date.month == date.month && dayUser.date.day == date.day) {
        return dayUser;
      }
    }

    return null;
  }

  /// Aktualizuje offset dla danego dnia
  Future<bool> updateOffset(DateTime date, int newOffset) async {
    if (_userInfo == null) {
      _logger.error('Próba aktualizacji offsetu bez danych użytkownika');
      return false;
    }

    var dayUser = findUserDayByDate(date);
    if (dayUser == null) {
      dayUser = DayUser(date);
      dayUser.offset = newOffset;
      _userInfo!.days.add(dayUser);
    } else {
      dayUser.offset = newOffset;
    }

    // Zapisz zmiany na serwerze
    try {
      await _apiService.saveUserData(_userInfo!);
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error('Błąd podczas zapisywania danych na serwerze: $e');
      return false;
    }
  }

  /// Pobiera aktualny offset dla danego dnia
  int getOffsetForDate(DateTime date) {
    return findUserDayByDate(date)?.offset ?? 0;
  }

  /// Pobiera skorygowaną wartość glukozy (z uwzględnieniem offsetu)
  int getAdjustedGlucoseValue(DateTime date, int originalValue) {
    return originalValue + getOffsetForDate(date);
  }

  /// Aktualizuje komentarz dla danego dnia
  Future<bool> updateComment(DateTime date, String newComment) async {
    if (_userInfo == null) {
      _logger.error('Próba aktualizacji komentarza bez danych użytkownika');
      return false;
    }

    var dayUser = findUserDayByDate(date);
    if (dayUser == null) {
      dayUser = DayUser(date, comments: newComment);
      _userInfo!.days.add(dayUser);
    } else {
      // Aktualizujemy tylko pole comments, zachowując pozostałe wartości
      dayUser = DayUser(
        date,
        comments: newComment,
        notes: dayUser.notes,
      )..offset = dayUser.offset;

      // Znajdujemy indeks starego dnia i zastępujemy go nowym
      final index = _userInfo!.days
          .indexWhere((d) => d.date.year == date.year && d.date.month == date.month && d.date.day == date.day);
      if (index != -1) {
        _userInfo!.days[index] = dayUser;
      }
    }

    // Zapisz zmiany na serwerze
    try {
      await _apiService.saveUserData(_userInfo!);
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error('Błąd podczas zapisywania danych na serwerze: $e');
      return false;
    }
  }

  /// Usuwa komentarz dla danego dnia
  Future<bool> deleteComment(DateTime date) async {
    if (_userInfo == null) {
      _logger.error('Próba usunięcia komentarza bez danych użytkownika');
      return false;
    }

    var dayUser = findUserDayByDate(date);
    if (dayUser == null) {
      _logger.error('Nie znaleziono dnia użytkownika dla daty $date');
      return false;
    }

    dayUser.comments = '';

    try {
      await _apiService.saveUserData(_userInfo!);
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error('Błąd podczas usuwania komentarza: $e');
      return false;
    }
  }

  /// Znajduje notatkę użytkownika dla danego timestampa
  /// Zwraca null jeśli nie znaleziono
  Note? findUserNoteByTimestamp(DateTime date, DateTime timestamp) {
    final dayUser = findUserDayByDate(date);
    if (dayUser == null) return null;

    for (var note in dayUser.notes) {
      if (note.timestamp.isAtSameMomentAs(timestamp)) {
        return note;
      }
    }

    return null;
  }

  /// Zapisuje notatkę użytkownika
  Future<bool> saveUserNote(DateTime date, Note note) async {
    if (_userInfo == null) {
      _logger.error('Próba zapisania notatki bez danych użytkownika');
      return false;
    }

    var dayUser = findUserDayByDate(date);
    if (dayUser == null) {
      dayUser = DayUser(date);
      _userInfo!.days.add(dayUser);
    }

    // Szukamy czy już istnieje notatka o tym samym timestamp
    final existingNoteIndex = dayUser.notes.indexWhere((n) => n.timestamp == note.timestamp);

    if (existingNoteIndex != -1) {
      // Aktualizujemy istniejącą notatkę
      dayUser.notes[existingNoteIndex] = note;
    } else {
      // Dodajemy nową notatkę
      dayUser.notes.add(note);
    }

    // Zapisujemy zmiany
    try {
      await _apiService.saveUserData(_userInfo!);
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error('Błąd podczas zapisywania notatki użytkownika: $e');
      return false;
    }
  }

  /// Usuwa lub ukrywa notatkę
  /// Dla notatek użytkownika: ustawia tekst na null
  /// Dla notatek systemowych: tworzy pustą notatkę użytkownika
  Future<bool> deleteUserNote(DateTime date, DateTime timestamp, {bool isSystemNote = false}) async {
    if (_userInfo == null) {
      _logger.error('Próba usunięcia notatki bez danych użytkownika');
      return false;
    }

    var dayUser = findUserDayByDate(date);
    if (dayUser == null) {
      dayUser = DayUser(date);
      _userInfo!.days.add(dayUser);
    }

    if (isSystemNote) {
      // Dla notatki systemowej tworzymy pustą notatkę użytkownika
      dayUser.notes.add(Note(timestamp, null));
    } else {
      // Dla notatki użytkownika ustawiamy tekst na null
      final noteIndex = dayUser.notes.indexWhere((note) => note.timestamp == timestamp);
      if (noteIndex != -1) {
        // Aktualizujemy istniejącą notatkę
        dayUser.notes[noteIndex] = Note(timestamp, null);
      } else {
        // Jeśli nie znaleziono notatki, to znaczy że próbujemy ukryć notatkę systemową
        dayUser.notes.add(Note(timestamp, null));
      }
    }

    // Zapisujemy zmiany
    try {
      await _apiService.saveUserData(_userInfo!);
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error('Błąd podczas usuwania notatki: $e');
      return false;
    }
  }

  /// Zwraca URL do obrazka
  String getImageUrl(String filename) {
    return _apiService.getImageUrl(filename);
  }

  /// Wysyła obrazek na serwer
  /// Zwraca nazwę pliku pod jaką został zapisany
  Future<String> uploadImage(ImageDto image) async {
    try {
      final filename = await _apiService.uploadImage(image);
      _logger.info('Wysłano obrazek: $filename');
      return filename;
    } catch (e) {
      _logger.error('Błąd podczas wysyłania obrazka: $e');
      rethrow;
    }
  }

  /// Usuwa obrazek z serwera
  Future<bool> deleteImage(String filename) async {
    try {
      final success = await _apiService.deleteImage(filename);
      if (success) {
        _logger.info('Usunięto obrazek: $filename');
      } else {
        _logger.error('Nie udało się usunąć obrazka: $filename');
      }
      return success;
    } catch (e) {
      _logger.error('Błąd podczas usuwania obrazka: $e');
      return false;
    }
  }

  /// Zapisuje notatkę wraz z obrazkami
  Future<bool> saveNoteWithImages(
    DateTime date,
    Note note,
    List<ImageDto> newImages,
    List<String> imagesToDelete,
  ) async {
    try {
      // 1. Usuwamy oznaczone obrazki
      for (final filename in imagesToDelete) {
        await deleteImage(filename);
      }

      // 2. Wysyłamy nowe obrazki
      final uploadedImages = <String>[];
      for (final image in newImages) {
        final filename = await uploadImage(image);
        uploadedImages.add(filename);
      }

      // 3. Aktualizujemy listę obrazków w notatce
      final existingImages = note.images.where((img) => !imagesToDelete.contains(img)).toList();
      note.images = [...existingImages, ...uploadedImages];

      // 4. Zapisujemy notatkę
      return await saveUserNote(date, note);
    } catch (e) {
      _logger.error('Błąd podczas zapisywania notatki z obrazkami: $e');
      return false;
    }
  }
}

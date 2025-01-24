import 'package:flutter/material.dart';
import 'model.dart';
import 'logger.dart';
import 'api_service.dart';

/// Kontroler zarządzający danymi i operacjami dla dni
class DayController extends ChangeNotifier {
  final ApiService _apiService;
  final Logger _logger = Logger('DayController');

  UserInfo? _userInfo;
  List<DayData> _csvData = [];
  final int _defaultTreshold;

  DayController(this._apiService, this._defaultTreshold);

  /// Pobiera threshold dla użytkownika
  int get treshold => _userInfo?.treshold ?? _defaultTreshold;

  /// Zwraca listę dni z danymi
  List<DayData> get csvData => _csvData;

  /// Ustawia listę dni z danymi
  set csvData(List<DayData> value) {
    _csvData = value;
    notifyListeners();
  }

  /// Zwraca dane użytkownika
  UserInfo get userInfo => _userInfo!;

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

    return dayUser.notes
        .cast<Note?>()
        .firstWhere((note) => note?.timestamp.isAtSameMomentAs(timestamp) ?? false, orElse: () => null);
  }

  /// Sprawdza czy istnieje notatka systemowa o danym timestampie
  bool _hasSystemNote(DateTime date, DateTime timestamp) {
    _logger.info('Sprawdzanie notatki systemowej dla daty $date i czasu $timestamp');
    _logger.info(' liczba pozycji w _csvData: ${_csvData.length}');
    final dayData = _csvData.findByDate(date);
    _logger.info('- Znaleziono dane systemowe dla dnia: ${dayData != null}');
    if (dayData == null) return false;

    _logger.info('- Liczba notatek systemowych w tym dniu: ${dayData.notes.length}');
    for (final note in dayData.notes) {
      _logger.info('- Porównanie timestampów: ${note.timestamp} vs $timestamp');
    }

    return dayData.notes.any((note) => note.timestamp.isAtSameMomentAs(timestamp));
  }

  /// Zapisuje notatkę użytkownika
  /// [newTimestamp] - podajemy tylko gdy zmieniamy czas notatki
  Future<bool> _saveUserNote(DateTime date, Note note, {DateTime? newTimestamp}) async {
    _logger.info('Zapisanie notatki użytkownika dla daty $date');
    if (_userInfo == null) {
      _logger.error('Próba zapisania notatki bez danych użytkownika');
      return false;
    }

    var dayUser = findUserDayByDate(date);
    if (dayUser == null) {
      dayUser = DayUser(date);
      _userInfo!.days.add(dayUser);
    }

    // Jeśli zmieniamy czas notatki, sprawdzamy czy pod starym timestampem jest notatka systemowa
    if (newTimestamp != null) {
      final hasOldSystemNote = _hasSystemNote(date, note.timestamp);
      _logger.info('- Czy istnieje notatka systemowa pod starym czasem (${note.timestamp}): $hasOldSystemNote');

      if (hasOldSystemNote) {
        // Tworzymy "ukrytą" notatkę użytkownika (note=null) żeby przykryć starą notatkę systemową
        final hiddenNote = Note(note.timestamp, null);
        dayUser.notes.add(hiddenNote);
        _logger.info('- Utworzono ukrytą notatkę (note=null) dla systemowej notatki z timestamp: ${note.timestamp}');
      }

      // Tworzymy nową notatkę z nowym timestampem
      note = Note(newTimestamp, note.note)..images.addAll(note.images);
    }

    // Szukamy czy już istnieje notatka użytkownika o tym samym timestamp
    final existingUserNoteIndex = dayUser.notes.indexWhere((n) => n.timestamp == note.timestamp);
    _logger.info('- Indeks istniejącej notatki użytkownika: $existingUserNoteIndex');

    if (existingUserNoteIndex != -1) {
      // Aktualizujemy istniejącą notatkę użytkownika
      dayUser.notes[existingUserNoteIndex] = note;
    } else {
      // Dodajemy nową notatkę użytkownika
      dayUser.notes.add(note);
    }

    // Zapisujemy zmiany
    try {
      await _apiService.saveUserData(_userInfo!);
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error('Błąd podczas zapisywania notatki: $e');
      return false;
    }
  }

  /// Zapisuje notatkę wraz z obrazkami
  Future<bool> saveNoteWithImages(
    DateTime date,
    Note note,
    List<ImageDto> newImages,
    List<String> imagesToDelete, {
    DateTime? newTimestamp,
  }) async {
    try {
      _logger.info('Start saveNoteWithImages');

      // 1. Usuwamy oznaczone obrazki
      for (final filename in imagesToDelete) {
        await deleteImage(filename);
      }

      // 2. Wysyłamy nowe obrazki na serwer
      final uploadedImages = <String>[];
      for (final image in newImages) {
        final filename = await uploadImage(image);
        uploadedImages.add(filename);
      }
      _logger.info('- Nazwy uploadowanych obrazków: $uploadedImages');

      // 3. Aktualizujemy listę obrazków w notatce
      note.images.removeWhere((img) => imagesToDelete.contains(img)); // Usuwamy obrazki oznaczone do usunięcia
      note.images.addAll(uploadedImages); // Dodajemy nowe obrazki
      _logger.info('- Finalna lista obrazków w notatce: ${note.images}');

      // 4. Zapisujemy notatkę
      final success = await _saveUserNote(date, note, newTimestamp: newTimestamp);
      _logger.info('- Zapis notatki: ${success ? 'sukces' : 'błąd'}');
      return success;
    } catch (e) {
      _logger.error('Błąd podczas zapisywania notatki z obrazkami: $e');
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
        // Aktualizujemy istniejącą notatkę użytkownika
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

  /// Zmienia widoczność dnia
  /// [date] - data dnia do zmiany
  /// [hide] - true jeśli dzień ma być ukryty, false jeśli ma być widoczny
  Future<bool> changeDayVisibility(DateTime date, bool hide) async {
    if (_userInfo == null) {
      _logger.error('Próba zmiany widoczności dnia bez danych użytkownika');
      return false;
    }

    var dayUser = findUserDayByDate(date);
    if (dayUser == null) {
      dayUser = DayUser(date, hidden: hide);
      _userInfo!.days.add(dayUser);
    } else {
      dayUser.hidden = hide;
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

  /// Sprawdza czy wartość przekracza próg z uwzględnieniem offsetu
  bool isAboveThreshold(DateTime date, int value, int threshold) {
    return getAdjustedGlucoseValue(date, value) > threshold;
  }

  /// Zwraca listę okresów przekroczeń z uwzględnieniem offsetu
  List<Period> getAdjustedPeriods(DayData day) {
    List<Period> adjustedPeriods = [];

    // Filtrujemy okresy, które po uwzględnieniu offsetu nadal przekraczają próg
    for (var period in day.periods) {
      var maxAdjustedValue = period.periodMeasurements
          .map((m) => getAdjustedGlucoseValue(day.date, m.glucoseValue))
          .reduce((a, b) => a > b ? a : b);

      if (maxAdjustedValue > treshold) {
        // Tworzymy nowy okres z uwzględnieniem offsetu
        var adjustedPeriod = Period(
          startTime: period.startTime,
          endTime: period.endTime,
          points: period.points,
          highestMeasure: maxAdjustedValue,
        );
        adjustedPeriod.periodMeasurements.addAll(period.periodMeasurements);
        adjustedPeriods.add(adjustedPeriod);
      }
    }

    return adjustedPeriods;
  }

  /// Przygotowuje listę notatek do wyświetlenia, łącząc notatki systemowe i użytkownika
  List<Note> prepareNotesToShow(DayData day) {
    final dayUser = findUserDayByDate(day.date);
    
    // Tworzymy mapę timestamp -> notatka dla notatek użytkownika
    final userNotesDict = <DateTime, Note>{};
    if (dayUser != null) {
      for (var note in dayUser.notes) {
        note.userNote = true;
        userNotesDict[note.timeOnly] = note;
      }
    }

    // tworzymy systemowe notatki o ile nie pokrywają się z timestamp notatek użytkownika
    final systemNotes = <Note>[];
    for (var note in day.notes) {
      if (!userNotesDict.containsKey(note.timeOnly)) {
        systemNotes.add(note);
      }
    }

    final allNotes = [...userNotesDict.values, ...systemNotes];

    // usuwam notatki bez tekstu - do ukrycia
    allNotes.removeWhere((note) => note.note == null);
    allNotes.sort((a, b) => _compareNotes(a, b));
    
    return allNotes;
  }

  /// Porównuje czasy notatek z uwzględnieniem czasu końca dnia
  int _compareNotes(Note a, Note b) {
    var minutesA = _minutesFromTime(a.timestamp);
    var minutesB = _minutesFromTime(b.timestamp);
    return minutesA.compareTo(minutesB);
  }

  int _minutesFromTime(DateTime time) {
    var tresholdMinutes = dayEndHour * 60;
    var minutes = time.hour * 60 + time.minute;
    if (minutes < tresholdMinutes) minutes += 24 * 60;
    return minutes;
  }
}

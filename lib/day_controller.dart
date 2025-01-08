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
      final index = _userInfo!.days.indexWhere((d) =>
          d.date.year == date.year && d.date.month == date.month && d.date.day == date.day);
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
}

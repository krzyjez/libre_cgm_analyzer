import 'package:json_annotation/json_annotation.dart';
import 'dart:typed_data';

part 'model.g.dart';

/// Reprezentuje obrazek przed wysłaniem na serwer
class ImageDto {
  /// Bajty obrazka
  final Uint8List bytes;

  const ImageDto({
    required this.bytes,
  });
}

class Measurement {
  final DateTime timestamp;
  final int glucoseValue;

  Measurement(this.timestamp, this.glucoseValue);
}

/// Dane pojedynczej notatki
@JsonSerializable()
class Note {
  final DateTime timestamp;
  // tekst notatki
  String? note;
  // lista obrazków przypisanych do notatki
  List<String> images = [];

  Note(this.timestamp, this.note);

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
  Map<String, dynamic> toJson() => _$NoteToJson(this);

  @override
  String toString() => 'Note(timestamp: $timestamp, note: $note)';
}

/// Dane dla pojedyczego dnia - z systemu LibreCGM
class DayData {
  final DateTime date;
  final List<Measurement> measurements = [];
  final List<Note> notes = [];
  final List<Period> periods = [];

  DayData(this.date);
}

/// Dane dla pojedynczego dnia - pochodzące od użytkownika
@JsonSerializable()
class DayUser {
  final DateTime date;

  /// Notatki użytkownika (z json) - jeśli mają taki sam timestamp to "przykrywają" notatki z csv
  final List<Note> notes;
  String comments;
  // Jeśli true to nie wyswietlamy danego dnia gdyż dane są np. zafałszywane
  bool hidden;

  /// wartość o którą będziemy modyfikować wartości glukozy rysowane na wykresie
  /// to dosyć wygodne jeśli np. czytnik zawyża pomiary
  int offset = 0;
  DayUser(this.date, {List<Note>? notes, String? comments, this.hidden = false})
      : notes = notes ?? [],
        comments = comments ?? '';

  factory DayUser.fromJson(Map<String, dynamic> json) => _$DayUserFromJson(json);
  Map<String, dynamic> toJson() => _$DayUserToJson(this);
}

/// Wszystkie dane związane z użytkownikiem
@JsonSerializable()
class UserInfo {
  final int treshold;
  final List<DayUser> days;

  UserInfo({
    this.treshold = 140,
    List<DayUser>? days,
  }) : days = days ?? [];

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

/// Zawiera dane pojedynczego okresu - przekroczenia progu bezpieczeństwa wysokości glukozy
class Period {
  final DateTime startTime;
  final DateTime endTime;
  final int points;
  final int highestMeasure;
  final List<Measurement> periodMeasurements = [];

  Period({required this.startTime, required this.endTime, required this.points, required this.highestMeasure});
}

/// Rozszerzenie dla List<DayData>
extension DayDataListExtension on List<DayData> {
  /// Znajduje DayData dla danej daty
  /// Zwraca null jeśli nie znaleziono
  DayData? findByDate(DateTime date) {
    try {
      return firstWhere((day) =>
        day.date.year == date.year &&
        day.date.month == date.month &&
        day.date.day == date.day
      );
    } catch (e) {
      return null;
    }
  }
}

/// Rozszerzenie dla List<DayUser>
extension DayUserListExtension on List<DayUser> {
  // ...
}

import 'package:json_annotation/json_annotation.dart';
import 'dart:typed_data';

part 'model.g.dart';

/// Reprezentuje obrazek przed wysłaniem na serwer
class ImageDto {
  /// Oryginalna nazwa pliku
  final String filename;

  /// Bajty obrazka
  final Uint8List bytes;

  const ImageDto({
    required this.filename,
    required this.bytes,
  });
}

class Measurement {
  final DateTime timestamp;
  final int glucoseValue;

  Measurement(this.timestamp, this.glucoseValue);
}

@JsonSerializable()
class Note {
  final DateTime timestamp;
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
  final List<Note> notes;
  String comments;
  // Jeśli true to nie wyswietlamy danego dnia gdyż dane są np. zafałszywane
  bool hidden = false;

  /// wartość o którą będziemy modyfikować wartości glukozy rysowane na wykresie
  /// to dosyć wygodne jeśli np. czytnik zawyża pomiary
  int offset = 0;
  DayUser(this.date, {List<Note>? notes, String? comments, bool hidden = false})
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

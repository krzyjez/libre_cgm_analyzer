import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

class Measurement {
  final DateTime timestamp;
  final int glucoseValue;

  Measurement(this.timestamp, this.glucoseValue);
}

@JsonSerializable()
class Note {
  final DateTime timestamp;
  final String? note;
  // lista obrazków przypisanych do notatki
  final List<String> images = [];

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

  /// wartość o którą będziemy modyfikować wartości glukozy rysowane na wykresie
  /// to dosyć wygodne jeśli np. czytnik zawyża pomiary
  int offset = 0;
  DayUser(this.date, {List<Note>? notes, String? comments})
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

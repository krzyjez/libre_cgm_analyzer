class Measurement {
  final DateTime timestamp;
  final int glucoseValue;

  Measurement(this.timestamp, this.glucoseValue);
}

class Note {
  final DateTime timestamp;
  final String note;

  Note(this.timestamp, this.note);
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
class DayUser {
  final DateTime date;
  final List<String> comments = [];
  final List<Note> notes = [];

  DayUser(this.date);
}

/// Wszystkie dane związane z użytkownikiem
class UserInfo {
  final int treshold = 140;
  final List<DayUser> days = [];
}

/// Zawiera dane pojedynczego okresu - przekroczenia progru bezpieczeństwa wysokości glukozy
class Period {
  final DateTime startTime;
  final DateTime endTime;

  final int points;
  final int highestMeasure;

  Period({required this.startTime, required this.endTime, required this.points, required this.highestMeasure});
}

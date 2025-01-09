// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
      DateTime.parse(json['timestamp'] as String),
      json['note'] as String?,
    );

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'note': instance.note,
    };

DayUser _$DayUserFromJson(Map<String, dynamic> json) => DayUser(
      DateTime.parse(json['date'] as String),
      comments: json['comments'] as String?,
      notes: (json['notes'] as List<dynamic>?)
          ?.map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..offset = (json['offset'] as num).toInt();

Map<String, dynamic> _$DayUserToJson(DayUser instance) => <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'comments': instance.comments,
      'notes': instance.notes,
      'offset': instance.offset,
    };

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      treshold: (json['treshold'] as num?)?.toInt() ?? 140,
      days: (json['days'] as List<dynamic>?)
          ?.map((e) => DayUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'treshold': instance.treshold,
      'days': instance.days,
    };

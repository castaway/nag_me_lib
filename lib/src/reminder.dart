import 'package:intl/intl.dart';

enum ReminderStatus { created, running, waiting, off }

class Reminder {
  final String id;
  final String owner_id;
  final String verb;
  final String reminder_text;
  static const Regularity = const {
    'Daily': 1,
    'Weekly': 7,
    'Monthly': 30,
    'Yearly': 365,
  };
  final String regularity;
  final NagTimeOfDay start_time;
  DateTime last_time;
  ReminderStatus status;

  Reminder({
    this.id,
    this.owner_id,
    this.verb,
    this.reminder_text,
    this.regularity,
    this.start_time,
    this.last_time,
    this.status = ReminderStatus.created,
  }) {
    if (this.last_time == null) {
      var now = DateTime.now();
      // Yesterday at midnight given, so if time is today in future it will run today
      this.last_time = new DateTime(now.year, now.month, now.day,
              0, 1)
          .subtract(Duration(days: 1)).toUtc();
    }
  }

  factory Reminder.fromFirebase(fbObj, id, owner_id)
  {
    ReminderStatus status = ReminderStatus.values.firstWhere((val) => val.index == fbObj['status']);
    return Reminder(
      id: id,
      owner_id: owner_id,
      verb: fbObj['verb'],
      reminder_text: fbObj['reminder_text'],
      regularity: fbObj['regularity'],
      start_time: NagTimeOfDay(
          hour: fbObj['start_time']['hour'],
          minute: fbObj['start_time']['minute']),
      last_time: DateTime.parse(fbObj['last_time']).toUtc(),
      status: status ?? ReminderStatus.created,
    );
  }

  Map toMap() {
    return <String, dynamic>{
      'owner_id': owner_id,
      'verb': verb,
      'reminder_text': reminder_text,
      'regularity': regularity,
      'start_time': <String, int>{
        'hour': start_time.hour,
        'minute': start_time.minute
      },
      'last_time': last_time.toIso8601String(),
      'status': status.index
    };
  }

  // Calcualtion = 1 time period after the last day we did it, at the time we want to start it
  // Service will now start if anywhen after this (in case of missed ones / service crashes etc)
  DateTime get next_time {
    return DateTime(this.last_time.year, this.last_time.month, this.last_time.day,
        this.start_time.hour, this.start_time.minute).add(Duration(days: 1)).toUtc();
  }

  // Update the next_time (and save it!?)
  bool taskDone() {
    print('Updated last_time: ${this.last_time}');
    final now = DateTime.now();
    this.last_time = DateTime(now.year, now.month, now.day,
        this.start_time.hour, this.start_time.minute ).toUtc();
//    this.start_time.hour, this.start_time.minute).toUtc(); //this.next_time.add(Duration(days: 1));
    this.status = ReminderStatus.waiting;
    print('Updated last_time: ${this.last_time}');
    print('Next time: ${this.next_time}');
    return true;
  }

  String asString() {
    return 'Have you ${this.verb} your ${this.reminder_text}?';
  }

  String displayString() {
    return '${this.asString()}\n\tDue: ${DateFormat('yyyy-MM-dd HH:mm').format(this.next_time)}';
  }

  String asEditString() {
    return '${this.verb};${this.reminder_text};${this.status.toString()};${this.start_time.toString()}';
  }

  Reminder updateFromString(String updateStr) {
    return Reminder.newFromString(updateStr, this.id, this.owner_id, this);
  }

  static Reminder newFromString(String newStr, String id, String ownerId, [Reminder old]) {
    var values = newStr.split(';');
    if (values.length < 4) {
      print('Edit reminder had incorrect parameters: $newStr');
      return old;
    }

    print(values);
    ReminderStatus status = ReminderStatus.values.firstWhere((val) => val.toString() == values[2]);
    var newTime = NagTimeOfDay.parse(values[3]);
    return Reminder(
      id: id,
      owner_id: ownerId,
      verb: values[0],
      reminder_text: values[1],
      regularity: 'daily',
      start_time: newTime,
      status: status,
    );
  }
}

// This exists in flutter but.. not in dart!?
class NagTimeOfDay {
  final num hour;
  final num minute;

  NagTimeOfDay({this.hour, this.minute});

   factory NagTimeOfDay.parse(String input) {
    var matchRE = RegExp(r'(?<hour>\d{1,2}):(?<minute>\d{1,2})');
    if (matchRE.hasMatch(input)) {
      var match = matchRE.firstMatch(input);
      return NagTimeOfDay(hour: int.parse(match.namedGroup('hour')), minute: int.parse(match.namedGroup('minute')));
    }
    return null;
  }

  String toString() {
     return '${this.hour.toString().padLeft(2, '0')}:${this.minute.toString().padLeft(2, '0')}';
  }
}

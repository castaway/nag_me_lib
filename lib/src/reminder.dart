import 'package:intl/intl.dart';
import 'package:nag_me_lib/nag_me.dart';

enum ReminderStatus { created, running, waiting }

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
  DateTime next_time;
  ReminderStatus status;

  Reminder({
    this.id,
    this.owner_id,
    this.verb,
    this.reminder_text,
    this.regularity,
    this.start_time,
    this.next_time,
    this.status = ReminderStatus.created,
  }) {
    if (this.next_time == null) {
      var now = DateTime.now();
      this.next_time = new DateTime(now.year, now.month, now.day,
              this.start_time.hour, this.start_time.minute)
          .toUtc();
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
      next_time: DateTime.parse(fbObj['next_time']).toUtc(),
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
      'next_time': next_time.toIso8601String(),
      'status': status.index
    };
  }

  // Update the next_time (and save it!?)
  bool taskDone() {
    print('Updated next_time: ${this.next_time}');
    this.next_time = this.next_time.add(Duration(days: 1));
    this.status = ReminderStatus.waiting;
    print('Updated next_time: ${this.next_time}');
    return true;
  }

  String asString() {
    return 'Have you ${this.verb} your ${this.reminder_text}?';
  }

  String displayString() {
    return '${this.asString()}\n\tDue: ${DateFormat('yyyy-MM-dd HH:mm').format(this.next_time)}';
  }

  String asEditString() {
    return '${this.verb};${this.reminder_text};${DateFormat('yyyy-MM-dd HH:mm').format(this.next_time)}';
  }

  Reminder updateFromString(String updateStr) {
    var values = updateStr.split(';');
    print(updateStr);
    if (values.length < 3) {
      print('Edit reminder had incorrect parameters: $updateStr');
      return this;
    }
    print(values);
    return Reminder(
      id: this.id,
      owner_id: this.owner_id,
      verb: values[0],
      reminder_text: values[1],
      regularity: this.regularity,
      start_time: this.start_time,
      next_time: DateTime.parse(values[2]).toUtc(),
    );
  }

  static Reminder newFromString(String newStr, String ownerId) {
    var values = newStr.split(';');
    print(newStr);
    // FIXME: Exception?
    // if (values.length < 3) {
    //   print('Edit reminder had incorrect parameters: $newStr');
    //   return this;
    // }
    print(values);

    var nextTime = DateTime.parse(values[2]).toUtc();
    return Reminder(
      id: null,
      owner_id: ownerId,
      verb: values[0],
      reminder_text: values[1],
      regularity: 'daily',
      start_time: NagTimeOfDay(hour: nextTime.hour, minute: nextTime.minute),
      next_time: nextTime,
    );
  }
}

// This exists in flutter but.. not in dart!?
class NagTimeOfDay {
  final num hour;
  final num minute;

  NagTimeOfDay({this.hour, this.minute});
}

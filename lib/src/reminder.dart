
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

  Reminder({
    this.id,
    this.owner_id,
    this.verb,
    this.reminder_text,
    this.regularity,
    this.start_time,
    this.next_time,
  }) {
    if (this.next_time == null) {
      var now = DateTime.now();
      this.next_time = new DateTime(now.year, now.month, now.day,
        this.start_time.hour, this.start_time.minute).toUtc();
    }
  }

  Reminder.fromFirebase(fbObj, owner_id) : this(
    id: fbObj.id,
    owner_id: owner_id,
    verb: fbObj['verb'],
    reminder_text: fbObj['reminder_text'],
    regularity: fbObj['regularity'],
    start_time: NagTimeOfDay(hour: fbObj['start_time']['hour'], minute: fbObj['start_time']['minute']),
    next_time: DateTime.parse(fbObj['next_time']).toUtc(),
  );

  Map toMap() {
    return <String, dynamic>{
      'owner_id': owner_id,
      'verb': verb,
      'reminder_text': reminder_text,
      'regularity': regularity,
      'start_time': <String, int>{ 'hour': start_time.hour, 'minute':start_time.minute },
      'next_time': next_time.toIso8601String(),
    };
  }

  // Update the next_time (and save it!?)
  bool taskDone() {
    print('Updated next_time: ${this.next_time}');
    this.next_time = this.next_time.add(Duration(days: 1));
    print('Updated next_time: ${this.next_time}');
  }

  String asString() {
    return 'Have you ${this.verb} your ${this.reminder_text}?';
  }
}


// This exists in flutter but.. not in dart!?
class NagTimeOfDay {
  final num hour;
  final num minute;

  NagTimeOfDay({ this.hour, this.minute });
}

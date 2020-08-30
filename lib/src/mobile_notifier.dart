import 'dart:convert';
import './notifier_service.dart';
import './notifier.dart';
import './reminder.dart';

// "implements"?
class MobileNotifier extends NotifierSetting {
  NotifierService service;

  MobileNotifier(
    [ service ]
  ) : this.service = service, super('Mobile', '');

  @override
  String toString() {
    return jsonEncode({
      'name': this.name,
    });
  }

  String toDisplay() {
    return '';
  }

  List<Map> toFields(Map newNotifier) {
    return [ ];
  }

  Future<bool> notifyUser(Reminder reminder) async {
    // this.service .. 
    print('Sending mobile notification!');
    final result = await service.sendMessage(reminder.owner_id, reminder.id, reminder.asString());
    print('notified, result: $result');
    if (result is String) {
      return true;
    }
    return false;
  }
}

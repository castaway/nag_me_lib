import 'dart:convert';
import 'package:nag_me_services/notifier_service.dart';
import 'package:teledart/model.dart';
import './notifier.dart';
import './reminder.dart';

// "implements"?
class TelegramNotifier extends NotifierSetting {
  final String username;
  // TelegramService service;
  NotifierService service;

  TelegramNotifier(
    this.username,
    [ service ]
  ) : this.service = service, super('Telegram');

  @override
  String toString() {
    return jsonEncode({
      'name': this.name,
      'username': this.username,
    });
  }

  String toDisplay() {
    return 'Username: ${this.username}';
  }

  List<Map> toFields(Map newNotifier) {
    return [
      { 'label': 'Telegram username',
        'fieldName': 'username',
        'validator': (value) {
          if (value.isEmpty) {
            return 'Please enter a username';
          }
          return null;
        },
        'onSaved': (value) {
          newNotifier['notifier'] = Notifier(
            owner_id: newNotifier['notifier'].owner_id,
            engine: newNotifier['notifier'].engine,
            settings: new TelegramNotifier((value.trim()),
            ),
          );
        },
      },
    ];
  }

  Future<bool> notifyUser(Reminder reminder) async {
    // this.service .. 
    print('Calling Telegram!');
    final result = await service.sendMessage(this.username, reminder.id, reminder.asString());
    print('notified, result: $result');
    if (result is Message) {
      return true;
    }
    return false;
  }
}

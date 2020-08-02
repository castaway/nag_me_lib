import 'dart:convert';
import './telegram_service.dart';
import './notifier.dart';

class TelegramNotifier extends NotifierSetting {
  final String username;
  //TelegramService service;
  Object service;

  TelegramNotifier(
    this.username,
    [ service ]
  ) : this.service = service != null ? service : TelegramService(), super('Telegram');

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


  Future<bool> notifyUser() async {
    // this.service .. 
    print('Calling Telegram!');
    // telegram.sendMessage('@${this.username}');
    
  }
}

import 'dart:convert';
import './notifier_service.dart';
import './telegram_notifier.dart';
import './mobile_notifier.dart';
import './reminder.dart';

enum Engine  { Telegram, Twitter, Mobile, Email }
class Notifier {
  final String owner_id;
  final Engine engine;
  final NotifierSetting settings;
  final DateTime _last_modified;
  var has_changed;

  // FIXME: 'Settings' also contains the service object + calls, so rename it?
  
  Notifier({
    this.owner_id,
    this.engine,
    this.settings,
    this.has_changed = false,
    last_modified,
  }) : _last_modified = last_modified ?? DateTime.now().toUtc();

  get last_modified => _last_modified;

  factory Notifier.fromFirebase(fbObj, owner_id, service) {
    Engine engine = Engine.values.firstWhere((val) => val.toString() == fbObj['engine']);
    return Notifier(
      owner_id: owner_id,
      engine: engine,
      settings: NotifierSetting.getInstance(
        engine,
        jsonDecode(fbObj['settings']),
        service
      ),
      last_modified: DateTime.parse(fbObj['last_modified']),
    );
  }
}

// Base class for different Notifier variations
abstract class NotifierSetting {
  final String name;
  NotifierService service;

  NotifierSetting(this.name);

  // Return the correct instance according to the chosen engine for this
  // notifier
  factory NotifierSetting.getInstance(Engine chosen, [Map settings, dynamic service]) {
    switch (chosen) {
      case Engine.Telegram:
        return TelegramNotifier(settings != null ? settings['username'] : '', service );
        break;
      case Engine.Email:
        return null;
        break;
      case Engine.Mobile:
        return MobileNotifier(service);
        break;
      case Engine.Twitter:
        return null;
        break;
      default:
        print('Unknown Engine value');
        return null;
    }
  }

  // Abstract method that sub classes must implement
  // void setValues();

  List<Map> toFields(Map newNotifier);
  String toDisplay();
  Future<bool> notifyUser(Reminder reminder);
}


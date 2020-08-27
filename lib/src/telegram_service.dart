import 'dart:io';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import './notifier_service.dart';
import './config.dart';

class TelegramService implements NotifierService {
  static TelegramConfig config() => TelegramConfig(Platform.script.resolve('telegram_config.yaml').toFilePath());
  final TeleDart teledart;
  var waitingOnResponse = <String, Map<String,dynamic>>{};
  var userMap = <String,int>{};

  TelegramService(
  ) : teledart = TeleDart(Telegram(config().token), Event())
  ;

  void start() {
    this.teledart.start().then((me) => print('${me.username} is initialised'));

    this.teledart
    .onMessage(keyword: 'nagme')
    .listen((message) {
        userMap[message.chat.username] = message.from.id;
        message.reply('Hello! ${message.chat.username}');
    });
    this.teledart
    .onMessage(keyword: 'yes')
    .listen((message) {
      print('waiting: $waitingOnResponse');
      if(waitingOnResponse.containsKey(message.chat.username)
          && !waitingOnResponse[message.chat.username]['result']) {
        waitingOnResponse[message.chat.username]['result'] = true;
        message.reply('Well done!');
      }
    });
  }

  Map forFirebase() {
    return <String, dynamic>{
      'name': 'Telegram',
      'data': {'userMap':userMap}
    };
  }

  void fromFirebase(Map savedData) {
    if(savedData.containsKey('userMap') && userMap.isEmpty) {
      userMap = Map<String, int>.from(savedData['userMap']);
    }
  }

  void fromUser(Map userData) {}

  Future<Object> sendMessage(String username, String key, String message) async {
    // Add https://core.telegram.org/bots/api#inlinekeyboardmarkup ?
    // Do we need to store which reminder these are for in case of multiple?? - Probably
    waitingOnResponse[username] = { 'key': key, 'result': false};
    if(!userMap.containsKey(username)) {
      print('No userid known for $username!');
      return null;
    }
    Message msg = await this.teledart.telegram.sendMessage(userMap[username], message);
    return msg;
  }

  List<dynamic> getFinishedTasks() {
    Iterable<MapEntry> ime = waitingOnResponse.entries.where(
            (entry) => entry.value['result'] == true);

    List<dynamic> finished = ime.map( (e) => e.value['key']).toList();

    waitingOnResponse.removeWhere((key, value) => value['result'] == true);
    return finished;
  }
}

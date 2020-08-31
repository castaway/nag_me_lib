import 'dart:io';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import './notifier_service.dart';
import './config.dart';

class TelegramService implements NotifierService {
  static TelegramConfig config() => TelegramConfig(
      Platform.script.resolve('telegram_config.yaml').toFilePath());
  final TeleDart teledart;
  var userKeys = {};

  var _waitingOnResponse = <String, Map<String, dynamic>>{};
  var _incomingCommands = <String, List<String>>{};
  var _userMap = <String, int>{};

  TelegramService() : teledart = TeleDart(Telegram(config().token), Event());

  // for testing!?
  set waitingOnResponse(Map val) => _waitingOnResponse = val;
  Map<String, List<String>> get incomingCommands => _incomingCommands;
  void clearCommands() => _incomingCommands = {};

  void start() {
    this.teledart.start().then((me) => print('${me.username} is initialised'));

    this.teledart.onMessage(keyword: 'nagme').listen((message) {
      _userMap[message.chat.username] = message.from.id;
      message.reply('Hello! ${message.chat.username}');
    });
    this.teledart.onMessage(keyword: 'yes').listen((message) {
      print('waiting: $_waitingOnResponse');
      if (_waitingOnResponse.containsKey(message.chat.username) &&
          !_waitingOnResponse[message.chat.username]['result']) {
        _waitingOnResponse[message.chat.username]['result'] = true;
        message.reply('Well done!');
      }
    });

    // all commands?
    this.teledart.onCommand().listen((message) {
      var who = this.userKeys[message.chat.username];
      print('incoming command for $who, ${message.text}');
      _incomingCommands[who] ??= <String>[];
      _incomingCommands[who].add(message.text);
    });
  }

  void stop() {
    this.teledart.removeLongPolling();
  }

  Map forFirebase() {
    return <String, dynamic>{
      'name': 'Telegram',
      'data': {'userMap': _userMap}
    };
  }

  void fromFirebase(Map savedData) {
    if (savedData.containsKey('userMap') && _userMap.isEmpty) {
      _userMap = Map<String, int>.from(savedData['userMap']);
    }
  }

  void fromUser(Map userData) {}

  // Message to user X
  // key = the notification object id
  // message = String or with buttons
  Future<Object> sendMessage(
      String username, String key, dynamic message) async {
    // Add https://core.telegram.org/bots/api#inlinekeyboardmarkup ?
    // Do we need to store which reminder these are for in case of multiple?? - Probably

    // No key = just a response to a query, not a notification
    if (key != null) {
      _waitingOnResponse[username] = {'key': key, 'result': false};
    }
    if (!_userMap.containsKey(username)) {
      print('No userid known for $username!');
      return null;
    }
    final messageText = message is String ? message : message['text'];
    final buttons = message is Map ? message['buttons'] : null;
    print('Sending message: $messageText, to $username');
    Message msg = await this
        .teledart
        .telegram
        .sendMessage(_userMap[username], messageText, reply_markup: buttons);
    return msg;
  }

  List<dynamic> getFinishedTasks() {
    Iterable<MapEntry> ime = _waitingOnResponse.entries
        .where((entry) => entry.value['result'] == true);

    List<dynamic> finished = ime.map((e) => e.value['key']).toList();

    _waitingOnResponse.removeWhere((key, value) => value['result'] == true);
    return finished;
  }

  // generate telegram thingies:

  // Basic one-line keyboard buttons (just sends back a response message)
  ReplyKeyboardMarkup makeSimpleButtons(List<String> names) {
    return ReplyKeyboardMarkup(keyboard:
        [names.map((name) => KeyboardButton(text: name)).toList()]);
  }

}

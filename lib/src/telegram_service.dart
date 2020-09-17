import 'dart:io' as io;

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:yaml_config/yaml_config.dart';
import './notifier_service.dart';

class TelegramService implements NotifierService {
  // static TelegramConfig config() => TelegramConfig(
  //     Platform.script.resolve('telegram_config.yaml').toFilePath());
  static Future<TelegramService> getInstance(callbacks) async {
    final config = await YamlConfig.fromFile(io.File(
        io.Platform.script.resolve('telegram_config.yaml').toFilePath()));
    return TelegramService(config, callbacks);
  }

  final TeleDart teledart;
  var userKeys = {};
  final Map<String, Function> callbacks;

  var _waitingOnResponse = <String, Map<String, Map<String, dynamic>>>{};
  var _incomingCommands = <String, List<Map>>{};
  var _userMap = <String, int>{};

  TelegramService(YamlConfig config, Map callbacks)
      : teledart = TeleDart(Telegram(config.getString('token')), Event()),
        callbacks = callbacks;
//  TelegramService() : teledart = TeleDart(Telegram(config().token), Event());

  // for testing!?
  set waitingOnResponse(Map val) => _waitingOnResponse = val;
  Map<String, List<Map>> get incomingCommands => _incomingCommands;
  void clearCommands() => _incomingCommands = {};

  void start() {
    this.teledart.start().then((me) => print('${me.username} is initialised'));

    this.teledart.onMessage(keyword: 'nagme').listen((message) {
      _userMap[message.chat.username] = message.from.id;
      message.reply('Hello! ${message.chat.username}');
    });

    this.teledart.onCommand('chatinfo').listen((message) {
      this
          .teledart
          .telegram
          .getChat(message.chat.id)
          .then((chat) => print(chat.toJson()));
    });

    // inline button callbacks:
    this.teledart.onCallbackQuery().listen((query) {
      // callback data = '$key:$name'
      var cbData = query.data.split(':');
      if (_waitingOnResponse.containsKey(query.from.username) &&
          _waitingOnResponse[query.from.username].containsKey(cbData[0]) &&
          !_waitingOnResponse[query.from.username][cbData[0]]
              .containsKey('result')) {
        if (cbData[1] == 'yes') {
          _waitingOnResponse[query.from.username][cbData[0]]['result'] = true;
          this.teledart.telegram.answerCallbackQuery(query.id);
          this
              .teledart
              .telegram
              .sendMessage(_userMap[query.from.username], 'Well done!');
        } else {
          _waitingOnResponse[query.from.username][cbData[0]]['result'] = false;
          this.teledart.telegram.answerCallbackQuery(query.id);
          this.teledart.telegram.sendMessage(
              _userMap[query.from.username], 'I\'ll nag you again later');
        }
      }
      if (cbData[1].startsWith('/edit')) {
        print('incoming command for ${query.from.username}, ${cbData[1]}');
        _incomingCommands[query.from.username] ??= <Map<String, dynamic>>[];
        var command = <String, dynamic>{'text': cbData[1], 'id': query.id};
        _incomingCommands[query.from.username].add(command);
      }
    });

    // all commands?
    this.teledart.onCommand().listen((message) {
      var who = this.userKeys[message.chat.username];
      if (message.text == '/reminders') {
        print('reminders requested');
        final cb = this.callbacks['reminder_list'];
        final reminderStr = cb('Engine.Telegram', who);
        //var testStr = reminderStr();

        int counter = 1;
        Map reminderList = {
          'text': reminderStr,
          'create_buttons':
              List.generate(counter++, (index) => '/edit ${index + 1}'),
        };
        this.sendMessage(message.chat.username, message.message_id.toString(), reminderList);
      }
      // print('incoming command for $who, ${message.text}');
      // _incomingCommands[who] ??= <Map<String, dynamic>>[];
      // var command = <String, dynamic>{
      //   'text': message.text,
      //   'id': message.message_id
      // };
      // _incomingCommands[who].add(command);
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
  // key = the reminder object id
  // message = String or with buttons
  Future<Object> sendMessage(
      String username, String key, dynamic message) async {
    print('sendMessage: $username, $key, $message');
    // No key = just a response to a query, not a notification
    if (key != null) {
      _waitingOnResponse[username] = {
        key: {}
      };
    }
    if (!_userMap.containsKey(username)) {
      print('No userid known for $username!');
      return null;
    }
    var messageText;
    var buttons;
    if (message is Map) {
      messageText = message['text'];
      buttons = message['buttons'] ??
          makeInlineButtons(names: message['create_buttons'], key: key);
    } else {
      messageText = message;
    }

    print('Sending message: $messageText, to $username');

    Message msg;
    try {
      msg = await this
          .teledart
          .telegram
          .sendMessage(_userMap[username], messageText, reply_markup: buttons);
    } catch (e) {
      print('sendMessage error!: $e');
    }
    _waitingOnResponse[username][key]['msg_id'] = msg.message_id;
    return msg;
  }

  List<dynamic> getFinishedTasks() {
    List<dynamic> finished = [];
    var userCopy = Map.from(_waitingOnResponse);
    for (var user in userCopy.entries) {
      var keyCopy = Map.from(user.value);
      for (var key in keyCopy.entries) {
        if (key.value['result']) {
          finished.add(key.key);
          _waitingOnResponse[user.key].remove(key.key);
        } else {
          if (key.value['result'] == false) {
            _waitingOnResponse[user.key].remove(key.key);
          }
        }
      }
    }

    return finished;
  }

  // generate telegram thingies:

  // Basic one-line keyboard buttons (just sends back a response message)
  ReplyKeyboardMarkup makeSimpleButtons(List<String> names) {
    return ReplyKeyboardMarkup(
        one_time_keyboard: true,
        resize_keyboard: true,
        keyboard: [names.map((name) => KeyboardButton(text: name)).toList()]);
  }

  InlineKeyboardMarkup makeInlineButtons({List<String> names, String key}) {
    if (names.isEmpty) {
      return null;
    }
    return InlineKeyboardMarkup(inline_keyboard: [
      names
          .map((name) =>
              InlineKeyboardButton(text: name, callback_data: '$key:$name'))
          .toList()
    ]);
  }
}

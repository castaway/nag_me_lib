import 'dart:io' as io;

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:yaml_config/yaml_config.dart';
import './notifier_service.dart';
import './reminder.dart';

class TelegramService implements NotifierService {
  // static TelegramConfig config() => TelegramConfig(
  //     Platform.script.resolve('telegram_config.yaml').toFilePath());
  static Future<TelegramService> getInstance(callbacks) async {
    final config = await YamlConfig.fromFile(io.File(
        io.Platform.script.resolve('telegram_config.yaml').toFilePath()));
    return TelegramService(config, callbacks);
  }

  final TeleDart teledart;
  // telegram username => firebase user id
  var userKeys = {};
  final Map<String, Function> callbacks;

  var _waitingOnResponse = <String, Map<String, Map<String, dynamic>>>{};
  var _incomingCommands = <String, List<Map>>{};
  // telegram username => telegram chat id
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
      var checkUser = this.callbacks['check_user'];
      // Anyone got this telegram username saved in a notifier? If no then
      // explain how to create a new user:
      if (!checkUser('Engine.Telegram', message.chat.username)) {
        message.reply('To sign up a new Nag Me account, send me this command:\n/createaccount <email address> <password>\n\nIf preferred you can instead use the initial Android release from: https://github.com/castaway/nag_me_mobile/releases/');
      } else {
        message.reply('Hello! ${message.chat.username}');
      }
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
      print('${query.data}');
      print('${_waitingOnResponse}');
      var cbData = query.data.split(':');
      // Response (yes/no) to a task being finished
      // yes = move reminder time to next day, end scheduler, notify
      // no = notify, nothing else (will re-poke in 30mins)
      // remove waitingOn entry (new one created next sendMessage)
      if (_waitingOnResponse.containsKey(query.from.username) &&
          _waitingOnResponse[query.from.username].containsKey(cbData[0]) &&
          !_waitingOnResponse[query.from.username][cbData[0]]
              .containsKey('result')) {
        if (cbData[1] == 'yes') {
          this.teledart.telegram.answerCallbackQuery(query.id);
          this
              .teledart
              .telegram
              .sendMessage(_userMap[query.from.username], 'Well done!');
          this.callbacks['finish_task'](
              userKeys[query.from.username], cbData[0]);
        } else {
          this.teledart.telegram.answerCallbackQuery(query.id);
          this.teledart.telegram.sendMessage(
              _userMap[query.from.username], 'I\'ll nag you again later');
        }
        // remove this either way, new sendMessage will create another
        _waitingOnResponse[query.from.username].remove(cbData[0]);
      }
    });

    // all commands?
    this.teledart.onCommand().listen((message) {
      var who = this.userKeys[message.chat.username];
      if (message.text == '/reminders') {
        print('reminders requested');
        final cb = this.callbacks['reminder_list'];
        final reminders = cb('Engine.Telegram', who);
        //var testStr = reminderStr();

        int counter = 1;
        // print(reminders[0].asEditString());
        String reminderStr = reminders
            .map((reminder) =>
                '${counter}: ${reminder.displayString()}\n*/edit reminder ${counter++} ${reminder.asEditString()}* (UTC)')
            .join('\n');
        this.sendMessage(message.chat.username, null, reminderStr);
      } else if (message.text.startsWith('/edit reminder') ||
          message.text.startsWith('/add reminder')) {
        var matchRE =
            RegExp(r'/(add|edit) reminder\s*(?<index>\d+)?\s+(?<updateStr>[\w\s;:.-]+)');
        if (matchRE.hasMatch(message.text)) {
          final cb = this.callbacks['reminder_list'];
          final reminders = cb('Engine.Telegram', who);
          var match = matchRE.firstMatch(message.text);
          var newReminder;
          if (match.namedGroup('index') != null) {
            var index = int.parse(match.namedGroup('index')) - 1;
//          print('matches: $index, ${match.namedGroup('updateStr')}');
            newReminder = reminders[index]
                .updateFromString(match.namedGroup('updateStr'));
            reminders[index] = newReminder;
          } else {
            newReminder = Reminder.newFromString(match.namedGroup('updateStr'), null, who);
            reminders.add(newReminder);
          }
            this.callbacks['update_reminders'](reminders);
            this.sendMessage(message.chat.username, null,
                'Updated: ${newReminder.displayString()}');
        }
      } else if (message.text.startsWith('/createaccount')) {
        // createaccount <email> <password>
        var matchRE = RegExp(r'/createaccount (?<email>\S+)\s(?<password>\S+)$');
        if (matchRE.hasMatch(message.text)) {
          print('createaccount matches');
          var match = matchRE.firstMatch(message.text);
          final cb  = this.callbacks['create_user'];
          cb('Engine.Telegram', message.chat.username,
              { 'email':match.namedGroup('email'), 'password': match.namedGroup('password') }).then((result) {
            if (result) {
              print('createaccount created a user');
              _userMap[message.chat.username] = message.from.id;
              message.reply('You\'re all setup! Use **/add reminder <verb>;<reminder text>;<start timestamp>** to create a reminder');
            } else {
              message.reply('Something went wrong there, are you sure that was a valid email address?');
            }
          });
        }
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
    if (!_waitingOnResponse.containsKey(username)) {
      _waitingOnResponse[username] = {};
    }
    if (key != null) {
      _waitingOnResponse[username][key] =  {};
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

    print(
        'Sending message (${messageText.length}): $messageText, to $username');

    Message msg;
    try {
      msg = await this.teledart.telegram.sendMessage(
          _userMap[username], messageText,
          reply_markup: buttons, parse_mode: 'Markdown');
    } catch (e, s) {
      print('sendMessage error!: $e\n$s');
    }
    if (key != null) {
      _waitingOnResponse[username][key]['msg_id'] = msg.message_id;
    }
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

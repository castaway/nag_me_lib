import 'dart:io';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import './config.dart';

class TelegramService {
  static TelegramConfig config() => TelegramConfig(Platform.script.resolve('telegram_config.yaml').toFilePath());
  final TeleDart teledart;

  // TODO: cache somehow expected responses, then respond with the answer
  
  TelegramService(
  ) : teledart = TeleDart(Telegram(config().token), Event())
  ;

  void start() {
    this.teledart.start().then((me) => print('${me.username} is initialised'));

    this.teledart
    .onMessage(keyword: 'nagme')
    .listen((message) {
        print('Message in : ${message.chat.username} (${message.chat.id})');
        print('Said: ${message.text}');
        message.reply('Thanks! ${message.chat.username}');
    });
  }

}

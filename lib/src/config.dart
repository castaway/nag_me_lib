import 'dart:io';
import 'package:safe_config/safe_config.dart';

class TelegramConfig extends Configuration {
  TelegramConfig(String fileName) : super.fromFile(File(fileName));

  String token;
}

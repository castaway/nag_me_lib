import 'dart:io' as io;
import 'package:dartbase_admin/dartbase_admin.dart';
import 'package:dartbase_admin/fcm/message.dart';
import 'package:yaml_config/yaml_config.dart';
import './notifier_service.dart';

// Just needs to send, don't need to wait on responses etc
class MobileService implements NotifierService {
  //static MobileConfig config() => MobileConfig(Platform.script.resolve('mobile_config.yaml').toFilePath());
  static Future<MobileService> getInstance(Map callbacks) async {
    final config = await YamlConfig.fromFile(
        io.File(io.Platform.script.resolve('mobile_config.yaml').toFilePath()));
    return MobileService(config, callbacks);
  }

  var _incomingCommands = {};
  var userKeys = {};
  final Map<String, Function> callbacks;

  Firebase firebase;
  FCM fcm;
  Map userTokens = <String, String>{};

  MobileService(
      YamlConfig config, Map callbacks
  ) : callbacks = callbacks {
      firebase = Firebase(config.getString('fbProjectId'),
          ServiceAccount.fromJson(config.getString('serviceAccount')));
  }
  void clearCommands() => _incomingCommands = {};

  Future<void> start() async {
    await firebase.init();
    fcm = FCM(firebase: firebase, fcmConfig: FCMConfig(firebase: firebase));
  }

  void stop() {
    firebase = null;
    fcm = null;
  }

  Map forFirebase() {
    return <String, dynamic>{
      'name': 'Mobile',
      'data': {'userTokens':userTokens}
    };
  }

  void fromFirebase(Map savedData) {
    if(savedData != null && savedData.containsKey('userTokens') && savedData['userTokens'] != null && userTokens.isEmpty) {
      userTokens = Map<String, String>.from(savedData['userTokens']);
    }
  }
  void fromUser(Map userData) {
    // token saved on user
    if(userData != null) {
      userData.forEach((id, data) {
        userTokens[id] = data['token'];
        });
    }
  }

  // chuck messages into the ether
  Future<Object> sendMessage(String user_id, String key, dynamic message) async {
    final messageId = await fcm.send(Message(
        notification: MessageNotification(title: 'Nag Nag!', body: message),
        token: userTokens[user_id])
    );
    return messageId;
  }

  // collects response statuses (unneeded in the mobile service!)
  List<dynamic> getFinishedTasks() {
    return [];
  }

  Map<String, List<Map>> get incomingCommands => {};
}

import 'dart:io';
import 'package:dartbase_admin/dartbase_admin.dart';
import 'package:dartbase_admin/fcm/message.dart';
import './notifier_service.dart';
import './config.dart';

// Just needs to send, don't need to wait on responses etc
class MobileService implements NotifierService {
  static MobileConfig config() => MobileConfig(Platform.script.resolve('mobile_config.yaml').toFilePath());
  Firebase firebase;
  FCM fcm;
  Map userTokens = <String, String>{};

  MobileService(
  ) {
      Firebase.initialize(config().fbProjectId, ServiceAccount.fromJson(config().serviceAccount))
          .then((fb) => firebase = fb);
  }

  Future<void> start() async {
    fcm = FCM(firebase: firebase, fcmConfig: FCMConfig(firebase: firebase));
    
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
  Future<Object> sendMessage(String user_id, String key, String message) async {
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
}

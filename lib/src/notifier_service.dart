abstract class NotifierService {
  var _incomingCommands = {};
  // store mapping of this service's user info -> user id from firebase
  var userKeys = {};

  void start();
  void stop();
  Future<Object> sendMessage(String username, String key, dynamic message);
  List<dynamic> getFinishedTasks();
  Map<String, List<String>> get incomingCommands;
  void clearCommands() => _incomingCommands = {};
  Map forFirebase();
  void fromFirebase(Map savedData);
  void fromUser(Map userData);
}

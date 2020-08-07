abstract class NotifierService {
  void start();
  Future<Object> sendMessage(String username, String key, String message);
  List<dynamic> getFinishedTasks();
  Map forFirebase();
  void fromFirebase(Map savedData);
}

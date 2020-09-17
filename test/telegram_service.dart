import 'package:test/test.dart';

import '../lib/src/telegram_service.dart';

main() {
  group('telegram service', () async {
      var tgn = await TelegramService.getInstance();
      test('Service has a teledart value', () {
          expect(tgn.teledart, isNot(null));
      });
      test('Finished Tasks returns a list', () {
        var tasks = tgn.getFinishedTasks();
        expect(tasks, isList);
      });
      test('Finished Tasks returns done items', () {
        tgn.waitingOnResponse = {'fred':{'key':'freddy', 'result': false},
          'john':{'key':'jonny', 'result': true}};
        var tasks = tgn.getFinishedTasks();
        expect(tasks[0], equals('jonny'));
        expect(tasks.length, equals(1));
      });
  });
}

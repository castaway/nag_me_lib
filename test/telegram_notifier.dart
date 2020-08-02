import 'package:test/test.dart';

import '../lib/src/telegram_notifier.dart';

main() {
  group('telegram', () {
      var tgn = TelegramNotifier('fred.bloggs');
      test('Name/username set correctly', () {
          expect(tgn.toString(), equals('{"name":"Telegram","username":"fred.bloggs"}'));
          expect(tgn.toDisplay(), equals('Username: fred.bloggs'));
      });
  });
}

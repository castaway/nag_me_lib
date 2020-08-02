import 'package:test/test.dart';

import '../lib/src/telegram_service.dart';

main() {
  group('telegram service', () {
      var tgn = TelegramService();
      test('Service has a teledart value', () {
          expect(tgn.teledart, isNot(null));
      });
  });
}

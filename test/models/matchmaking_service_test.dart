import 'package:flutter_test/flutter_test.dart';
import 'package:chess_2/models/matchmaking_service.dart';

void main() {
  group('isQueueEntryStale', () {
    final now = DateTime(2026, 1, 1, 12, 0, 0);

    test('joinedAt null ise (taze/onaylanmamış kayıt) false döner', () {
      expect(isQueueEntryStale(null, now: now), isFalse);
    });

    test('89 saniye önce katılmış bir kayıt hâlâ taze sayılır', () {
      final joinedAt = now.subtract(const Duration(seconds: 89));
      expect(isQueueEntryStale(joinedAt, now: now), isFalse);
    });

    test('tam 90 saniye sınırında hâlâ taze sayılır (eşitlik dahil değil)', () {
      final joinedAt = now.subtract(const Duration(seconds: 90));
      expect(isQueueEntryStale(joinedAt, now: now), isFalse);
    });

    test('91 saniye önce katılmış bir kayıt hayalet sayılır', () {
      final joinedAt = now.subtract(const Duration(seconds: 91));
      expect(isQueueEntryStale(joinedAt, now: now), isTrue);
    });

    test('saatler önce katılmış bir kayıt kesinlikle hayalet sayılır', () {
      final joinedAt = now.subtract(const Duration(hours: 3));
      expect(isQueueEntryStale(joinedAt, now: now), isTrue);
    });

    test('özel bir staleAfter değeri geçilirse ona göre hesaplar', () {
      final joinedAt = now.subtract(const Duration(seconds: 10));
      expect(
        isQueueEntryStale(joinedAt, now: now, staleAfter: const Duration(seconds: 5)),
        isTrue,
      );
    });
  });
}

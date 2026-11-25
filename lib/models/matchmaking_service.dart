import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'match_state_builder.dart';

/// Flutter Web'de Firebase JS SDK'sından gelen hatalar, Dart tarafına
/// "Dart exception thrown from converted Future..." gibi anlamsız bir
/// sarmalayıcı mesajla düşer; asıl hata bu nesnenin `.error` alanında
/// saklıdır. Bunu (varsa) açığa çıkarır, yoksa normal `toString()`'e döner.
String describeMatchmakingError(Object e) {
  try {
    final dynamic d = e;
    final boxed = d.error;
    if (boxed != null) return '$e  |  gerçek hata: $boxed';
  } catch (_) {
    // `.error` alanı yoksa (native platformlarda genelde olmaz) sorun değil.
  }
  return e.toString();
}

/// Bir kuyruk kaydının `joinedAt` zaman damgasına göre "hayalet" (uygulaması
/// kapanmış/çökmüş, terk edilmiş) sayılıp sayılmayacağını hesaplar. Firestore'a
/// hiç dokunmaz — bu yüzden doğrudan, sahte veriyle birim testi yazılabilir.
/// `joinedAt` null ise (sunucu zaman damgası henüz onaylanmamış taze bir
/// kayıt olabilir) BİLEREK false döner.
bool isQueueEntryStale(
  DateTime? joinedAt, {
  required DateTime now,
  Duration staleAfter = MatchmakingService._staleAfter,
}) {
  if (joinedAt == null) return false;
  return now.difference(joinedAt) > staleAfter;
}

/// Gerçek oyuncuları birbiriyle eşleştiren servis. Sunucu tarafı (Cloud
/// Functions) kullanmadan, tamamen Firestore İŞLEMLERİ (transactions) ile
/// çalışır — bu yüzden ücretsiz (Spark) planla tam uyumludur.
///
/// Akış:
///  1) Oyuncu "Savaş"a basınca `matchmaking_queue/{uid}` altına kendi
///     kaydını yazar ve kendi kaydını dinlemeye başlar.
///  2) Kuyrukta BAŞKA bekleyen biri var mı diye bakar; varsa bir Firestore
///     transaction'ı içinde onunla eşleşmeyi (ve maç dokümanını) atomik
///     olarak oluşturmayı dener.
///  3) Kimseyi bulamazsa pasif bekler: başka biri onu bulup eşleştirdiğinde
///     kendi kuyruk kaydındaki `matchId` alanı dolar, bunu dinleyerek haberdar olur.
class MatchmakingService {
  MatchmakingService._internal();
  static final MatchmakingService instance = MatchmakingService._internal();

  /// Bir kuyruk kaydı bu süreden daha eskiyse "hayalet" (uygulama temiz
  /// kapatılmadan/çökerek terk edilmiş) sayılır ve otomatik silinir. Normal
  /// eşleşme birkaç saniye içinde olur; bu eşik sadece gerçekten terk
  /// edilmiş kayıtları yakalayacak kadar cömert tutuldu.
  static const Duration _staleAfter = Duration(seconds: 90);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _queueCol =>
      _firestore.collection('matchmaking_queue');
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _matchesCol =>
      _firestore.collection('matches');

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _queueSub;
  Timer? _retryTimer;
  bool _searching = false;

  /// Kuyruğa girer ve eşleşme arar. Bulununca [onMatched] (matchId ile),
  /// bir hata olursa [onError] çağrılır. [cancel] ile aramadan vazgeçilebilir.
  Future<void> findMatch({
    required void Function(String matchId) onMatched,
    required void Function(Object error) onError,
  }) async {
    final uid = AuthService.instance.uid;
    if (uid == null) {
      onError(StateError('Oturum açılmamış'));
      return;
    }

    _searching = true;
    try {
      await _queueCol.doc(uid).set({
        'uid': uid,
        'displayName': ProfileService.instance.name,
        'avatar': ProfileService.instance.avatar,
        'trophies': ProfileService.instance.trophies,
        'joinedAt': FieldValue.serverTimestamp(),
        'matchId': null,
      });

      await _queueSub?.cancel();
      _queueSub = _queueCol.doc(uid).snapshots().listen(
        (snap) {
          final matchId = snap.data()?['matchId'];
          if (matchId is String && _searching) {
            _searching = false;
            _retryTimer?.cancel();
            _queueSub?.cancel();
            _queueCol.doc(uid).delete().catchError((_) {});
            onMatched(matchId);
          }
        },
        onError: (Object e) {
          // KRİTİK: Bu olmadan bir izin/bağlantı hatası sessizce yutulur ve
          // ekran sonsuza dek "Rakip Aranıyor" da kalır — hiçbir geri
          // bildirim gelmez. Artık hem terminale yazdırıyor hem UI'a
          // (onError callback'i ile) bildiriyoruz.
          debugPrint('MatchmakingService: kuyruk dinleme hatası: ${describeMatchmakingError(e)}');
          if (_searching) {
            _searching = false;
            _retryTimer?.cancel();
            onError(e);
          }
        },
      );

      // İlk deneme: kuyrukta o an bekleyen biri var mı diye bak.
      await _tryPairWithWaitingOpponent(uid);

      // KRİTİK: Tek seferlik arama yeterli DEĞİL. İki oyuncu neredeyse aynı
      // anda "Savaş"a basarsa, ikisi de birbirinin kuyruğa henüz yazdığını
      // GÖREMEDEN arayıp "kimse yok" sonucuna varabilir ve sonsuza dek pasif
      // beklemede kalabilir (hiçbir hata fırlamadan!). Bunu önlemek için,
      // eşleşene kadar birkaç saniyede bir yeniden dener.
      _retryTimer?.cancel();
      _retryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!_searching) {
          _retryTimer?.cancel();
          return;
        }
        _tryPairWithWaitingOpponent(uid);
      });
    } catch (e, stackTrace) {
      _searching = false;
      debugPrint('MatchmakingService.findMatch hata: ${describeMatchmakingError(e)}');
      debugPrint('$stackTrace');
      onError(e);
    }
  }

  bool _isStale(Map<String, dynamic>? data) {
    final joinedAt = data?['joinedAt'];
    if (joinedAt is! Timestamp) return false;
    return isQueueEntryStale(joinedAt.toDate(), now: DateTime.now());
  }

  Future<void> _tryPairWithWaitingOpponent(String myUid) async {
    // NOT: Burada BİLEREK orderBy('joinedAt') kullanmıyoruz. `where` +
    // farklı bir alanda `orderBy` birlikte kullanılırsa Firestore, sen
    // Console'da manuel oluşturmadıkça sorguyu reddeden bir "composite
    // index" ister. Sıra adaleti (en eski bekleyen önce) yerine basitlik
    // tercih edildi — MVP için yeterli.
    final candidates = await _queueCol
        .where('matchId', isEqualTo: null)
        .limit(5)
        .get();

    debugPrint(
        'MatchmakingService: kuyrukta ${candidates.docs.length} kayıt bulundu '
        '(kendim dahil): ${candidates.docs.map((d) => d.id).toList()}');

    for (final doc in candidates.docs) {
      if (doc.id == myUid) continue;
      if (!_searching) return; // Bu sırada eşleştiysek (başkası bizi buldu) dur.

      if (_isStale(doc.data())) {
        // Uygulaması kapanan/çöken bir oyuncunun kuyrukta sonsuza dek kalan
        // "hayalet" kaydı. Bununla eşleşmeyi denemenin anlamı yok — sil ve
        // sıradaki adaya geç. Bu, tam da "boşken bile hep arama yapıyor"
        // sorununu kaynağında (ve kalıcı olarak, tüm oyuncular için)
        // temizler.
        debugPrint('MatchmakingService: ${doc.id} hayalet kayıt, temizleniyor.');
        await _queueCol.doc(doc.id).delete().catchError((_) {});
        continue;
      }

      debugPrint('MatchmakingService: ${doc.id} ile eşleşme deneniyor...');
      final success = await _tryTransactionalMatch(myUid, doc.id);
      if (success) {
        debugPrint('MatchmakingService: eşleşme BAŞARILI (${doc.id} ile).');
        return;
      }
    }
    // Uygun kimse bulunamadı: pasif bekliyoruz, başka biri bizi bulacak
    // (ya da 3 saniye sonra tekrar aranacak, bkz. findMatch).
  }

  Future<bool> _tryTransactionalMatch(String myUid, String candidateUid) async {
    final matchRef = _matchesCol.doc();
    try {
      await _firestore.runTransaction((tx) async {
        final myQueueRef = _queueCol.doc(myUid);
        final candidateQueueRef = _queueCol.doc(candidateUid);

        final myQueueSnap = await tx.get(myQueueRef);
        final candidateQueueSnap = await tx.get(candidateQueueRef);

        if (!myQueueSnap.exists || !candidateQueueSnap.exists) {
          throw StateError('Kuyruk kaydı bulunamadı');
        }
        if (myQueueSnap.data()?['matchId'] != null ||
            candidateQueueSnap.data()?['matchId'] != null) {
          throw StateError('Zaten eşleşmiş');
        }
        if (_isStale(candidateQueueSnap.data())) {
          // Savunma amaçlı ikinci kontrol: ön-filtreden (dışarıdaki liste
          // taramasından) bu transaction'a kadar geçen sürede kayıt
          // hayalet hâle gelmiş olabilir (nadir ama mümkün). Aynı anda hem
          // temizle hem "bu aday uygun değil" diye bildir.
          tx.delete(candidateQueueRef);
          throw StateError('Hayalet kayıt (temizlendi)');
        }

        final myUserSnap = await tx.get(_usersCol.doc(myUid));
        final candidateUserSnap = await tx.get(_usersCol.doc(candidateUid));
        final myData = myUserSnap.data();
        final candidateData = candidateUserSnap.data();

        final initialState = buildInitialMatchStateJson(
          whiteFormationJson: myData?['formation'] as Map<String, dynamic>?,
          whiteCardLevelsJson: myData?['cardLevels'] as Map<String, dynamic>?,
          blackFormationJson: candidateData?['formation'] as Map<String, dynamic>?,
          blackCardLevelsJson: candidateData?['cardLevels'] as Map<String, dynamic>?,
        );

        tx.set(matchRef, {
          'whiteUid': myUid,
          'blackUid': candidateUid,
          'whiteName': myQueueSnap.data()?['displayName'] ?? '?',
          'blackName': candidateQueueSnap.data()?['displayName'] ?? '?',
          'whiteAvatar': myQueueSnap.data()?['avatar'] ?? '🦁',
          'blackAvatar': candidateQueueSnap.data()?['avatar'] ?? '🦁',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // Maç daha yeni kurulduğu için ikisi de "az önce buradaydı"
          // sayılır — yoksa ilk kalp atışı gelene kadar (birkaç saniye)
          // rakip yanlışlıkla "bağlantısı kopmuş" görünebilir.
          'whiteLastSeen': FieldValue.serverTimestamp(),
          'blackLastSeen': FieldValue.serverTimestamp(),
          ...initialState,
        });

        tx.update(myQueueRef, {'matchId': matchRef.id});
        tx.update(candidateQueueRef, {'matchId': matchRef.id});
      });
      return true;
    } catch (e) {
      final description = describeMatchmakingError(e);
      // NOT: Firestore'un web SDK'sı, transaction içinde fırlatılan Dart
      // hatalarını bazen JS tarafından geçirip sarmalıyor — bu yüzden
      // "beklenen mi beklenmeyen mi" ayrımını TİP kontrolüyle değil, hata
      // metninin içeriğine bakarak yapıyoruz (daha güvenilir).
      final isExpectedContention = description.contains('Kuyruk kaydı bulunamadı') ||
          description.contains('Zaten eşleşmiş') ||
          description.contains('Hayalet kayıt');
      if (isExpectedContention) {
        // Bu BİLEREK fırlatılan, beklenen bir "yarış durumu": aday az önce
        // başkasıyla eşleşmiş. Gerçek bir hata DEĞİL.
        debugPrint('MatchmakingService: aday uygun değil (normal): $description');
      } else {
        // Beklenmeyen bir hata (ör. izin reddi, ağ sorunu). Bunu tekrar
        // tekrar görüyorsan asıl sorun muhtemelen burada.
        debugPrint('MatchmakingService: BEKLENMEYEN eşleşme hatası: $description');
      }
      return false;
    }
  }

  /// Aramadan vazgeçilince ("İptal" butonu) çağrılır.
  Future<void> cancel() async {
    _searching = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _queueSub?.cancel();
    _queueSub = null;
    final uid = AuthService.instance.uid;
    if (uid != null) {
      try {
        await _queueCol.doc(uid).delete();
      } catch (_) {}
    }
  }
}

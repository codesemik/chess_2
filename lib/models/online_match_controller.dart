import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/board_controller.dart';
import 'piece_library.dart';
import 'auth_service.dart';
import 'matchmaking_service.dart' show describeMatchmakingError;

/// Bir oyuncunun "hâlâ bağlı" sayılabilmesi için son kalp atışının üzerinden
/// en fazla bu kadar zaman geçmiş olmalı. Bunu aşarsa "bağlantısı kopmuş
/// olabilir" uyarısı gösterilir.
const Duration kOpponentWarnThreshold = Duration(seconds: 25);

/// Bu kadar süre kalp atışı gelmezse rakip "zaferi ilan et" seçeneği
/// görebilir.
const Duration kOpponentClaimThreshold = Duration(seconds: 45);

/// `matches/{matchId}` dokümanını dinleyip yazan, iki gerçek oyuncu
/// arasındaki canlı bir maçı yöneten sınıf. İçinde normal (yerel) bir
/// [BoardController] taşır — tüm satranç kuralları/özel yetenekler AYNI
/// motorla çalışır; bu sınıf sadece "hamleyi Firestore'a yaz / rakibin
/// hamlesini Firestore'dan oku" katmanını, ayrıca kalp atışı (bağlantı
/// takibi) mantığını ekler.
class OnlineMatchController {
  OnlineMatchController(this.matchId);

  final String matchId;
  final BoardController controller = BoardController();

  String? _myUid;
  Team? myColor;
  String opponentName = '?';
  String opponentAvatar = '🦁';
  String status = 'active';
  String? endReason;
  DateTime? opponentLastSeen;
  bool _disposed = false;

  DocumentReference<Map<String, dynamic>> get _matchRef =>
      FirebaseFirestore.instance.collection('matches').doc(matchId);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _heartbeatTimer;

  /// Dinlemeyi başlatır. Her güncellemede (kendi hamlemiz dahil, rakibin
  /// hamlesi dahil) [onUpdate] çağrılır — ekran bunun içinde `setState`
  /// yapmalı. Ayrıca periyodik olarak "buradayım" sinyali (kalp atışı)
  /// göndermeye başlar.
  void listen(void Function() onUpdate) {
    _myUid = AuthService.instance.uid;
    debugPrint('OnlineMatchController: dinleme başlıyor (matchId=$matchId, benim uid=$_myUid)');
    _sub = _matchRef.snapshots().listen(
      (snap) {
        if (_disposed) return;
        final data = snap.data();
        if (data == null) {
          debugPrint('OnlineMatchController: maç dokümanı BOŞ geldi (henüz yok ya da silindi mi?)');
          return;
        }

        final whiteUid = data['whiteUid'] as String?;
        myColor = (_myUid != null && _myUid == whiteUid) ? Team.white : Team.black;
        final amWhite = myColor == Team.white;
        opponentName = (amWhite ? data['blackName'] : data['whiteName']) as String? ?? '?';
        opponentAvatar = (amWhite ? data['blackAvatar'] : data['whiteAvatar']) as String? ?? '🦁';
        status = data['status'] as String? ?? 'active';
        endReason = data['endReason'] as String?;

        final rawSeen = amWhite ? data['blackLastSeen'] : data['whiteLastSeen'];
        if (rawSeen is Timestamp) opponentLastSeen = rawSeen.toDate();

        controller.loadFromMatchStateJson(data);
        onUpdate();
      },
      onError: (Object e) {
        debugPrint('OnlineMatchController: maç dinleme hatası: ${describeMatchmakingError(e)}');
      },
    );

    _sendHeartbeat();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 12), (_) => _sendHeartbeat());
  }

  void _sendHeartbeat() {
    if (_disposed || myColor == null || status != 'active') return;
    final field = myColor == Team.white ? 'whiteLastSeen' : 'blackLastSeen';
    _matchRef.set({field: FieldValue.serverTimestamp()}, SetOptions(merge: true)).catchError((e) {
      debugPrint('OnlineMatchController: kalp atışı gönderilemedi: ${describeMatchmakingError(e)}');
    });
  }

  /// Rakibin son kalp atışının üzerinden [kOpponentWarnThreshold]'dan fazla
  /// zaman geçtiyse true döner (bağlantısı kopmuş OLABİLİR).
  bool get opponentSeemsAway {
    final seen = opponentLastSeen;
    if (seen == null) return false;
    return DateTime.now().difference(seen) > kOpponentWarnThreshold;
  }

  /// Rakibin son kalp atışının üzerinden [kOpponentClaimThreshold]'dan fazla
  /// zaman geçtiyse true döner — bu durumda "Zaferi İlan Et" gösterilebilir.
  bool get canClaimVictory {
    if (controller.winner != null) return false;
    final seen = opponentLastSeen;
    if (seen == null) return false;
    return DateTime.now().difference(seen) > kOpponentClaimThreshold;
  }

  void dispose() {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _sub?.cancel();
  }

  bool get isMyTurn =>
      myColor != null && controller.winner == null && controller.currentTurn == myColor;

  /// Bir hamle dener. Sıra bizdeyse ve hamle kurallara uygunsa hem yerel
  /// tahtaya uygulanır hem de anında Firestore'a yazılır (rakibin
  /// cihazına canlı yansır). Döner: hamle gerçekleştiyse true.
  Future<bool> tryMove(int fromRow, int fromCol, int toRow, int toCol) async {
    if (!isMyTurn) {
      debugPrint(
          'OnlineMatchController.tryMove: sıra sende değil (myColor=$myColor, '
          'currentTurn=${controller.currentTurn}, winner=${controller.winner}) — hamle reddedildi.');
      return false;
    }
    final moved = controller.movePiece(fromRow, fromCol, toRow, toCol);
    if (!moved) {
      debugPrint('OnlineMatchController.tryMove: BoardController hamleyi kabul etmedi (kural dışı?).');
      return false;
    }
    debugPrint('OnlineMatchController.tryMove: yerel hamle OK, Firestore\'a yazılıyor...');
    await _push();
    return true;
  }

  /// Zaman Lordu'nun "Geri Sarma" yeteneğini dener; başarılıysa yeni
  /// durumu Firestore'a yazar.
  Future<bool> tryRewind(Piece actor) async {
    final success = controller.rewind(actor);
    if (success) await _push();
    return success;
  }

  Future<void> _push() async {
    final json = controller.toMatchStateJson();
    json['updatedAt'] = FieldValue.serverTimestamp();
    if (controller.winner != null) {
      json['status'] = 'finished';
      json['endReason'] = 'king_captured';
    }
    try {
      await _matchRef.set(json, SetOptions(merge: true));
      debugPrint('OnlineMatchController: Firestore yazma BAŞARILI (sıra artık: ${json['currentTurn']}).');
    } catch (e) {
      // KRİTİK: Bunu sessizce yutmuyoruz artık — yazma başarısız olursa
      // rakip hamleni HİÇ görmez ve ekranın neden senkron olmadığını
      // anlayamayız. Terminale yazdırıyoruz.
      debugPrint('OnlineMatchController: Firestore yazma BAŞARISIZ: ${describeMatchmakingError(e)}');
    }
  }

  /// Maçtan çekilme ("Pes Et"). Rakip otomatik olarak kazanan sayılır.
  Future<void> resign() async {
    if (myColor == null) return;
    final winnerTeam = myColor == Team.white ? Team.black : Team.white;
    try {
      await _matchRef.set({
        'winner': winnerTeam.name,
        'status': 'finished',
        'endReason': 'resigned',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('OnlineMatchController.resign: yazma başarısız: ${describeMatchmakingError(e)}');
    }
  }

  /// Rakip uzun süredir kalp atışı göndermiyorsa ("bağlantısı kopmuş
  /// olabilir") çağrılabilir: zaferi bize verir. Sadece [canClaimVictory]
  /// true iken anlamlıdır — ama burada tekrar kontrol edilmez, UI zaten
  /// butonu sadece o zaman gösterir.
  Future<void> claimVictoryByDisconnect() async {
    if (myColor == null) return;
    try {
      await _matchRef.set({
        'winner': myColor!.name,
        'status': 'finished',
        'endReason': 'opponent_disconnected',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('OnlineMatchController.claimVictoryByDisconnect: yazma başarısız: ${describeMatchmakingError(e)}');
    }
  }
}

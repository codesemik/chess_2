/// Tüm kartların TEK TOPLANDIĞI yer burasıdır. Her kartın kendi tanımı
/// `pieces/` klasöründe ayrı bir dosyada yaşar (ör. `pieces/goblin.dart`,
/// `pieces/ejderha_kralice.dart`). Yeni bir kart eklemek istersen:
///   1. `pieces/` altında yeni bir dosya oluştur (bir örneğini kopyala).
///   2. Aşağıya `import` satırını ekle.
///   3. `PieceLibrary` içindeki uygun listeye ekle.
///
/// Bu dosya dışındaki tüm ekranlar/servisler sadece bu dosyayı import eder
/// (`piece_base.dart` buradan `export` edildiği için Piece, Team, Rarity,
/// SpecialAbility gibi tipler de otomatik gelir).

export 'pieces/piece_base.dart';

import 'pieces/piece_base.dart';

import 'pieces/pawn.dart';
import 'pieces/queen.dart';
import 'pieces/king.dart';
import 'pieces/knight_basic.dart';
import 'pieces/bishop_basic.dart';
import 'pieces/rook_basic.dart';

import 'pieces/goblin.dart';
import 'pieces/sipahi.dart';
import 'pieces/maden_muhafizi.dart';
import 'pieces/golge_piyonu.dart';

import 'pieces/pegasus.dart';
import 'pieces/kabus.dart';

import 'pieces/skele_archer.dart';
import 'pieces/buyucu.dart';
import 'pieces/saman.dart';

import 'pieces/golem.dart';
import 'pieces/mancinik.dart';
import 'pieces/barikat.dart';

import 'pieces/dark_enchantress.dart';
import 'pieces/ejderha_kralice.dart';
import 'pieces/zaman_lordu.dart';

import 'pieces/armored_king.dart';
import 'pieces/savasci_kral.dart';
import 'pieces/necromancer_sah.dart';

/// Oyundaki tüm kartların şablon tanımları.
/// Mağaza, Kartlarım, Diziliş editörü, Kart Test Odası ve varsayılan
/// dizilim burada tanımlı tekil (singleton) örnekleri referans olarak
/// kullanır.
class PieceLibrary {
  // --- Başlangıç (ücretsiz / temel) kartlar — mağazada satılmaz ---
  static final Piece pawn = pawnBasicPiece;
  static final Piece queen = queenBasicPiece;
  static final Piece king = kingBasicPiece;
  static final Piece knightBasic = knightBasicPiece;
  static final Piece bishopBasic = bishopBasicPiece;
  static final Piece rookBasic = rookBasicPiece;

  /// Ücretsiz başlangıç kartları (mağazada satılmaz, herkes bunlara sahiptir).
  static final List<Piece> starterCards = [
    pawn, queen, king, knightBasic, bishopBasic, rookBasic,
  ];

  // --- Piyon varyasyonları ---
  static final Piece goblin = goblinPiece;
  static final Piece sipahi = sipahiPiece;
  static final Piece madenMuhafizi = madenMuhafiziPiece;
  static final Piece golgePiyonu = golgePiyonuPiece;

  // --- At varyasyonları ---
  static final Piece pegasus = pegasusPiece;
  static final Piece kabus = kabusPiece;

  // --- Fil varyasyonları ---
  static final Piece skeleArcher = skeleArcherPiece;
  static final Piece buyucu = buyucuPiece;
  static final Piece saman = samanPiece;

  // --- Kale varyasyonları ---
  static final Piece golem = golemPiece;
  static final Piece mancinik = mancinikPiece;
  static final Piece barikat = barikatPiece;

  // --- Vezir varyasyonları ---
  static final Piece darkEnchantress = darkEnchantressPiece;
  static final Piece ejderhaKralice = ejderhaKralicePiece;
  static final Piece zamanLordu = zamanLorduPiece;

  // --- Şah varyasyonları ---
  static final Piece armoredKing = armoredKingPiece;
  static final Piece savasciKral = savasciKralPiece;
  static final Piece necromancerSah = necromancerSahPiece;

  /// Oyundaki tüm kartlar (koleksiyon ekranı ve test odası bunu kullanır).
  static final List<Piece> all = [
    ...starterCards,
    goblin, sipahi, madenMuhafizi, golgePiyonu,
    pegasus, kabus,
    skeleArcher, buyucu, saman,
    golem, mancinik, barikat,
    darkEnchantress, ejderhaKralice, zamanLordu,
    armoredKing, savasciKral, necromancerSah,
  ];

  /// Sadece mağazada satılan (temel olmayan) kartlar.
  static final List<Piece> storeItems = [
    goblin, sipahi, madenMuhafizi, golgePiyonu,
    pegasus, kabus,
    skeleArcher, buyucu, saman,
    golem, mancinik, barikat,
    darkEnchantress, ejderhaKralice, zamanLordu,
    armoredKing, savasciKral, necromancerSah,
  ];

  /// Mağazayı / test odasını kategori başlıklarıyla göstermek için
  /// gruplandırılmış listeler.
  static final List<Piece> pawnTierStoreItems = [goblin, sipahi, madenMuhafizi, golgePiyonu];
  static final List<Piece> knightTierStoreItems = [pegasus, kabus];
  static final List<Piece> bishopTierStoreItems = [skeleArcher, buyucu, saman];
  static final List<Piece> rookTierStoreItems = [golem, mancinik, barikat];
  static final List<Piece> queenTierStoreItems = [darkEnchantress, ejderhaKralice, zamanLordu];
  static final List<Piece> kingTierStoreItems = [armoredKing, savasciKral, necromancerSah];

  static Piece byId(String id) => all.firstWhere(
        (p) => p.id == id,
        orElse: () => pawn,
      );

  static List<Piece> byRole(CardRole role) =>
      all.where((p) => p.roles.contains(role)).toList();
}

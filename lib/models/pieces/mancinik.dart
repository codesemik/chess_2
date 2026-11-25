import 'piece_base.dart';

/// 🏰 Mancınık Kulesi — Uzak Atış: hareket etmez; bunun yerine düz
/// hattındaki TAM 3 kare uzaklıktaki bir rakibi, aradaki taşları
/// görmezden gelerek vurabilir. Vurduğunda yerinde kalır.
/// TEST İPUCU: Taşı seç; sadece tam 3 kare uzaktaki düşmanlar kırmızı
/// nokta olarak görünür (aradaki taş engel olmaz), başka hiçbir hareket
/// seçeneği yoktur.
final Piece mancinikPiece = Piece(
  id: 'mancinik',
  nameKey: 'piece_mancinik',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.rookStyle,
  emoji: '🏰',
  hp: 2,
  maxHp: 2,
  attackPower: 3,
  rarity: Rarity.rare,
  roles: const [CardRole.dps],
  ability: SpecialAbility.catapultStrike,
);

import 'piece_base.dart';

/// 💀 Ölüçağıran Şah — Ruh Çağırma: takımın hiç piyonu kalmadıysa,
/// oyunda bir kez, boş bitişik bir kareye "yürümek" yerine bir
/// iskelet piyon çağırabilir.
/// TEST İPUCU: Bu senaryoda takımın hiç piyonu yok (koşul otomatik
/// sağlanmış durumda). Şahı seç, boş bitişik bir kareye dokun — bir
/// piyon yerine hareket etmek yerine oraya yeni bir iskelet piyon
/// belirecek.
final Piece necromancerSahPiece = Piece(
  id: 'necromancer_sah',
  nameKey: 'piece_necromancer_sah',
  type: PieceType.king,
  team: Team.white,
  moveStyle: MoveStyle.kingStyle,
  emoji: '💀',
  hp: 3,
  maxHp: 3,
  attackPower: 1,
  rarity: Rarity.legendary,
  roles: const [CardRole.king],
  ability: SpecialAbility.soulSummon,
);

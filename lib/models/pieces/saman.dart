import 'piece_base.dart';

/// 🪶 Şaman — Ruh Yolu: takımın en az 1 ölü piyonu varsa, çapraz hattı
/// boyunca ilerlerken bir kez 90° kırıp diğer çapraz aileye geçebilir.
/// TEST İPUCU: Bu senaryoda takımın zaten 1 "ölü piyonu" var sayılıyor
/// (test için önceden ayarlandı). Taşı seç ve normal çaprazların ötesinde
/// beliren "kırılmış" yeşil noktaları takip et.
final Piece samanPiece = Piece(
  id: 'saman',
  nameKey: 'piece_saman',
  type: PieceType.custom,
  team: Team.white,
  moveStyle: MoveStyle.bishopStyle,
  emoji: '🪶',
  hp: 2,
  maxHp: 2,
  attackPower: 2,
  rarity: Rarity.epic,
  roles: const [CardRole.dps],
  ability: SpecialAbility.spiritPath,
);

import 'piece_base.dart';

/// ⛏️ Maden Muhafızı — Taş Deri: ilk ölümcül vuruşu absorbe eder,
/// 1 can ile hayatta kalır. İkinci ölümcül vuruşta gerçekten elenir.
/// TEST İPUCU: Bir rakip taşla ona 2 kez vur; ilkinde hayatta kalıp
/// yetenek ikonu grileşecek, ikincisinde elenecek.
final Piece madenMuhafiziPiece = Piece(
  id: 'maden_muhafizi',
  nameKey: 'piece_maden_muhafizi',
  type: PieceType.pawn,
  team: Team.white,
  moveStyle: MoveStyle.pawnStyle,
  emoji: '⛏️',
  hp: 1,
  maxHp: 1,
  attackPower: 1,
  rarity: Rarity.rare,
  roles: const [CardRole.pawn],
  ability: SpecialAbility.stoneSkin,
);

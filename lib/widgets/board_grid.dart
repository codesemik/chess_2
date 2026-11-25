import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/piece_library.dart';
import '../controllers/board_controller.dart';

/// 4x8 satranç tahtasını çizen, hem gerçek maç ekranında (Oyun sekmesi)
/// hem de Kart Test Odası'nda kullanılan paylaşılan widget. Sadece görsel
/// çizimden sorumludur; seçim durumu ve dokunma mantığı çağıran ekranda
/// (State) yaşar ve callback'ler üzerinden buraya aktarılır.
class BoardGrid extends StatelessWidget {
  final BoardController controller;
  final int? selectedRow;
  final int? selectedCol;
  final List<Point> highlightedMoves;
  final void Function(int row, int col) onSquareTap;
  final void Function(Piece piece)? onPieceLongPress;

  const BoardGrid({
    Key? key,
    required this.controller,
    required this.selectedRow,
    required this.selectedCol,
    required this.highlightedMoves,
    required this.onSquareTap,
    this.onPieceLongPress,
  }) : super(key: key);

  static const int rows = BoardController.rows;
  static const int cols = BoardController.cols;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: cols / rows,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows * cols,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ cols;
          final col = index % cols;
          return _buildSquare(row, col);
        },
      ),
    );
  }

  Widget _buildSquare(int row, int col) {
    final isDark = (row + col) % 2 == 1;
    final piece = controller.grid[row][col];
    final isSelected = (selectedRow == row && selectedCol == col);
    final isMoveTarget = highlightedMoves.contains(Point(row, col));
    final isOnFire = controller.isSquareOnFire(row, col);
    final isKingInCheck = controller.lastMoveWasCheck &&
        controller.winner == null &&
        piece != null &&
        piece.isKingPiece &&
        piece.team == controller.currentTurn;

    return GestureDetector(
      onTap: () => onSquareTap(row, col),
      onLongPress: piece != null && onPieceLongPress != null
          ? () => onPieceLongPress!(piece)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: isOnFire
              ? Colors.deepOrange[700]
              : (isDark ? Colors.brown[600] : Colors.amber[200]),
          border: isSelected
              ? Border.all(color: Colors.greenAccent, width: 4)
              : isKingInCheck
                  ? Border.all(color: Colors.redAccent, width: 3)
                  : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isOnFire)
              const Positioned(
                top: 2,
                child: Text('🔥', style: TextStyle(fontSize: 12)),
              ),
            if (piece != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Text(piece.emoji, style: const TextStyle(fontSize: 18)),
                      if (piece.shieldTurns > 0)
                        const Positioned(
                          right: -8,
                          top: -4,
                          child: Icon(Icons.shield, size: 12, color: Colors.lightBlueAccent),
                        ),
                      if (piece.frozenTurns > 0)
                        const Positioned(
                          left: -8,
                          top: -4,
                          child: Icon(Icons.ac_unit, size: 12, color: Colors.cyanAccent),
                        ),
                      if (piece.hasSpecialAbility)
                        Positioned(
                          right: -8,
                          bottom: -4,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 10,
                            color: piece.specialUsed ? Colors.grey : Colors.amberAccent,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    piece.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: piece.team == Team.white ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: Colors.black54,
                    child: Text(
                      '${loc('hp')}: ${piece.hp}/${piece.maxHp}',
                      style: const TextStyle(fontSize: 9, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            if (isMoveTarget)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: piece == null
                      ? Colors.greenAccent.withOpacity(0.7)
                      : Colors.redAccent.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bir taşın can/hareket/yetenek bilgisini gösteren, her iki ekranda da
/// (Oyun ve Kart Test Odası) aynı şekilde kullanılan bilgi kutusu.
void showPieceInfoDialog(BuildContext context, Piece piece) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Text(piece.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(piece.name)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
              Text(' ${piece.hp}/${piece.maxHp}   '),
              const Icon(Icons.bolt, size: 14, color: Colors.orangeAccent),
              Text(' ${piece.attackPower}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(piece.moveDescription, style: const TextStyle(fontSize: 13)),
          if (piece.hasSpecialAbility) ...[
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: Colors.amberAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    piece.abilityDescription,
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            if (piece.specialUsed) ...[
              const SizedBox(height: 6),
              Text('(${loc('ability_used')})',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc('piece_info_close')),
        ),
      ],
    ),
  );
}

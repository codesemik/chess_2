import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/piece_library.dart';
import '../models/collection_service.dart';
import '../utils/rarity_utils.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService.instance, CollectionService.instance]),
      builder: (context, _) {
        final collection = CollectionService.instance;
        final sections = <MapEntry<String, List<Piece>>>[
          MapEntry(loc('tier_pawn'), PieceLibrary.pawnTierStoreItems),
          MapEntry(loc('tier_knight'), PieceLibrary.knightTierStoreItems),
          MapEntry(loc('tier_bishop'), PieceLibrary.bishopTierStoreItems),
          MapEntry(loc('tier_rook'), PieceLibrary.rookTierStoreItems),
          MapEntry(loc('tier_queen'), PieceLibrary.queenTierStoreItems),
          MapEntry(loc('tier_king'), PieceLibrary.kingTierStoreItems),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc('store_title'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(loc('store_subtitle'),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                  Chip(
                    avatar: const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                    label: Text('${collection.gold}'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sections.length,
                itemBuilder: (context, sectionIndex) {
                  final section = sections[sectionIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                        child: Text(
                          section.key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey[400],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...section.value.map((piece) => _StoreCardTile(piece: piece, collection: collection)),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StoreCardTile extends StatelessWidget {
  final Piece piece;
  final CollectionService collection;
  const _StoreCardTile({required this.piece, required this.collection});

  @override
  Widget build(BuildContext context) {
    final owned = collection.isOwned(piece);
    final price = priceForRarity(piece.rarity);
    final color = rarityColor(piece.rarity);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.25),
              child: Text(piece.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(piece.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      owned
                          ? Chip(
                              label: Text(loc('owned'), style: const TextStyle(fontSize: 11)),
                              backgroundColor: Colors.green.withOpacity(0.2),
                              visualDensity: VisualDensity.compact,
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                final success = collection.buy(piece);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? '${piece.name} ${loc('purchased')}'
                                        : loc('not_enough_gold')),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.monetization_on, size: 16),
                              label: Text('$price'),
                            ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rarityLabel(piece.rarity)} · ${piece.moveDescription}',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                  if (piece.hasSpecialAbility) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: Colors.amberAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            piece.abilityDescription,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                      Text(' ${piece.maxHp}   ', style: const TextStyle(fontSize: 11)),
                      const Icon(Icons.bolt, size: 12, color: Colors.orangeAccent),
                      Text(' ${piece.attackPower}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

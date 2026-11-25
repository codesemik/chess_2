import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/piece_library.dart';
import '../models/collection_service.dart';
import '../models/formation_service.dart';
import '../models/card_level_service.dart';
import '../utils/rarity_utils.dart';
import 'card_test_screen.dart';

/// "Kartlarım" sekmesi: sahip olunan kartların gösterildiği Koleksiyon
/// alt-sekmesi ve maça girecek dizilimin düzenlendiği Diziliş alt-sekmesinden
/// oluşur. Diziliş burada, sadece burada değiştirilebilir.
class CardsScreen extends StatelessWidget {
  const CardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc('cards_title'),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(loc('cards_subtitle'),
                              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CardTestScreen()),
                      ),
                      icon: const Icon(Icons.science_outlined, size: 16),
                      label: Text(loc('test_lab_entry'), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: loc('tab_collection')),
                  Tab(text: loc('tab_formation')),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _CollectionView(),
                    _FormationView(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// KOLEKSİYON
// ---------------------------------------------------------------------

class _CollectionView extends StatelessWidget {
  const _CollectionView();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService.instance,
        CollectionService.instance,
        CardLevelService.instance,
      ]),
      builder: (context, _) {
        final owned = CollectionService.instance.ownedPieces;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: owned.length,
          itemBuilder: (context, index) {
            final template = owned[index];
            final color = rarityColor(template.rarity);
            final level = CardLevelService.instance.levelOf(template.id);
            final preview = CardLevelService.instance.previewAtCurrentLevel(template);

            return GestureDetector(
              onTap: () => _showCardDetailSheet(context, template),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(0.25), Colors.black26],
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(template.emoji, style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 6),
                          Text(
                            template.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rarityLabel(template.rarity),
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            template.moveDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10),
                          ),
                          if (template.hasSpecialAbility) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 10, color: Colors.amberAccent),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      template.abilityDescription,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                              Text(' ${preview.maxHp}   ', style: const TextStyle(fontSize: 11)),
                              const Icon(Icons.bolt, size: 12, color: Colors.orangeAccent),
                              Text(' ${preview.attackPower}', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          'Lv.$level',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Bir kartın tam detayını ve seviye yükseltme akışını gösteren alt menü.
void _showCardDetailSheet(BuildContext context, Piece template) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final service = CardLevelService.instance;
          final color = rarityColor(template.rarity);
          final level = service.levelOf(template.id);
          final current = service.previewAtCurrentLevel(template);
          final isMax = service.isMaxLevel(template);
          final cost = service.costForNextLevel(template);
          final next = isMax ? null : service.previewAtNextLevel(template);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: color.withOpacity(0.25),
                        child: Text(template.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(template.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('${rarityLabel(template.rarity)} · ${loc('level')} $level',
                                style: TextStyle(fontSize: 12, color: color)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(current.moveDescription, style: const TextStyle(fontSize: 13)),
                  if (template.hasSpecialAbility) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(current.abilityDescription,
                              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          title: '${loc('level')} $level',
                          hp: current.maxHp,
                          attack: current.attackPower,
                          highlight: false,
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 18, color: Colors.grey),
                      Expanded(
                        child: _StatColumn(
                          title: isMax
                              ? loc('card_max_level')
                              : '${loc('level')} ${level + 1}',
                          hp: next?.maxHp,
                          attack: next?.attackPower,
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isMax)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.amberAccent.withOpacity(0.15),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: Text(loc('card_max_level'),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final success = service.levelUp(template);
                          if (success) {
                            setSheetState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${template.name} ${loc('card_level_up_success')}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc('not_enough_gold'))),
                            );
                          }
                        },
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: Text('${loc('card_level_up')} (${loc('gold')}: $cost)'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _StatColumn extends StatelessWidget {
  final String title;
  final int? hp;
  final int? attack;
  final bool highlight;
  const _StatColumn({required this.title, this.hp, this.attack, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.amberAccent : Colors.grey[300];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
            Text(' ${hp ?? '-'}   ', style: const TextStyle(fontSize: 12)),
            const Icon(Icons.bolt, size: 12, color: Colors.orangeAccent),
            Text(' ${attack ?? '-'}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// DİZİLİŞ
// ---------------------------------------------------------------------

class _FormationView extends StatelessWidget {
  const _FormationView();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService.instance,
        FormationService.instance,
        CollectionService.instance,
      ]),
      builder: (context, _) {
        final formation = FormationService.instance;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(loc('formation_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(loc('formation_subtitle'), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 20),

            // DPS
            Row(
              children: [
                Expanded(
                  child: _SlotPicker(
                    label: loc('formation_dps_left'),
                    role: CardRole.dps,
                    selected: formation.dpsLeft,
                    onSelected: formation.setDpsLeft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SlotPicker(
                    label: loc('formation_dps_right'),
                    role: CardRole.dps,
                    selected: formation.dpsRight,
                    onSelected: formation.setDpsRight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vezir & Şah
            Row(
              children: [
                Expanded(
                  child: _SlotPicker(
                    label: loc('formation_queen'),
                    role: CardRole.queen,
                    selected: formation.queen,
                    onSelected: formation.setQueen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SlotPicker(
                    label: loc('formation_king'),
                    role: CardRole.king,
                    selected: formation.king,
                    onSelected: formation.setKing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(loc('formation_pawns'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(4, (index) {
                final slotLabels = ['slot_a', 'slot_b', 'slot_c', 'slot_d'];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    child: _SlotPicker(
                      label: loc(slotLabels[index]),
                      role: CardRole.pawn,
                      selected: PieceLibrary.byId(formation.pawnSlotIds[index]),
                      onSelected: (id) => formation.setPawnSlot(index, id),
                      compact: true,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              loc('formation_locked_hint'),
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        );
      },
    );
  }
}

/// Tek bir formasyon slotunu (ör. "Sol DPS") temsil eder. Üzerine
/// dokunulduğunda o role uygun ve sahip olunan kartların listelendiği
/// bir alt menü (bottom sheet) açılır.
class _SlotPicker extends StatelessWidget {
  final String label;
  final CardRole role;
  final Piece selected;
  final ValueChanged<String> onSelected;
  final bool compact;

  const _SlotPicker({
    required this.label,
    required this.role,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  void _openPicker(BuildContext context) {
    final options = CollectionService.instance.ownedByRole(role);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((piece) {
                    final isSelected = piece.id == selected.id;
                    final color = rarityColor(piece.rarity);
                    return GestureDetector(
                      onTap: () {
                        onSelected(piece.id);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 84,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? Colors.greenAccent : color, width: 2),
                          color: isSelected ? Colors.greenAccent.withOpacity(0.15) : color.withOpacity(0.1),
                        ),
                        child: Column(
                          children: [
                            Text(piece.emoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(
                              piece.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            if (piece.hasSpecialAbility) ...[
                              const SizedBox(height: 2),
                              const Icon(Icons.auto_awesome, size: 12, color: Colors.amberAccent),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(selected.rarity);
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          color: color.withOpacity(0.08),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: compact ? 10 : 11, color: Colors.grey[400])),
            const SizedBox(height: 4),
            Text(selected.emoji, style: TextStyle(fontSize: compact ? 22 : 28)),
            const SizedBox(height: 2),
            Text(
              selected.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: compact ? 10 : 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Icon(Icons.edit, size: compact ? 12 : 14, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}

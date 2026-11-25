import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/clan_service.dart';
import '../models/collection_service.dart';
import 'clan_war_screen.dart';

/// "Klan" sekmesi. Henüz bir klanı yoksa gözat/kur ekranını, varsa tam
/// klan panelini (üyeler, görevler, Klan Savaşı) gösterir.
class ClanScreen extends StatelessWidget {
  const ClanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ClanService.instance,
        LocalizationService.instance,
        CollectionService.instance,
      ]),
      builder: (context, _) {
        final clan = ClanService.instance.currentClan;
        return clan == null ? const _ClanBrowseView() : const _ClanDashboard();
      },
    );
  }
}

// ---------------------------------------------------------------------
// GÖZAT / KUR
// ---------------------------------------------------------------------

class _ClanBrowseView extends StatelessWidget {
  const _ClanBrowseView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc('clan_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(loc('clan_subtitle'), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              const Icon(Icons.shield_moon, size: 56, color: Colors.deepPurpleAccent),
              const SizedBox(height: 8),
              Text(loc('clan_no_clan'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showCreateClanDialog(context),
                icon: const Icon(Icons.add),
                label: Text(loc('clan_create')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(loc('clan_browse_title'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...ClanService.instance.availableClans.map((clan) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withOpacity(0.25),
                  child: Text(clan.icon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text('${clan.name} [${clan.tag}]',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${loc('clan_level')} ${clan.level} · ${clan.members.length} ${loc('clan_members_count')}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: ElevatedButton(
                  onPressed: () => ClanService.instance.joinClan(clan),
                  child: Text(loc('clan_join_button')),
                ),
              ),
            )),
      ],
    );
  }
}

void _showCreateClanDialog(BuildContext context) {
  final nameController = TextEditingController();
  final tagController = TextEditingController();
  String selectedIcon = ClanService.clanIconChoices.first;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(loc('clan_create_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  maxLength: 24,
                  decoration: InputDecoration(labelText: loc('clan_name_label')),
                ),
                TextField(
                  controller: tagController,
                  maxLength: 4,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: loc('clan_tag_label')),
                ),
                const SizedBox(height: 8),
                Text(loc('clan_pick_icon'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ClanService.clanIconChoices.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.deepPurpleAccent.withOpacity(0.4)
                              : Colors.white10,
                          border: isSelected
                              ? Border.all(color: Colors.deepPurpleAccent, width: 2)
                              : null,
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc('close')),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final tag = tagController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc('clan_name_required'))),
                  );
                  return;
                }
                if (tag.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc('clan_tag_required'))),
                  );
                  return;
                }
                ClanService.instance.createClan(name, tag, selectedIcon);
                Navigator.of(context).pop();
              },
              child: Text(loc('clan_create_button')),
            ),
          ],
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------
// PANEL (klan içindeyken)
// ---------------------------------------------------------------------

class _ClanDashboard extends StatelessWidget {
  const _ClanDashboard();

  @override
  Widget build(BuildContext context) {
    final clan = ClanService.instance.currentClan!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Klan başlık kartı ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.deepPurple.withOpacity(0.25),
                      child: Text(clan.icon, style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${clan.name} [${clan.tag}]',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            '${loc('clan_level')} ${clan.level} · ${clan.members.length} ${loc('clan_members_count')}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: clan.levelProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${clan.xp} / ${clan.xpToNextLevel} XP',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    Row(
                      children: [
                        const Icon(Icons.account_balance, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${loc('clan_treasury')}: ${clan.treasury}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDonateDialog(context),
                        icon: const Icon(Icons.volunteer_activism, size: 16),
                        label: Text(loc('clan_donate')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmLeave(context),
                        icon: const Icon(Icons.exit_to_app, size: 16),
                        label: Text(loc('clan_leave')),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        _WarSection(),

        const SizedBox(height: 16),
        _QuestsSection(),

        const SizedBox(height: 16),
        Text(loc('clan_members_title'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ...clan.members.map((m) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: m.isPlayer ? Colors.deepPurpleAccent.withOpacity(0.12) : null,
              child: ListTile(
                dense: true,
                leading: Text(m.avatar, style: const TextStyle(fontSize: 20)),
                title: Text('${m.name}${m.isPlayer ? ' ${loc('clan_you')}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(loc(m.roleKey), style: const TextStyle(fontSize: 11)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${m.trophies}'),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 24),
      ],
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc('clan_leave_confirm_title')),
        content: Text(loc('clan_leave_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc('close')),
          ),
          TextButton(
            onPressed: () {
              ClanService.instance.leaveClan();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(loc('clan_leave_confirm_yes')),
          ),
        ],
      ),
    );
  }

  void _showDonateDialog(BuildContext context) {
    final amountController = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc('clan_donate_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc('clan_donate_hint'), style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text('${loc('gold')}: ${CollectionService.instance.gold}',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [50, 100, 250, 500].map((v) {
                return OutlinedButton(
                  onPressed: () => amountController.text = '$v',
                  child: Text('$v'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc('close')),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(amountController.text.trim()) ?? 0;
              final success = ClanService.instance.donate(amount);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? loc('clan_donate_confirm') : loc('not_enough_gold')),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Text(loc('clan_donate_confirm')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// KLAN SAVAŞI BÖLÜMÜ
// ---------------------------------------------------------------------

class _WarSection extends StatelessWidget {
  const _WarSection();

  @override
  Widget build(BuildContext context) {
    final service = ClanService.instance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.deepOrangeAccent),
                const SizedBox(width: 8),
                Text(loc('clan_war_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(ClanService.rivalClanIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('${loc('clan_war_rival')}: ${ClanService.rivalClanName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ScoreBadge(label: loc('clan_title'), value: service.warScoreUs, color: Colors.greenAccent),
                Text(loc('clan_war_score'),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                _ScoreBadge(
                    label: ClanService.rivalClanName, value: service.warScoreRival, color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${loc('clan_war_played')}: ${service.warBattlesPlayed}   ${loc('clan_war_won')}: ${service.warBattlesWon}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClanWarScreen()),
                ),
                icon: const Icon(Icons.sports_kabaddi, size: 18),
                label: Text(loc('clan_war_join')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ScoreBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        SizedBox(
          width: 90,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// GÖREVLER BÖLÜMÜ
// ---------------------------------------------------------------------

class _QuestsSection extends StatelessWidget {
  const _QuestsSection();

  @override
  Widget build(BuildContext context) {
    final quests = ClanService.instance.quests;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checklist, color: Colors.lightGreenAccent),
                    const SizedBox(width: 8),
                    Text(loc('clan_quests_title'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: loc('clan_quests_refresh'),
                  onPressed: () => ClanService.instance.refreshQuests(),
                ),
              ],
            ),
            ...quests.map((q) {
              final progressRatio = (q.progress / q.target).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(loc(q.descriptionKey), style: const TextStyle(fontSize: 12)),
                        ),
                        if (q.claimed)
                          Chip(
                            label: Text(loc('clan_quest_claimed'), style: const TextStyle(fontSize: 10)),
                            backgroundColor: Colors.green.withOpacity(0.2),
                            visualDensity: VisualDensity.compact,
                          )
                        else if (q.isComplete)
                          ElevatedButton(
                            onPressed: () {
                              ClanService.instance.claimQuestReward(q.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(loc('quest_reward_claimed')),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(0, 32),
                            ),
                            child: Text(
                              '${loc('clan_quest_claim')} (+${q.rewardGold})',
                              style: const TextStyle(fontSize: 11),
                            ),
                          )
                        else
                          Text('${q.progress}/${q.target}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        color: q.claimed
                            ? Colors.green
                            : (q.isComplete ? Colors.amberAccent : Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

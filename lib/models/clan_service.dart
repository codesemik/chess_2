import 'dart:math';
import 'package:flutter/foundation.dart';
import 'collection_service.dart';
import 'profile_service.dart';

/// Bir klan üyesinin rolü.
enum ClanRole { leader, officer, member }

class ClanMember {
  final String name;
  final String avatar;
  final ClanRole role;
  final int trophies;
  final bool isPlayer;

  const ClanMember({
    required this.name,
    required this.avatar,
    required this.role,
    required this.trophies,
    this.isPlayer = false,
  });

  String get roleKey {
    switch (role) {
      case ClanRole.leader:
        return 'clan_role_leader';
      case ClanRole.officer:
        return 'clan_role_officer';
      case ClanRole.member:
        return 'clan_role_member';
    }
  }
}

class Clan {
  final String id;
  final String name;
  final String tag;
  final String icon;
  int level;
  int xp;
  int treasury;
  final List<ClanMember> members;

  Clan({
    required this.id,
    required this.name,
    required this.tag,
    required this.icon,
    required this.members,
    this.level = 1,
    this.xp = 0,
    this.treasury = 0,
  });

  int get xpToNextLevel => level * 500;
  double get levelProgress => (xp / xpToNextLevel).clamp(0.0, 1.0);
}

enum ClanQuestType { donate, playWar, winWar }

class ClanQuest {
  final String id;
  final ClanQuestType type;
  final String descriptionKey;
  final int target;
  final int rewardGold;
  int progress;
  bool claimed;

  ClanQuest({
    required this.id,
    required this.type,
    required this.descriptionKey,
    required this.target,
    required this.rewardGold,
    this.progress = 0,
    this.claimed = false,
  });

  bool get isComplete => progress >= target;
}

/// Klan sistemini yöneten servis. Gerçek bir sunucu olmadığı için diğer
/// klan üyeleri ve rakip klan simüle edilmiştir; ama bağış, seviye atlama,
/// görevler ve Klan Savaşı tamamen fonksiyoneldir.
class ClanService extends ChangeNotifier {
  ClanService._internal();
  static final ClanService instance = ClanService._internal();

  Clan? currentClan;

  /// Klan Savaşı'ndaki sabit (flavor) rakip. Gerçek bir klan değildir.
  static const String rivalClanName = 'Gölgeavcıları';
  static const String rivalClanIcon = '🗡️';

  int warScoreUs = 0;
  int warScoreRival = 0;
  int warBattlesPlayed = 0;
  int warBattlesWon = 0;

  List<ClanQuest> quests = [];

  static const List<String> _namePool = [
    'Aslan', 'Kartal', 'Tuna', 'Ece', 'Baran', 'Elif', 'Deniz', 'Kaan',
    'Zeynep', 'Mert', 'Yiğit', 'Selin', 'Ege', 'Naz', 'Umut', 'Ada', 'Kerem', 'Ceylin',
  ];
  static const List<String> _avatarPool = [
    '🦁', '🐯', '🐺', '🦊', '🐲', '🥷', '🧙', '👑', '💀', '🤖', '🦅', '🐉',
  ];
  static const List<String> clanIconChoices = [
    '🌑', '🛡️', '🌙', '🔥', '❄️', '⚔️', '🐺', '👑', '💀', '🦅', '🐲', '🌟',
  ];

  static List<ClanMember> _generateFakeMembers(int count, {ClanRole topRole = ClanRole.leader}) {
    final rng = Random();
    final names = List<String>.from(_namePool)..shuffle(rng);
    final avatars = List<String>.from(_avatarPool)..shuffle(rng);
    final result = <ClanMember>[];
    for (int i = 0; i < count; i++) {
      result.add(ClanMember(
        name: names[i % names.length],
        avatar: avatars[i % avatars.length],
        role: i == 0 ? topRole : ClanRole.member,
        trophies: 40 + rng.nextInt(600),
      ));
    }
    return result;
  }

  /// Katılmak için göz atılabilecek, simüle edilmiş klanlar.
  final List<Clan> availableClans = [
    Clan(id: 'c1', name: 'Gölge Kardeşliği', tag: 'GLGE', icon: '🌑', level: 6, xp: 120,
        treasury: 5400, members: _generateFakeMembers(9)),
    Clan(id: 'c2', name: 'Demir Yumruklar', tag: 'DMR', icon: '🛡️', level: 4, xp: 80,
        treasury: 2100, members: _generateFakeMembers(6)),
    Clan(id: 'c3', name: 'Ay Işığı Klanı', tag: 'AYIK', icon: '🌙', level: 3, xp: 40,
        treasury: 900, members: _generateFakeMembers(5)),
    Clan(id: 'c4', name: 'Kızıl Ejderler', tag: 'KZLE', icon: '🔥', level: 8, xp: 300,
        treasury: 9200, members: _generateFakeMembers(12)),
    Clan(id: 'c5', name: 'Buz Krallığı', tag: 'BUZK', icon: '❄️', level: 2, xp: 10,
        treasury: 300, members: _generateFakeMembers(3)),
  ];

  void _resetQuests() {
    quests = [
      ClanQuest(
        id: 'q_donate',
        type: ClanQuestType.donate,
        descriptionKey: 'quest_donate_desc',
        target: 200,
        rewardGold: 150,
      ),
      ClanQuest(
        id: 'q_play_war',
        type: ClanQuestType.playWar,
        descriptionKey: 'quest_playwar_desc',
        target: 1,
        rewardGold: 100,
      ),
      ClanQuest(
        id: 'q_win_war',
        type: ClanQuestType.winWar,
        descriptionKey: 'quest_winwar_desc',
        target: 1,
        rewardGold: 250,
      ),
    ];
  }

  void refreshQuests() {
    _resetQuests();
    notifyListeners();
  }

  void createClan(String name, String tag, String icon) {
    final player = ClanMember(
      name: ProfileService.instance.name,
      avatar: ProfileService.instance.avatar,
      role: ClanRole.leader,
      trophies: ProfileService.instance.trophies,
      isPlayer: true,
    );
    currentClan = Clan(
      id: 'player_clan_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      tag: tag.toUpperCase(),
      icon: icon,
      level: 1,
      xp: 0,
      treasury: 0,
      members: [player, ..._generateFakeMembers(3, topRole: ClanRole.member)],
    );
    warScoreUs = 0;
    warScoreRival = 0;
    warBattlesPlayed = 0;
    warBattlesWon = 0;
    _resetQuests();
    notifyListeners();
  }

  void joinClan(Clan template) {
    final player = ClanMember(
      name: ProfileService.instance.name,
      avatar: ProfileService.instance.avatar,
      role: ClanRole.member,
      trophies: ProfileService.instance.trophies,
      isPlayer: true,
    );
    currentClan = Clan(
      id: template.id,
      name: template.name,
      tag: template.tag,
      icon: template.icon,
      level: template.level,
      xp: template.xp,
      treasury: template.treasury,
      members: [...template.members, player],
    );
    warScoreUs = 0;
    warScoreRival = 0;
    warBattlesPlayed = 0;
    warBattlesWon = 0;
    _resetQuests();
    notifyListeners();
  }

  void leaveClan() {
    currentClan = null;
    quests = [];
    notifyListeners();
  }

  bool donate(int amount) {
    final clan = currentClan;
    if (clan == null || amount <= 0) return false;
    if (!CollectionService.instance.spendGold(amount)) return false;

    clan.treasury += amount;
    clan.xp += amount;
    while (clan.xp >= clan.xpToNextLevel) {
      clan.xp -= clan.xpToNextLevel;
      clan.level++;
    }

    for (final q in quests) {
      if (q.type == ClanQuestType.donate && !q.claimed) {
        q.progress = (q.progress + amount).clamp(0, q.target);
      }
    }
    notifyListeners();
    return true;
  }

  /// Bir Klan Savaşı maçı bittiğinde çağrılır.
  void recordWarBattleResult(bool won) {
    warBattlesPlayed++;
    if (won) {
      warBattlesWon++;
      warScoreUs++;
    } else {
      warScoreRival++;
    }
    for (final q in quests) {
      if (q.claimed) continue;
      if (q.type == ClanQuestType.playWar) {
        q.progress = (q.progress + 1).clamp(0, q.target);
      } else if (q.type == ClanQuestType.winWar && won) {
        q.progress = (q.progress + 1).clamp(0, q.target);
      }
    }
    notifyListeners();
  }

  bool claimQuestReward(String questId) {
    ClanQuest? quest;
    for (final q in quests) {
      if (q.id == questId) {
        quest = q;
        break;
      }
    }
    if (quest == null || !quest.isComplete || quest.claimed) return false;
    quest.claimed = true;
    CollectionService.instance.addGold(quest.rewardGold);
    notifyListeners();
    return true;
  }
}

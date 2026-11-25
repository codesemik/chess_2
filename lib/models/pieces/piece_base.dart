import '../../l10n/localization_service.dart';

/// Bu dosya sadece TEMEL YAPI TAŞLARINI içerir: enum'lar ve [Piece] sınıfı.
/// Gerçek taş tanımları (Piyon, Vezir, Goblin, Ejderha Kraliçe, vb.) bu
/// klasördeki KENDİ ayrı dosyalarında yaşar (ör. `pawn.dart`, `goblin.dart`).
/// Hepsini tek yerden görmek için `../piece_library.dart` dosyasına bakabilirsin.

enum Team { white, black }

enum PieceType { pawn, king, queen, custom }

/// Bir taşın satrançtaki gerçek hareket mantığını belirler.
/// Board controller, hangi karelere gidilebileceğini bu değere göre hesaplar.
enum MoveStyle {
  kingStyle,   // Her yöne 1 kare (Şah)
  queenStyle,  // Düz + çapraz, sınırsız (Vezir)
  pawnStyle,   // İleri hareket, çapraz vuruş (Piyon)
  rookStyle,   // Düz, sınırsız (Kale mantığı)
  bishopStyle, // Çapraz, sınırsız (Fil mantığı)
  knightStyle, // L şeklinde sıçrama (At mantığı)
}

enum Rarity { common, rare, epic, legendary, mythic }

/// Bir kartın "Diziliş" (formasyon) ekranında hangi slot(lar)a
/// yerleştirilebileceğini belirler. Bazı kartlar (ör. Goblin) birden
/// fazla role sahip olabilir; hem piyon sırasında hem DPS slotunda kullanılabilir.
enum CardRole { pawn, dps, queen, king }

/// Kartların taşıdığı özel yetenekler. Her yeteneğin somut mantığı
/// [BoardController] içinde uygulanır; bu enum sadece "hangi kart hangi
/// yeteneğe sahip" eşlemesini tutar.
enum SpecialAbility {
  none,
  cavalryRush,        // Sipahi: ilk hamlede 3 kare düz sıçrama
  stoneSkin,           // Maden Muhafızı: ilk ölümcül vuruşu absorbe eder
  blindSpotStrike,     // Gölge Piyonu: önündeki taşın üzerinden 2 kare çapraz vuruş
  windGlideShield,     // Pegasus: iniş karesi çevresindeki dost piyonlara kalkan
  fearAura,            // Kabus: iniş karesi çevresindeki rakipleri 1 tur kilitler
  mirrorReflection,    // Büyücü: oyunda 1 kez dik/yatay 1 kare kayma
  spiritPath,          // Şaman: ölü dost piyon varsa çapraz yön kırma
  catapultStrike,      // Mancınık Kulesi: hareket etmeden 3 kare uzağa vuruş
  barricade,           // Barikat Kalesi: bitişiğini rakip atlardan korur
  flameLine,           // Ejderha Kraliçe: vuruş sonrası arkasındaki kareyi ateşe verir
  rewind,              // Zaman Lordu: oyunda 1 kez son hamleyi geri alır
  lastStand,           // Savaşçı Kral: şah çekildiğinde bitişik tehdidi yiyebilir
  soulSummon,          // Ölüçağıran Şah: piyon kalmadıysa iskelet piyon çağırır
}

class Piece {
  final String id;
  final String nameKey; // Localization anahtarı (ör: 'piece_goblin')
  final PieceType type;
  final Team team;
  final MoveStyle moveStyle;
  final String emoji;
  final Rarity rarity;
  final List<CardRole> roles;
  final SpecialAbility ability;
  int hp;
  int maxHp;
  int attackPower;

  // --- Maç-içi geçici durum (her yeni maçta copyWith ile sıfırlanır) ---
  int level = 1;              // Kartın seviyesi (1-3). Can/vuruş/yetenek gücünü belirler.
  int usesRemaining = 1;      // "Oyunda N kez" yetenekler için kalan kullanım hakkı
  int stoneSkinCharges = 1;   // Taş Deri'nin kaç ölümcül vuruşu absorbe edebileceği
  int shieldTurns = 0;        // >0 ise bir sonraki hasar yok sayılır
  int frozenTurns = 0;        // >0 ise bu taş hareket edemez

  Piece({
    required this.id,
    required this.nameKey,
    required this.type,
    required this.team,
    required this.moveStyle,
    required this.emoji,
    required this.hp,
    required this.maxHp,
    required this.attackPower,
    this.rarity = Rarity.common,
    this.roles = const [],
    this.ability = SpecialAbility.none,
  });

  /// Ekranda gösterilecek, aktif dile göre çevrilmiş isim.
  String get name => loc(nameKey);

  /// KRİTİK: Bir taşın "Şah" sayılıp sayılmadığı HER ZAMAN role göre kontrol
  /// edilmeli, [type] alanına göre değil — çünkü Zırhlı Şah, Savaşçı Kral gibi
  /// varyasyonların [type]'ı tarihsel nedenlerle [PieceType.custom] olabilir.
  /// Şah çekme, mat kontrolü ve oyun sonu mantığı SADECE bunu kullanmalı.
  bool get isKingPiece => roles.contains(CardRole.king);

  /// Aynı mantık Piyon türevleri (Sipahi, Maden Muhafızı, Goblin vb.) için:
  /// terfi (promotion) ve "piyon kalmadı mı" kontrolleri SADECE bunu kullanmalı.
  bool get isPawnPiece => roles.contains(CardRole.pawn);

  String get moveDescription {
    switch (moveStyle) {
      case MoveStyle.kingStyle:
        return loc('move_king_style');
      case MoveStyle.queenStyle:
        return loc('move_queen_style');
      case MoveStyle.pawnStyle:
        return loc('move_pawn_style');
      case MoveStyle.rookStyle:
        return loc('move_rook_style');
      case MoveStyle.bishopStyle:
        return loc('move_bishop_style');
      case MoveStyle.knightStyle:
        return loc('move_knight_style');
    }
  }

  bool get hasSpecialAbility => ability != SpecialAbility.none;

  /// [specialUsed] artık [usesRemaining] üzerinden HESAPLANIR: seviyeli bir
  /// kart, "oyunda 1 kez" yeteneğini seviyesi kadar kez kullanabilir.
  bool get specialUsed => usesRemaining <= 0;

  /// [stoneSkinUsed] de aynı şekilde [stoneSkinCharges] üzerinden hesaplanır.
  bool get stoneSkinUsed => stoneSkinCharges <= 0;

  /// Tek kullanımlık bir yeteneği (Ayna Yansıması, Geri Sarma, Ruh Çağırma)
  /// tüketir. Board controller, eski `piece.specialUsed = true` yerine
  /// bunu çağırır.
  void consumeUse() {
    if (usesRemaining > 0) usesRemaining--;
  }

  /// Taş Deri'nin bir ölümcül vuruşunu tüketir.
  void consumeStoneSkinCharge() {
    if (stoneSkinCharges > 0) stoneSkinCharges--;
  }

  String get abilityDescription {
    final base = _baseAbilityDescription;
    if (base.isEmpty || level <= 1) return base;
    return '$base  •  ${loc('level')} $level';
  }

  String get _baseAbilityDescription {
    switch (ability) {
      case SpecialAbility.none:
        return '';
      case SpecialAbility.cavalryRush:
        return loc('ability_cavalry_rush');
      case SpecialAbility.stoneSkin:
        return loc('ability_stone_skin');
      case SpecialAbility.blindSpotStrike:
        return loc('ability_blind_spot');
      case SpecialAbility.windGlideShield:
        return loc('ability_wind_glide');
      case SpecialAbility.fearAura:
        return loc('ability_fear_aura');
      case SpecialAbility.mirrorReflection:
        return loc('ability_mirror_reflection');
      case SpecialAbility.spiritPath:
        return loc('ability_spirit_path');
      case SpecialAbility.catapultStrike:
        return loc('ability_catapult_strike');
      case SpecialAbility.barricade:
        return loc('ability_barricade');
      case SpecialAbility.flameLine:
        return loc('ability_flame_line');
      case SpecialAbility.rewind:
        return loc('ability_rewind');
      case SpecialAbility.lastStand:
        return loc('ability_last_stand');
      case SpecialAbility.soulSummon:
        return loc('ability_soul_summon');
    }
  }

  // Klonlama yardımı (Maç başında taşları tahtaya kopyalayarak dizmek için).
  // Maç-içi geçici durumlar (kalkan, kilit) her zaman sıfırdan başlar;
  // böylece kütüphanedeki şablon asla kirlenmez. [level] verilirse can,
  // vuruş gücü ve yetenek kullanım hakları buna göre yükseltilir.
  Piece copyWith({Team? newTeam, String? newId, int level = 1}) {
    final bonus = level - 1; // Seviye 1 = bonus yok, Seviye 2 = +1, Seviye 3 = +2
    final p = Piece(
      id: newId ?? id,
      nameKey: nameKey,
      type: type,
      team: newTeam ?? team,
      moveStyle: moveStyle,
      emoji: emoji,
      hp: maxHp + bonus,
      maxHp: maxHp + bonus,
      attackPower: attackPower + bonus,
      rarity: rarity,
      roles: roles,
      ability: ability,
    );
    p.level = level;
    p.usesRemaining = level;
    p.stoneSkinCharges = level;
    return p;
  }

  /// Zaman Lordu'nun "Geri Sarma" yeteneği için: taşın MEVCUT (maç-içi)
  /// durumunu (can, kalkan, kilit, seviye, kullanım hakları dahil) birebir
  /// kopyalar. [copyWith]'ten farkı budur; oradaki geçici durumu sıfırlar,
  /// bu ise korur.
  Piece clone() {
    final p = Piece(
      id: id,
      nameKey: nameKey,
      type: type,
      team: team,
      moveStyle: moveStyle,
      emoji: emoji,
      hp: hp,
      maxHp: maxHp,
      attackPower: attackPower,
      rarity: rarity,
      roles: roles,
      ability: ability,
    );
    p.level = level;
    p.usesRemaining = usesRemaining;
    p.stoneSkinCharges = stoneSkinCharges;
    p.shieldTurns = shieldTurns;
    p.frozenTurns = frozenTurns;
    return p;
  }

  /// [copyWith]'ten farkı: bu, can/seviye/yetenek durumunu SIFIRDAN
  /// hesaplamaz, taşı OLDUĞU GİBİ (zaten hesaplanmış durumuyla) kopyalar;
  /// sadece takım/id değiştirir. Çevrimiçi bir maçın başlangıç durumunu,
  /// her iki oyuncunun da kendi (buluttan okunan) seviyeleriyle doğru
  /// şekilde kurmak için kullanılır — bkz. `match_state_builder.dart`.
  Piece copyForPlacement({Team? newTeam, String? newId}) {
    final p = Piece(
      id: newId ?? id,
      nameKey: nameKey,
      type: type,
      team: newTeam ?? team,
      moveStyle: moveStyle,
      emoji: emoji,
      hp: hp,
      maxHp: maxHp,
      attackPower: attackPower,
      rarity: rarity,
      roles: roles,
      ability: ability,
    );
    p.level = level;
    p.usesRemaining = usesRemaining;
    p.stoneSkinCharges = stoneSkinCharges;
    return p;
  }

  // ---------------------------------------------------------------------
  // ÇEVRİMİÇİ MAÇ SENKRONİZASYONU (Firestore)
  // ---------------------------------------------------------------------

  /// Bu taşın TAM mevcut durumunu (can, seviye, kalkan, kilit, kullanım
  /// hakları dahil) Firestore'a yazılabilir düz bir haritaya çevirir.
  /// Kendi kendine yeterlidir — kütüphaneye (PieceLibrary) hiç ihtiyaç
  /// duymadan [Piece.fromJson] ile birebir geri kurulabilir.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nameKey': nameKey,
        'type': type.name,
        'team': team.name,
        'moveStyle': moveStyle.name,
        'emoji': emoji,
        'rarity': rarity.name,
        'roles': roles.map((r) => r.name).toList(),
        'ability': ability.name,
        'hp': hp,
        'maxHp': maxHp,
        'attackPower': attackPower,
        'level': level,
        'usesRemaining': usesRemaining,
        'stoneSkinCharges': stoneSkinCharges,
        'shieldTurns': shieldTurns,
        'frozenTurns': frozenTurns,
      };

  factory Piece.fromJson(Map<String, dynamic> json) {
    final p = Piece(
      id: json['id'] as String,
      nameKey: json['nameKey'] as String,
      type: PieceType.values.byName(json['type'] as String),
      team: Team.values.byName(json['team'] as String),
      moveStyle: MoveStyle.values.byName(json['moveStyle'] as String),
      emoji: json['emoji'] as String,
      hp: (json['hp'] as num).toInt(),
      maxHp: (json['maxHp'] as num).toInt(),
      attackPower: (json['attackPower'] as num).toInt(),
      rarity: Rarity.values.byName(json['rarity'] as String? ?? 'common'),
      roles: (json['roles'] as List? ?? [])
          .map((r) => CardRole.values.byName(r as String))
          .toList(),
      ability: SpecialAbility.values.byName(json['ability'] as String? ?? 'none'),
    );
    p.level = (json['level'] as num?)?.toInt() ?? 1;
    p.usesRemaining = (json['usesRemaining'] as num?)?.toInt() ?? p.level;
    p.stoneSkinCharges = (json['stoneSkinCharges'] as num?)?.toInt() ?? p.level;
    p.shieldTurns = (json['shieldTurns'] as num?)?.toInt() ?? 0;
    p.frozenTurns = (json['frozenTurns'] as num?)?.toInt() ?? 0;
    return p;
  }
}

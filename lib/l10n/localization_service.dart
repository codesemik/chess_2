import 'package:flutter/foundation.dart';

/// Uygulamanın desteklediği diller.
/// Yeni bir dil eklemek için buraya bir değer ve
/// aşağıdaki [LocalizationService._strings] içine bir harita eklemek yeterli.
enum AppLanguage { tr, en }

extension AppLanguageMeta on AppLanguage {
  String get flag {
    switch (this) {
      case AppLanguage.tr:
        return '🇹🇷';
      case AppLanguage.en:
        return '🇬🇧';
    }
  }

  String get label {
    switch (this) {
      case AppLanguage.tr:
        return 'Türkçe';
      case AppLanguage.en:
        return 'English';
    }
  }
}

/// Basit, dışarıdan paket gerektirmeyen çeviri servisi.
/// Uygulama genelinde tek bir örnek (singleton) olarak kullanılır ve
/// [ChangeNotifier] olduğu için dil değiştiğinde dinleyen tüm widget'lar
/// otomatik olarak yeniden çizilir.
class LocalizationService extends ChangeNotifier {
  LocalizationService._internal();
  static final LocalizationService instance = LocalizationService._internal();

  AppLanguage _language = AppLanguage.tr;
  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }

  void toggleLanguage() {
    setLanguage(_language == AppLanguage.tr ? AppLanguage.en : AppLanguage.tr);
  }

  /// CloudSyncService bunu, kaydedilmiş dil tercihini buluttan geri
  /// yüklerken kullanır. Dinleyiciler henüz bağlanmadan (açılışta) tek
  /// seferlik bir yükleme olduğu için bilerek `notifyListeners()` çağırmaz.
  void restoreLanguageCode(String code) {
    for (final lang in AppLanguage.values) {
      if (lang.name == code) {
        _language = lang;
        return;
      }
    }
  }

  /// Anahtara karşılık gelen metni döndürür.
  /// Aktif dilde bulunamazsa İngilizce'ye, o da yoksa anahtarın kendisine düşer.
  String t(String key) {
    return _strings[_language]?[key] ?? _strings[AppLanguage.en]?[key] ?? key;
  }

  static final Map<AppLanguage, Map<String, String>> _strings = {
    AppLanguage.tr: {
      // Genel
      'app_title': 'Chess 2',
      'new_game': 'Yeni Oyun',
      'reset': 'Sıfırla',
      'close': 'Kapat',
      'ok': 'Tamam',
      'coming_soon': 'Çok yakında!',

      // Alt navigasyon
      'nav_store': 'Mağaza',
      'nav_play': 'Oyun',
      'nav_cards': 'Kartlarım',
      'nav_clan': 'Klan',

      // Oyun ekranı
      'left_wing': 'Sol Kanat',
      'right_wing': 'Sağ Kanat',
      'start_formation': 'Dizilimi Başlat',
      'turn_white': 'Sıra: Beyaz',
      'turn_black': 'Sıra: Siyah',
      'check': 'ŞAH!',
      'game_over': 'Oyun Bitti',
      'white_wins': 'Beyaz Takım Kazandı!',
      'black_wins': 'Siyah Takım Kazandı!',
      'play_again': 'Tekrar Oyna',
      'hp': 'Can',

      // Taş / kart isimleri
      'piece_king': 'Şah',
      'piece_queen': 'Vezir',
      'piece_pawn': 'Piyon',
      'piece_goblin': 'Goblin',
      'piece_skele_archer': 'Okçu İskelet',
      'piece_golem': 'Kaya Golem',

      // Hareket stilleri (kart açıklamaları için)
      'move_king_style': 'Her yöne 1 kare hareket eder',
      'move_queen_style': 'Düz ve çapraz sınırsız hareket eder',
      'move_pawn_style': 'İleri gider, çapraz vurur',
      'move_knight_style': 'L şeklinde sıçrar (atlar)',
      'move_bishop_style': 'Çapraz sınırsız hareket eder',
      'move_rook_style': 'Düz sınırsız hareket eder',

      // Mağaza
      'store_title': 'Mağaza',
      'store_subtitle': 'Yeni kartlar aç, koleksiyonunu güçlendir',
      'buy': 'Satın Al',
      'owned': 'Sahipsin',
      'gold': 'Altın',
      'not_enough_gold': 'Yeterli altının yok!',
      'purchased': 'satın alındı!',

      // Kartlarım
      'cards_title': 'Kartlarım',
      'cards_subtitle': 'Sahip olduğun tüm kartlar burada',
      'rarity_common': 'Sıradan',
      'rarity_rare': 'Nadir',
      'rarity_epic': 'Destansı',
      'attack': 'Saldırı',

      // Klan
      'clan_title': 'Klan',
      'clan_subtitle': 'Arkadaşlarınla birlikte klan kur, birlikte savaş',
      'clan_no_clan': 'Henüz bir klanın yok',
      'clan_create': 'Klan Kur',
      'clan_join': 'Klana Katıl',
      'clan_members': 'Üyeler',
      'clan_placeholder': 'Bu özellik çok yakında aktif olacak. Klanlar sayesinde arkadaşlarınla '
          'ittifak kurup birlikte turnuvalara katılabileceksin.',

      // Klan — gözat / kur
      'clan_browse_title': 'Bir Klana Katıl',
      'clan_or_create': 'ya da kendi klanını kur',
      'clan_create_title': 'Klan Kur',
      'clan_name_label': 'Klan Adı',
      'clan_tag_label': 'Klan Kodu (3-4 harf)',
      'clan_pick_icon': 'Simge Seç',
      'clan_create_button': 'Klanı Oluştur',
      'clan_join_button': 'Katıl',
      'clan_name_required': 'Klan adı gerekli',
      'clan_tag_required': 'Klan kodu gerekli (en az 2 harf)',

      // Klan — panel
      'clan_level': 'Seviye',
      'clan_members_count': 'Üye',
      'clan_treasury': 'Hazine',
      'clan_donate': 'Bağış Yap',
      'clan_donate_title': 'Klana Bağış Yap',
      'clan_donate_hint': 'Bağışladığın altın klanın seviyesini yükseltir.',
      'clan_donate_confirm': 'Bağışla',
      'clan_leave': 'Klandan Ayrıl',
      'clan_leave_confirm_title': 'Klandan Ayrılmak İstiyor musun?',
      'clan_leave_confirm_body': 'Klandan ayrılırsan, tekrar katılman ya da yeni bir klan kurman gerekecek.',
      'clan_leave_confirm_yes': 'Ayrıl',

      // Klan Savaşı
      'clan_war_title': 'Klan Savaşı',
      'clan_war_score': 'Skor',
      'clan_war_join': 'Savaşa Katıl',
      'clan_war_rival': 'Rakip Klan',
      'clan_war_result_won': 'Klan Savaşını Kazandın!',
      'clan_war_result_lost': 'Klan Savaşını Kaybettin',
      'clan_war_return': 'Klana Dön',
      'clan_war_played': 'Oynanan',
      'clan_war_won': 'Kazanılan',

      // Klan Görevleri
      'clan_quests_title': 'Klan Görevleri',
      'clan_quests_refresh': 'Görevleri Yenile',
      'clan_quest_claim': 'Ödülü Al',
      'clan_quest_claimed': 'Alındı',
      'quest_donate_desc': 'Klana 200 altın bağışla',
      'quest_playwar_desc': 'Bir Klan Savaşı oyna',
      'quest_winwar_desc': 'Bir Klan Savaşı kazan',
      'quest_reward_claimed': 'Ödül alındı!',

      // Klan Üyeleri
      'clan_members_title': 'Üyeler',
      'clan_role_leader': 'Lider',
      'clan_role_officer': 'Yönetici',
      'clan_role_member': 'Üye',
      'clan_you': '(Sen)',

      // Dil seçici
      'language': 'Dil',
      'select_language': 'Dil Seç',

      // Lobi / Savaş
      'battle_button': 'SAVAŞ',
      'searching_opponent': 'Rakip Aranıyor...',
      'searching_waiting_hint': 'Şu an uygun bir rakip bulunamadı, başka biri girene kadar bekleniyor. Bu normaldir.',
      'searching_error': 'Eşleşme aranırken bir sorun oluştu, tekrar dene',
      'cancel_search': 'İptal',
      'return_to_lobby': 'Lobiye Dön',
      'lobby_subtitle': 'Savaşmaya hazır mısın?',
      'trophies': 'Kupa',
      'opponent_label': 'Rakip',
      'your_turn': 'Senin Sıran',
      'opponent_turn': 'Rakibin Sırası',
      'resign_button': 'Pes Et',
      'resign_confirm_title': 'Pes etmek istiyor musun?',
      'resign_confirm_body': 'Pes edersen rakibin otomatik olarak kazanır ve kupa kaybedersin.',
      'match_you_won': 'Kazandın! 🎉',
      'match_you_lost': 'Kaybettin',
      'match_opponent_resigned': 'Rakip pes etti, kazandın! 🎉',
      'match_you_resigned': 'Pes ettin',
      'match_won_by_disconnect': 'Rakibin bağlantısı koptu, kazandın! 🎉',
      'match_lost_by_disconnect': 'Bağlantın koptuğu için kaybettin',
      'leave_match_title': 'Maçtan Çıkmak İstiyor musun?',
      'leave_match_body': 'Maç hâlâ devam ediyor. Çıkarsan pes etmiş sayılırsın ve rakibin kazanır.',
      'opponent_away_hint': 'Rakibin bir süredir bağlı görünmüyor.',
      'claim_victory_button': 'Zaferi İlan Et',
      'resume_match_title': 'Devam eden bir maçın var',
      'resume_match_button': 'Maça Geri Dön',

      // Profil
      'profile_title': 'Profilim',
      'profile_name': 'Oyuncu Adı',
      'profile_change_avatar': 'Avatar Seç',
      'profile_default_name': 'Oyuncu',
      'save': 'Kaydet',
      'saved': 'Kaydedildi!',

      // Ayarlar
      'settings_title': 'Ayarlar',
      'settings_sound': 'Ses Ayarları',
      'settings_music': 'Müzik',
      'settings_sfx': 'Efekt Sesleri',
      'settings_music_volume': 'Müzik Seviyesi',
      'settings_sfx_volume': 'Efekt Seviyesi',
      'settings_language': 'Dil',

      // Kartlarım - sekmeler
      'tab_collection': 'Koleksiyon',
      'tab_formation': 'Diziliş',
      'formation_title': 'Dizilişini Düzenle',
      'formation_subtitle': 'Kartlarını sadece burada değiştirebilirsin',
      'formation_pawns': 'Piyon Sırası',
      'formation_dps_left': 'Sol DPS',
      'formation_dps_right': 'Sağ DPS',
      'formation_queen': 'Vezir',
      'formation_king': 'Şah',
      'formation_choose_card': 'Kart Seç',
      'formation_locked_hint': 'Mağazadan yeni kartlar açarak buraya ekleyebilirsin',
      'slot_a': 'A',
      'slot_b': 'B',
      'slot_c': 'C',
      'slot_d': 'D',

      // Yeni kartlar
      'piece_dark_enchantress': 'Kara Büyücü',
      'piece_armored_king': 'Zırhlı Şah',

      // Temel klasik taşlar
      'piece_knight_basic': 'At',
      'piece_bishop_basic': 'Fil',
      'piece_rook_basic': 'Kale',

      // Yeni nadir dereceleri
      'rarity_legendary': 'Efsanevi',
      'rarity_mythic': 'Miti',

      // Piyon varyasyonları
      'piece_sipahi': 'Sipahi',
      'piece_maden_muhafizi': 'Maden Muhafızı',
      'piece_golge_piyonu': 'Gölge Piyonu',

      // At varyasyonları
      'piece_pegasus': 'Pegasus',
      'piece_kabus': 'Kabus',

      // Fil varyasyonları
      'piece_buyucu': 'Büyücü',
      'piece_saman': 'Şaman',

      // Kale varyasyonları
      'piece_mancinik': 'Mancınık Kulesi',
      'piece_barikat': 'Barikat Kalesi',

      // Vezir varyasyonları
      'piece_ejderha_kralice': 'Ejderha Kraliçe',
      'piece_zaman_lordu': 'Zaman Lordu',

      // Şah varyasyonları
      'piece_savasci_kral': 'Savaşçı Kral',
      'piece_necromancer_sah': 'Ölüçağıran Şah',

      // Yetenek açıklamaları
      'ability_none': '',
      'ability_cavalry_rush': 'Süvari Hücumu: İlk hamlesinde 3 kare ileri atlayabilir',
      'ability_stone_skin': 'Taş Deri: İlk ölümcül vuruşu absorbe eder, 1 can ile hayatta kalır',
      'ability_blind_spot': 'Kör Nokta: Önündeki taşın üzerinden aşıp 2 kare çaprazdaki düşmanı yiyebilir',
      'ability_wind_glide': 'Rüzgar Süzülüşü: İndiği karenin etrafındaki dost piyonlara 1 hamlelik kalkan verir',
      'ability_fear_aura': 'Korku Halesi: İndiği karenin komşularındaki rakip taşları 1 tur kilitler',
      'ability_mirror_reflection': 'Ayna Yansıması: Oyunda bir kez, dik/yatay 1 kare kayarak kare rengini değiştirebilir',
      'ability_spirit_path': 'Ruh Yolu: Ölü dost piyonun varlığında çapraz yönünü 90° kırabilir',
      'ability_catapult_strike': 'Uzak Atış: Hareket etmez; düz hatta 3 kare uzaktaki düşmanı vurur',
      'ability_barricade': 'Ağır Taş: Bitişiğindeki dost taşlar rakip atlardan korunur',
      'ability_flame_line': 'Alev Hattı: Vuruş sonrası geldiği yöndeki kareyi 1 tur ateşe verir',
      'ability_rewind': 'Geri Sarma: Oyunda bir kez, son hamleyi geri alıp ekstra hamle kazanır',
      'ability_last_stand': 'Son Direniş: Şah çekildiğinde, bitişikteki tehdit eden taşı yiyebilir',
      'ability_soul_summon': 'Ruh Çağırma: Piyonun kalmadığı bir maçta, bir defaya mahsus iskelet piyon çağırır',

      // Mağaza kategori başlıkları
      'tier_pawn': 'Piyon Varyasyonları',
      'tier_knight': 'At Varyasyonları',
      'tier_bishop': 'Fil Varyasyonları',
      'tier_rook': 'Kale Varyasyonları',
      'tier_queen': 'Vezir Varyasyonları',
      'tier_king': 'Şah Varyasyonları',

      // Kart Test Odası
      'test_lab_title': 'Kart Test Odası',
      'test_lab_entry': 'Kart Test Odası',
      'test_lab_subtitle': 'Her kartı tek tek, izole bir senaryoda dene',
      'test_reset': 'Senaryoyu Sıfırla',
      'test_lab_hint': 'Bir kareye dokun, sonra hedef kareye dokun. Taşa uzun basarsan bilgi kutusu açılır. Sıra kısıtlaması yoktur — istediğin taşı istediğin an oynatabilirsin.',

      // Seviye Sistemi
      'level': 'Seviye',
      'card_level_up': 'Seviye Yükselt',
      'card_level_up_cost': 'Yükseltme Maliyeti',
      'card_max_level': 'Maksimum Seviye',
      'card_level_up_success': 'seviye atladı!',
      'card_level_bonus_hp': 'Can',
      'card_level_bonus_attack': 'Vuruş',
      'card_level_preview': 'sonraki seviyede',

      // Yetenek arayüzü
      'special_ability': 'Özel Yetenek',
      'rewind_button': 'Geri Sar',
      'ability_used': 'Kullanıldı',
      'piece_info_close': 'Kapat',
    },
    AppLanguage.en: {
      // General
      'app_title': 'Chess 2',
      'new_game': 'New Game',
      'reset': 'Reset',
      'close': 'Close',
      'ok': 'OK',
      'coming_soon': 'Coming soon!',

      // Bottom navigation
      'nav_store': 'Store',
      'nav_play': 'Play',
      'nav_cards': 'My Cards',
      'nav_clan': 'Clan',

      // Game screen
      'left_wing': 'Left Wing',
      'right_wing': 'Right Wing',
      'start_formation': 'Start Formation',
      'turn_white': "White's Turn",
      'turn_black': "Black's Turn",
      'check': 'CHECK!',
      'game_over': 'Game Over',
      'white_wins': 'White Team Wins!',
      'black_wins': 'Black Team Wins!',
      'play_again': 'Play Again',
      'hp': 'HP',

      // Piece / card names
      'piece_king': 'King',
      'piece_queen': 'Queen',
      'piece_pawn': 'Pawn',
      'piece_goblin': 'Goblin',
      'piece_skele_archer': 'Skeleton Archer',
      'piece_golem': 'Rock Golem',

      // Move styles (for card descriptions)
      'move_king_style': 'Moves 1 square in any direction',
      'move_queen_style': 'Moves any distance, straight or diagonal',
      'move_pawn_style': 'Moves forward, captures diagonally',
      'move_knight_style': 'Jumps in an L-shape',
      'move_bishop_style': 'Moves any distance diagonally',
      'move_rook_style': 'Moves any distance in a straight line',

      // Store
      'store_title': 'Store',
      'store_subtitle': 'Unlock new cards and grow your collection',
      'buy': 'Buy',
      'owned': 'Owned',
      'gold': 'Gold',
      'not_enough_gold': 'Not enough gold!',
      'purchased': 'purchased!',

      // My Cards
      'cards_title': 'My Cards',
      'cards_subtitle': 'All the cards you own are here',
      'rarity_common': 'Common',
      'rarity_rare': 'Rare',
      'rarity_epic': 'Epic',
      'attack': 'Attack',

      // Clan
      'clan_title': 'Clan',
      'clan_subtitle': 'Team up with friends and fight together',
      'clan_no_clan': "You don't have a clan yet",
      'clan_create': 'Create Clan',
      'clan_join': 'Join Clan',
      'clan_members': 'Members',
      'clan_placeholder': 'This feature is coming very soon. Clans will let you team up with '
          'friends and join tournaments together.',

      // Clan — browse / create
      'clan_browse_title': 'Join a Clan',
      'clan_or_create': 'or create your own',
      'clan_create_title': 'Create Clan',
      'clan_name_label': 'Clan Name',
      'clan_tag_label': 'Clan Tag (3-4 letters)',
      'clan_pick_icon': 'Choose Icon',
      'clan_create_button': 'Create Clan',
      'clan_join_button': 'Join',
      'clan_name_required': 'Clan name is required',
      'clan_tag_required': 'Clan tag is required (min 2 letters)',

      // Clan — dashboard
      'clan_level': 'Level',
      'clan_members_count': 'Members',
      'clan_treasury': 'Treasury',
      'clan_donate': 'Donate',
      'clan_donate_title': 'Donate to Clan',
      'clan_donate_hint': 'Gold you donate increases the clan level.',
      'clan_donate_confirm': 'Donate',
      'clan_leave': 'Leave Clan',
      'clan_leave_confirm_title': 'Leave the Clan?',
      'clan_leave_confirm_body': "If you leave, you'll need to join or create another clan.",
      'clan_leave_confirm_yes': 'Leave',

      // Clan War
      'clan_war_title': 'Clan War',
      'clan_war_score': 'Score',
      'clan_war_join': 'Join Battle',
      'clan_war_rival': 'Rival Clan',
      'clan_war_result_won': 'You Won the Clan War!',
      'clan_war_result_lost': 'You Lost the Clan War',
      'clan_war_return': 'Return to Clan',
      'clan_war_played': 'Played',
      'clan_war_won': 'Won',

      // Clan Quests
      'clan_quests_title': 'Clan Quests',
      'clan_quests_refresh': 'Refresh Quests',
      'clan_quest_claim': 'Claim Reward',
      'clan_quest_claimed': 'Claimed',
      'quest_donate_desc': 'Donate 200 gold to the clan',
      'quest_playwar_desc': 'Play 1 Clan War battle',
      'quest_winwar_desc': 'Win 1 Clan War battle',
      'quest_reward_claimed': 'Reward claimed!',

      // Clan Members
      'clan_members_title': 'Members',
      'clan_role_leader': 'Leader',
      'clan_role_officer': 'Officer',
      'clan_role_member': 'Member',
      'clan_you': '(You)',

      // Language picker
      'language': 'Language',
      'select_language': 'Select Language',

      // Lobby / Battle
      'battle_button': 'BATTLE',
      'searching_opponent': 'Searching for Opponent...',
      'searching_waiting_hint': "No opponent available right now, waiting for someone to join. This is normal.",
      'searching_error': 'Something went wrong finding a match, try again',
      'cancel_search': 'Cancel',
      'return_to_lobby': 'Return to Lobby',
      'lobby_subtitle': 'Ready to battle?',
      'trophies': 'Trophies',
      'opponent_label': 'Opponent',
      'your_turn': 'Your Turn',
      'opponent_turn': "Opponent's Turn",
      'resign_button': 'Resign',
      'resign_confirm_title': 'Do you want to resign?',
      'resign_confirm_body': 'If you resign, your opponent automatically wins and you lose trophies.',
      'match_you_won': 'You Won! 🎉',
      'match_you_lost': 'You Lost',
      'match_opponent_resigned': 'Your opponent resigned, you won! 🎉',
      'match_you_resigned': 'You resigned',
      'match_won_by_disconnect': 'Your opponent disconnected, you won! 🎉',
      'match_lost_by_disconnect': 'You lost because you disconnected',
      'leave_match_title': 'Leave the Match?',
      'leave_match_body': "The match is still going. If you leave, you'll be counted as resigning and your opponent wins.",
      'opponent_away_hint': "Your opponent hasn't seemed to respond for a while.",
      'claim_victory_button': 'Claim Victory',
      'resume_match_title': 'You have a match in progress',
      'resume_match_button': 'Return to Match',

      // Profile
      'profile_title': 'My Profile',
      'profile_name': 'Player Name',
      'profile_change_avatar': 'Choose Avatar',
      'profile_default_name': 'Player',
      'save': 'Save',
      'saved': 'Saved!',

      // Settings
      'settings_title': 'Settings',
      'settings_sound': 'Sound Settings',
      'settings_music': 'Music',
      'settings_sfx': 'Sound Effects',
      'settings_music_volume': 'Music Volume',
      'settings_sfx_volume': 'SFX Volume',
      'settings_language': 'Language',

      // My Cards - tabs
      'tab_collection': 'Collection',
      'tab_formation': 'Formation',
      'formation_title': 'Edit Your Formation',
      'formation_subtitle': 'You can only change your cards here',
      'formation_pawns': 'Pawn Row',
      'formation_dps_left': 'Left DPS',
      'formation_dps_right': 'Right DPS',
      'formation_queen': 'Queen',
      'formation_king': 'King',
      'formation_choose_card': 'Choose Card',
      'formation_locked_hint': 'Unlock more cards in the Store to add them here',
      'slot_a': 'A',
      'slot_b': 'B',
      'slot_c': 'C',
      'slot_d': 'D',

      // New cards
      'piece_dark_enchantress': 'Dark Enchantress',
      'piece_armored_king': 'Armored King',

      // Classic base pieces
      'piece_knight_basic': 'Knight',
      'piece_bishop_basic': 'Bishop',
      'piece_rook_basic': 'Rook',

      // New rarities
      'rarity_legendary': 'Legendary',
      'rarity_mythic': 'Mythic',

      // Pawn variations
      'piece_sipahi': 'Cavalryman',
      'piece_maden_muhafizi': 'Mine Guardian',
      'piece_golge_piyonu': 'Shadow Pawn',

      // Knight variations
      'piece_pegasus': 'Pegasus',
      'piece_kabus': 'Nightmare',

      // Bishop variations
      'piece_buyucu': 'Illusionist',
      'piece_saman': 'Shaman',

      // Rook variations
      'piece_mancinik': 'Catapult Tower',
      'piece_barikat': 'Barricade Rook',

      // Queen variations
      'piece_ejderha_kralice': 'Dragon Queen',
      'piece_zaman_lordu': 'Time Lord',

      // King variations
      'piece_savasci_kral': 'Warrior King',
      'piece_necromancer_sah': 'Necromancer King',

      // Ability descriptions
      'ability_none': '',
      'ability_cavalry_rush': 'Cavalry Rush: Can leap 3 squares forward on its first move',
      'ability_stone_skin': 'Stone Skin: Absorbs the first lethal hit, survives with 1 HP',
      'ability_blind_spot': 'Blind Spot: Can jump over the piece in front to capture 2 squares diagonally',
      'ability_wind_glide': 'Wind Glide: Grants a 1-move shield to allied pawns around its landing square',
      'ability_fear_aura': 'Fear Aura: Freezes enemy pieces adjacent to its landing square for 1 turn',
      'ability_mirror_reflection': 'Mirror Reflection: Once per game, can shift 1 square orthogonally to change square color',
      'ability_spirit_path': 'Spirit Path: Can bend its diagonal 90° if an allied pawn has died',
      'ability_catapult_strike': "Long Shot: Doesn't move; strikes an enemy 3 squares away in a straight line",
      'ability_barricade': 'Heavy Stone: Adjacent allies are protected from enemy knight-style attacks',
      'ability_flame_line': 'Flame Line: After a capture, sets the square behind it on fire for 1 turn',
      'ability_rewind': 'Rewind: Once per game, undoes the last move and gains an extra move',
      'ability_last_stand': 'Last Stand: When checked, can capture the adjacent threatening piece',
      'ability_soul_summon': 'Soul Summon: Once per game, if no pawns remain, summons a skeleton pawn',

      // Store category headers
      'tier_pawn': 'Pawn Variations',
      'tier_knight': 'Knight Variations',
      'tier_bishop': 'Bishop Variations',
      'tier_rook': 'Rook Variations',
      'tier_queen': 'Queen Variations',
      'tier_king': 'King Variations',

      // Card Test Lab
      'test_lab_title': 'Card Test Lab',
      'test_lab_entry': 'Card Test Lab',
      'test_lab_subtitle': 'Try each card, one at a time, in an isolated scenario',
      'test_reset': 'Reset Scenario',
      'test_lab_hint': 'Tap a square, then tap a target square. Long-press a piece to see its info. There is no turn restriction — move any piece anytime.',

      // Level System
      'level': 'Level',
      'card_level_up': 'Level Up',
      'card_level_up_cost': 'Upgrade Cost',
      'card_max_level': 'Max Level',
      'card_level_up_success': 'leveled up!',
      'card_level_bonus_hp': 'HP',
      'card_level_bonus_attack': 'Attack',
      'card_level_preview': 'at next level',

      // Ability UI
      'special_ability': 'Special Ability',
      'rewind_button': 'Rewind',
      'ability_used': 'Used',
      'piece_info_close': 'Close',
    },
  };
}

/// Kısayol: `tr('key')` çağrısı aktif dildeki metni döndürür.
/// (Fonksiyon adı Türkçe "tr" ile karışmasın diye kısaca [loc] de kullanılabilir.)
String loc(String key) => LocalizationService.instance.t(key);

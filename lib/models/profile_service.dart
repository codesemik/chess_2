import 'package:flutter/foundation.dart';
import '../l10n/localization_service.dart';

/// Profil ekranında seçilebilecek avatarlar.
const List<String> kAvailableAvatars = [
  '🦁', '🐯', '🐺', '🦊', '🐲', '🥷', '🧙', '👑', '💀', '🤖', '🦅', '🐉',
];

/// Oyuncunun profil bilgilerini (isim, avatar, kupa sayısı) tutan servis.
class ProfileService extends ChangeNotifier {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  String? _customName;
  String avatar = kAvailableAvatars.first;
  int trophies = 120;

  String get name => _customName ?? loc('profile_default_name');

  void setName(String newName) {
    _customName = newName.trim().isEmpty ? null : newName.trim();
    notifyListeners();
  }

  void setAvatar(String emoji) {
    avatar = emoji;
    notifyListeners();
  }

  /// Çevrimiçi bir maç bitince kupa sayısını günceller (kazanınca pozitif,
  /// kaybedince negatif bir [delta] ile çağrılır). 0'ın altına inmez.
  void addTrophies(int delta) {
    trophies = (trophies + delta).clamp(0, 1000000);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // BULUT SENKRONİZASYONU (Firestore) — bkz. CloudSyncService
  // ---------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'name': _customName,
        'avatar': avatar,
        'trophies': trophies,
      };

  void restoreFromJson(Map<String, dynamic> json) {
    final n = json['name'];
    _customName = (n is String && n.trim().isNotEmpty) ? n : null;
    avatar = json['avatar'] as String? ?? avatar;
    final t = json['trophies'];
    if (t is num) trophies = t.toInt();
  }
}

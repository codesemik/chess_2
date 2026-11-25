import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/piece_library.dart';

/// Kartın nadir derecesine göre tema rengini döndürür.
/// Mağaza ve Kartlarım ekranları arasında tutarlılık için ortak kullanılır.
Color rarityColor(Rarity r) {
  switch (r) {
    case Rarity.common:
      return Colors.grey;
    case Rarity.rare:
      return Colors.blueAccent;
    case Rarity.epic:
      return Colors.purpleAccent;
    case Rarity.legendary:
      return Colors.orangeAccent;
    case Rarity.mythic:
      return Colors.pinkAccent;
  }
}

/// Kartın nadir derecesinin aktif dildeki metni.
String rarityLabel(Rarity r) {
  switch (r) {
    case Rarity.common:
      return loc('rarity_common');
    case Rarity.rare:
      return loc('rarity_rare');
    case Rarity.epic:
      return loc('rarity_epic');
    case Rarity.legendary:
      return loc('rarity_legendary');
    case Rarity.mythic:
      return loc('rarity_mythic');
  }
}

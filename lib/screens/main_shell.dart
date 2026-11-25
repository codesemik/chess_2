import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import 'store_screen.dart';
import 'game_screen.dart';
import 'cards_screen.dart';
import 'clan_screen.dart';

/// Uygulamanın ana iskeleti: alt navigasyon barı ile 4 sekme arasında geçiş
/// sağlar (Mağaza / Oyun / Kartlarım / Klan).
/// Her sekmenin kendi üst arayüzü olduğu için (Oyun sekmesinde profil/ayarlar,
/// diğerlerinde kendi başlıkları) global bir AppBar kullanılmaz.
/// Sekme state'lerinin kaybolmaması için IndexedStack kullanılır.
class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1; // Varsayılan olarak "Oyun" sekmesiyle açılır

  final List<Widget> _screens = const [
    StoreScreen(),
    GameScreen(),
    CardsScreen(),
    ClanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront),
                label: loc('nav_store'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.sports_esports_outlined),
                selectedIcon: const Icon(Icons.sports_esports),
                label: loc('nav_play'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.style_outlined),
                selectedIcon: const Icon(Icons.style),
                label: loc('nav_cards'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.shield_outlined),
                selectedIcon: const Icon(Icons.shield),
                label: loc('nav_clan'),
              ),
            ],
          ),
        );
      },
    );
  }
}

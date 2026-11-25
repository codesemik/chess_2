# ♟️ Tactical Fantasy Chess (Flutter & Firebase)

[![Flutter CI](https://github.com/KULLANICI_ADIN/REPO_ADIN/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/codesemik/chess_2/actions/workflows/flutter_ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)

A cross-platform, real-time multiplayer strategy game built with **Flutter** and **Firebase**. Combining classic chess mechanics with RPG-style deck building, custom unit abilities, card progression, and clan warfare.

> **Project Status:** Core gameplay engine, custom unit abilities, Firebase backend synchronization, and unit tests are implemented. Currently archived as an open-source showcase of game state architecture and full-stack Flutter development.

---

## ✨ Key Features

* **Custom Chess Engine & Special Units:** Extends traditional chess rules with 25+ unique characters (e.g., *Time Lord*, *Dragon Queen*, *Necromancer King*, *Catapult*, *Golem*, *Shadow Pawn*), each featuring custom movement patterns and active/passive abilities.
* **Deck & Formation Builder:** Players collect unit cards, upgrade their levels, and customize their starting board formations before entering a match.
* **Real-Time Multiplayer & Matchmaking:** Built-in matchmaking queue and live board state synchronization powered by Cloud Firestore (`matchmaking_service.dart`, `online_match_controller.dart`).
* **Clan System & Clan Wars:** Full social infrastructure allowing players to create/join clans and participate in clan wars.
* **Cloud Sync & Authentication:** Seamless user authentication and cross-device progress synchronization (`auth_service.dart`, `cloud_sync_service.dart`).
* **Localization (`l10n`):** Multi-language support structured directly into the service layer.
* **Automated Testing & CI/CD:** Comprehensive unit and controller test suites (`test/`) integrated with GitHub Actions (`flutter_ci.yml`).

---

## 🏗️ Project Architecture

```text
lib/
├── controllers/       # Core board logic, turn management, and move validation
├── l10n/              # Localization services and multi-language strings
├── models/
│   ├── pieces/        # Polymorphic piece architecture (piece_base.dart & 25+ units)
│   └── *_service.dart # Matchmaking, Auth, Cloud Sync, Clan, and Collection services
├── screens/           # Game board, Deck/Cards, Store, Clan Wars, Profile, and Test Sandbox
├── utils/             # Rarity helpers and shared utilities
└── widgets/           # Reusable UI components and interactive board grid
```

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (3.x or higher)
* Dart SDK
* A Firebase project (for Authentication and Cloud Firestore)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/KULLANICI_ADIN/REPO_ADIN.git
   cd REPO_ADIN
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   * Copy the template configuration file:
     ```bash
     cp lib/firebase_options.example.dart lib/firebase_options.dart
     ```
   * Run `flutterfire configure` (or manually update `lib/firebase_options.dart` and add your `google-services.json` / `GoogleService-Info.plist`) with your own Firebase project credentials.
   * Deploy the included security rules (`firestore.rules`) to your Firestore database.

4. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🧪 Running Tests

The project includes unit tests for core board mechanics, piece behaviors, card leveling, and matchmaking logic:

```bash
flutter test
```

---

## 🗺️ Roadmap & Future Scope

While active development is currently paused, the architecture is modular and ready for future extensions:
- [ ] Ranked seasonal leaderboards
- [ ] Replay system for past matches
- [ ] Additional VFX and sound effects for special unit abilities
- [ ] Expanded AI bot difficulty levels for offline practice

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
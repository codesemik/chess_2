import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([LocalizationService.instance, SettingsService.instance]),
      builder: (context, _) {
        final settings = SettingsService.instance;
        return Scaffold(
          appBar: AppBar(title: Text(loc('settings_title'))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(title: loc('settings_language')),
              Card(
                child: Column(
                  children: AppLanguage.values.map((lang) {
                    final selected = LocalizationService.instance.language == lang;
                    return RadioListTile<AppLanguage>(
                      value: lang,
                      groupValue: LocalizationService.instance.language,
                      onChanged: (value) {
                        if (value != null) LocalizationService.instance.setLanguage(value);
                      },
                      title: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(lang.label),
                        ],
                      ),
                      selected: selected,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: loc('settings_sound')),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.music_note),
                      title: Text(loc('settings_music')),
                      value: settings.musicEnabled,
                      onChanged: settings.toggleMusic,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_down, size: 18),
                          Expanded(
                            child: Slider(
                              value: settings.musicVolume,
                              onChanged: settings.musicEnabled ? settings.setMusicVolume : null,
                            ),
                          ),
                          const Icon(Icons.volume_up, size: 18),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.graphic_eq),
                      title: Text(loc('settings_sfx')),
                      value: settings.sfxEnabled,
                      onChanged: settings.toggleSfx,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_down, size: 18),
                          Expanded(
                            child: Slider(
                              value: settings.sfxVolume,
                              onChanged: settings.sfxEnabled ? settings.setSfxVolume : null,
                            ),
                          ),
                          const Icon(Icons.volume_up, size: 18),
                        ],
                      ),
                    ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

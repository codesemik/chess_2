import 'package:flutter/material.dart';
import '../l10n/localization_service.dart';
import '../models/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late String _selectedAvatar;

  @override
  void initState() {
    super.initState();
    final profile = ProfileService.instance;
    _nameController = TextEditingController(text: profile.name);
    _selectedAvatar = profile.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    ProfileService.instance.setName(_nameController.text);
    ProfileService.instance.setAvatar(_selectedAvatar);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc('saved')), duration: const Duration(seconds: 1)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        final profile = ProfileService.instance;
        return Scaffold(
          appBar: AppBar(title: Text(loc('profile_title'))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.deepPurple.withOpacity(0.3),
                  child: Text(_selectedAvatar, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${profile.trophies} ${loc('trophies')}'),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  maxLength: 16,
                  decoration: InputDecoration(
                    labelText: loc('profile_name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(loc('profile_change_avatar'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: kAvailableAvatars.map((emoji) {
                    final isSelected = emoji == _selectedAvatar;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = emoji),
                      child: Container(
                        width: 52,
                        height: 52,
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
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(loc('save')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

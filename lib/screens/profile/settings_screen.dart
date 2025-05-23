import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/translation_service.dart';
import 'edit_password_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final String currentName;
  final String currentAvatar;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.currentName,
    required this.currentAvatar,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _nameController = TextEditingController(text: widget.currentName);
  late final _firstNameController = TextEditingController();
  late final _lastNameController = TextEditingController();
  late String _selectedAvatar = widget.currentAvatar;
  late String _selectedLanguage;

  final _avatars = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
  ];

  final _languages = {
    'ru': 'Русский',
    'kk': 'Қазақша',
    'en': 'English',
  };

  @override
  void initState() {
    super.initState();
    _selectedLanguage = context.read<LanguageProvider>().currentLanguage;
    FirebaseFirestore.instance.collection('users').doc(widget.userId).get().then((doc) {
      final data = doc.data();
      if (data != null) {
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final updates = {
      "username": _nameController.text,
      "firstName": _firstNameController.text,
      "lastName": _lastNameController.text,
      "avatar": _selectedAvatar,
      "language": _selectedLanguage,
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updates);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _selectedLanguage);

      await context.read<LanguageProvider>().setLanguage(_selectedLanguage, widget.userId);
      await Future.delayed(const Duration(milliseconds: 50));
      await TranslationService.load(_selectedLanguage);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.t('save_success'))),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${TranslationService.t('save_error')}: $e')),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          TranslationService.t('settings'),
          style: TextStyle(color: colorScheme.onBackground),
        ),
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: Text(
              TranslationService.t('save'),
              style: TextStyle(color: colorScheme.primary),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _avatars.map((path) {
                        final selected = _selectedAvatar == path;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = path),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundImage: AssetImage(path),
                              child: selected ? const Icon(Icons.check_circle, color: Colors.green, size: 30) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _nameController, decoration: _input(TranslationService.t('username'))),
                  const SizedBox(height: 12),
                  TextField(controller: _firstNameController, decoration: _input(TranslationService.t('first_name'))),
                  const SizedBox(height: 12),
                  TextField(controller: _lastNameController, decoration: _input(TranslationService.t('last_name'))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(TranslationService.t('change_password')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditPasswordScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildDropdown(
            icon: Icons.language,
            label: TranslationService.t('language'),
            value: _selectedLanguage,
            items: _languages,
            onChanged: (val) async {
              setState(() => _selectedLanguage = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('language', val);
              await context.read<LanguageProvider>().setLanguage(val, widget.userId);
              await Future.delayed(const Duration(milliseconds: 50));
              await TranslationService.load(val);
            },
          ),
          const SizedBox(height: 24),
          _buildDropdown<ThemeMode>(
            icon: Icons.palette_outlined,
            label: TranslationService.t('theme'),
            value: themeProvider.themeMode,
            items: {
              ThemeMode.system: TranslationService.t('theme_system'),
              ThemeMode.light: TranslationService.t('theme_light'),
              ThemeMode.dark: TranslationService.t('theme_dark'),
            },
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('theme', val.name);
              await themeProvider.setThemeMode(val, widget.userId);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: Text(TranslationService.t('logout')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required IconData icon,
    required String label,
    required T value,
    required Map<T, String> items,
    required void Function(T) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<T>(
            value: value,
            items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
            decoration: _input(label),
          ),
        ),
      ],
    );
  }
}

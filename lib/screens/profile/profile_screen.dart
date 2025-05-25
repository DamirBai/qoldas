import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_screen.dart';
import 'progress_screen.dart';
import '../../services/translation_service.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  final bool isAdmin;

  const ProfileScreen({
    Key? key,
    required this.userId,
    this.isAdmin = false,
  }) : super(key: key);

  String _resolveAvatarPath(dynamic avatar) {
    if (avatar == null || avatar.toString().isEmpty) {
      return 'assets/avatars/avatar1.png';
    }
    return avatar.toString().startsWith('assets/avatars/')
        ? avatar.toString()
        : 'assets/avatars/$avatar';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('${TranslationService.t("profile_load_error")}: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(child: Text(TranslationService.t("profile_not_found"))),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Stack(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(_resolveAvatarPath(data['avatar'])),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data['username'] ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                userId: userId,
                                currentName: data['username'] ?? '',
                                currentAvatar: _resolveAvatarPath(data['avatar']),
                              ),
                            ),
                          );

                          if (result == true && context.mounted) {
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _infoTile(TranslationService.t('username'), data['username']),
                _infoTile('Email', data['email']),
                _infoTile(TranslationService.t('first_name'), data['firstName']),
                _infoTile(TranslationService.t('last_name'), data['lastName']),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProgressScreen(userId: userId)),
                    );
                  },
                  child: Text(TranslationService.t('my_progress')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(String title, dynamic value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value?.toString().trim().isNotEmpty == true
          ? value.toString()
          : TranslationService.t('not_specified')),
    );
  }
}

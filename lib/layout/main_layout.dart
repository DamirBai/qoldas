import 'package:flutter/material.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/courses/courses_screen.dart';
import '../../screens/plans/plans_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../services/user_service.dart';
import '../../services/translation_service.dart';

class MainLayout extends StatefulWidget {
  final String userId;

  const MainLayout({super.key, required this.userId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    final admin = await UserService.isAdmin(widget.userId);
    print('[MainLayout] isAdmin: $admin');
    setState(() {
      _isAdmin = admin;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      HomeScreen(userId: widget.userId, isAdmin: _isAdmin),
      CoursesScreen(userId: widget.userId, isAdmin: _isAdmin),
      const PlansScreen(),
      ProfileScreen(userId: widget.userId, isAdmin: _isAdmin),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: isDark
              ? const Color(0xFF6F7BD9).withOpacity(0.2)
              : const Color(0xFFB0C7FF).withOpacity(0.2),
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedFontSize: 13,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          selectedItemColor:
              isDark ? const Color(0xFFB4BBFF) : const Color(0xFF3F51B5),
          unselectedItemColor:
              isDark ? Colors.white70 : Colors.black45,
          elevation: 12,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined, size: 24),
              activeIcon: const Icon(Icons.home, size: 26),
              label: TranslationService.t('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.school_outlined, size: 24),
              activeIcon: const Icon(Icons.school, size: 26),
              label: TranslationService.t('courses'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star_outline, size: 24),
              activeIcon: const Icon(Icons.star, size: 26),
              label: TranslationService.t('plans'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline, size: 24),
              activeIcon: const Icon(Icons.person, size: 26),
              label: TranslationService.t('profile'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sportsin/screens/feed/feed_screen.dart';
import 'package:sportsin/screens/opening/opening_screen.dart';
import 'package:sportsin/screens/tournament/tournament_screen.dart';
import 'package:sportsin/screens/profile/player_details.dart';
import 'package:sportsin/screens/profile/recruiter_details.dart';
import 'package:sportsin/services/db/db_provider.dart';
import '../../services/auth/auth_service.dart';
import '../../components/custom_toast.dart';
import '../../config/routes/route_names.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService.customProvider();

  late PageController _pageController;
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _pages = [
      FeedScreen(userId: DbProvider.instance.cashedUser?.id),
      const NotificationScreen(),
      const TournamentScreen(),
      DbProvider.instance.cashedUser?.role.value == 'player'
          ? const PlayerDetailsScreen()
          : const RecruiterDetailsScreen(),
    ];

    final cachedUser = DbProvider.instance.cashedUser;

    if (cachedUser != null) {
      debugPrint(
          'HomeScreen: Using cached user: ${cachedUser.name} (${cachedUser.role.value})');
    } else {
      debugPrint('HomeScreen: No cached user found');
      final singletonUser = DbProvider.instance.user;
      if (singletonUser != null) {
        debugPrint(
            'HomeScreen: Found user in singleton: ${singletonUser.name}');
      } else {
        debugPrint('HomeScreen: No user in singleton either');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    try {
      await _authService.signOut();

      if (mounted) {
        CustomToast.showSuccess(
          message: 'Successfully logged out',
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.goNamed(RouteNames.login);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(
          message: 'Failed to logout. Please try again.',
        );
      }
    }
  }

  void _onNavBarTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome ${(DbProvider.instance.cashedUser?.userName ?? DbProvider.instance.user?.name ?? 'User').length > 12 ? '${(DbProvider.instance.cashedUser?.userName ?? DbProvider.instance.user?.name ?? 'User').substring(0, 12)}...' : (DbProvider.instance.cashedUser?.userName ?? DbProvider.instance.user?.name ?? 'User')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 24),
            onPressed: () => context.pushNamed(RouteNames.chatScreen),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 24),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _pages,
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.blueAccent, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              spreadRadius: 4,
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => context.pushNamed(RouteNames.postCreation),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E1E),
              Color(0xFF2A2A2A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomAppBar(
          height: 75,
          color: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Feed', 0),
                _buildNavItem(Icons.notifications_rounded, 'Notifications', 1),
                const SizedBox(width: 50), // Space for the FAB
                _buildNavItem(Icons.sports_soccer, 'Tournament', 2),
                _buildNavItem(Icons.person_rounded, 'Me', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onNavBarTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

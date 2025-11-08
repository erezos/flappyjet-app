/// 🏠 HOME NAVIGATOR SCREEN - Modern Tab Navigation System
/// Swipeable PageView with floating bottom navigator (Brawl Stars style)
library;

import 'package:flutter/material.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../widgets/navigation/bottom_navigator_bar.dart';
import 'store_page.dart';
import 'tournaments_page.dart';
import 'story_page.dart';
import 'missions_page.dart';
import 'profile_page.dart';

class HomeNavigatorScreen extends StatefulWidget {
  final bool firebaseEnabled;
  final MonetizationManager monetization;
  final MissionsManager missions;
  final AchievementsManager achievements;

  const HomeNavigatorScreen({
    super.key,
    required this.firebaseEnabled,
    required this.monetization,
    required this.missions,
    required this.achievements,
  });

  @override
  State<HomeNavigatorScreen> createState() => _HomeNavigatorScreenState();
}

class _HomeNavigatorScreenState extends State<HomeNavigatorScreen> {
  late PageController _pageController;
  int _currentPage = 2; // Start at Story page (center)

  final List<String> _pageTitles = [
    'Store',
    'Tournaments',
    'Story',
    'Missions',
    'Profile',
  ];

  final List<IconData> _pageIcons = [
    Icons.shopping_bag,
    Icons.emoji_events,
    Icons.map,
    Icons.checklist,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for swipeable pages
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              // Page 0: Store
              StorePage(
                monetization: widget.monetization,
              ),
              
              // Page 1: Tournaments
              TournamentsPage(
                monetization: widget.monetization,
                missions: widget.missions,
              ),
              
              // Page 2: Story (default/home)
              StoryPage(
                firebaseEnabled: widget.firebaseEnabled,
                monetization: widget.monetization,
                missions: widget.missions,
                achievements: widget.achievements,
              ),
              
              // Page 3: Missions
              MissionsPage(
                missions: widget.missions,
              ),
              
              // Page 4: Profile
              ProfilePage(
                achievements: widget.achievements,
              ),
            ],
          ),
          
          // Floating bottom navigator bar (Brawl Stars style)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: BottomNavigatorBar(
              currentIndex: _currentPage,
              titles: _pageTitles,
              icons: _pageIcons,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}


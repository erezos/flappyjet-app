/// 🏠 HOME NAVIGATOR SCREEN - Modern Tab Navigation System
/// Swipeable PageView with floating bottom navigator (Brawl Stars style)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../../game/systems/menu_audio_manager.dart';
import '../../game/systems/daily_streak_manager.dart';
import '../../core/debug_logger.dart';
import '../widgets/navigation/bottom_navigator_bar.dart';
import '../widgets/exit_confirmation_popup.dart';
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

class _HomeNavigatorScreenState extends State<HomeNavigatorScreen> 
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentPage = 2; // Start at Story page (center)
  
  // 🎵 Menu audio manager for background music
  late MenuAudioManager _menuAudio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pageController = PageController(initialPage: _currentPage);
    
    // 🎵 Initialize menu audio
    _menuAudio = MenuAudioManager();
    Future.microtask(() => _menuAudio.initialize());
    
    safePrint('🏠 HomeNavigatorScreen initialized with menu audio');
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for audio (pause/resume)
    _menuAudio.handleAppLifecycle(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _menuAudio.dispose();
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

  /// 🚪 Handle back button press - show exit confirmation on Story tab only
  Future<bool> _onWillPop() async {
    // Only show exit confirmation when on Story tab (index 2 = homepage)
    if (_currentPage == 2) {
      // Generate contextual reminder message
      final reminderMessage = _getReminderMessage();
      
      final shouldExit = await showExitConfirmation(
        context,
        reminderMessage: reminderMessage,
      );
      
      if (shouldExit) {
        safePrint('🚪 User confirmed exit from homepage');
        // Exit the app
        SystemNavigator.pop();
        return true;
      }
      
      safePrint('🚪 User chose to stay');
      return false;
    }
    
    // On other tabs, navigate to Story tab instead of exiting
    _pageController.animateToPage(
      2, // Story tab
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    return false;
  }
  
  /// Get contextual reminder message based on user state
  String? _getReminderMessage() {
    try {
      final streakManager = DailyStreakManager();
      
      // Check if daily streak reward is available (not yet claimed today)
      if (streakManager.shouldShowPopup) {
        return "Don't forget to claim your daily streak reward! 🎁";
      }
      
      // Check if close to weekly milestone
      final currentDay = streakManager.currentStreak;
      if (currentDay > 0 && currentDay % 7 == 6) {
        return "You're 1 day away from a weekly milestone! Keep your streak alive! 🔥";
      }
      
      // Default message
      return "Your jet is ready for more adventures! ✈️";
    } catch (e) {
      // If streak manager isn't available, use default
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚪 Wrap with PopScope to handle back button
    return PopScope(
      canPop: false, // We handle all back button presses manually
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Already popped, do nothing
        await _onWillPop();
      },
      child: Scaffold(
      body: PageView(
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
            achievements: widget.achievements,
          ),
          
          // Page 4: Profile
          ProfilePage(
            achievements: widget.achievements,
          ),
        ],
      ),
      // ✅ FULL-WIDTH BOTTOM NAVIGATION BAR (Custom Fighter Jet Dashboard)
      bottomNavigationBar: BottomNavigatorBar(
        currentIndex: _currentPage,
        onTap: _onNavTap,
      ),
      ),
    );
  }
}


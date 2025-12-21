/// 🏠 HOMEPAGE LAYOUT - Base layout with footer navigator
/// 
/// Wraps content screens with the footer navigator.
/// Used for all screens except GameScreen.
/// 
/// ✅ Flame Best Practices: Reusable layout, clear separation of concerns
/// ✅ Mobile Gaming Standards: Consistent navigation, responsive design
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/homepage_footer_navigator.dart';
import '../screens/world_map_screen.dart';
import '../screens/store_page.dart';
import '../screens/tournament_hub_screen.dart';
import '../screens/daily_missions_screen.dart';
import '../screens/profile_page.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../utils/responsive_config.dart';

/// Base layout that wraps content with footer navigator
class HomepageLayout extends StatefulWidget {
  final Widget child;
  final FooterNavigatorSection? activeSection;
  
  const HomepageLayout({
    super.key,
    required this.child,
    this.activeSection,
  });

  @override
  State<HomepageLayout> createState() => _HomepageLayoutState();
}

class _HomepageLayoutState extends State<HomepageLayout> {
  // Swipe gesture tracking
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;
  static const double _minSwipeDistance = 50.0; // Minimum distance to trigger tab switch
  
  /// Check if current screen is World Map (World Map doesn't use HomepageLayout, but check for safety)
  bool _isWorldMapScreen() {
    return widget.child is WorldMapScreen;
  }
  
  /// Handle horizontal drag start
  void _onHorizontalDragStart(DragStartDetails details) {
    // Only track if not World Map (World Map has its own PageView for zones and doesn't use HomepageLayout)
    if (!_isWorldMapScreen()) {
      _dragStartX = details.globalPosition.dx;
      _dragCurrentX = _dragStartX;
    }
  }
  
  /// Handle horizontal drag update - track current position
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Only track if not World Map
    if (!_isWorldMapScreen()) {
      _dragCurrentX = details.globalPosition.dx;
    }
  }
  
  /// Handle horizontal drag end - switch tabs if appropriate
  void _onHorizontalDragEnd(DragEndDetails details, BuildContext context) {
    // Skip tab switching for World Map - it has its own PageView for zones
    // Footer navigator will handle swipes on the footer itself
    if (_isWorldMapScreen()) {
      _dragStartX = 0.0;
      _dragCurrentX = 0.0;
      return;
    }
    
    // Calculate actual swipe distance
    final swipeDistance = (_dragStartX - _dragCurrentX).abs();
    
    // Determine swipe direction
    final isSwipeLeft = _dragCurrentX < _dragStartX;
    final isSwipeRight = _dragCurrentX > _dragStartX;
    
    // For non-World Map screens: Allow swiping anywhere if distance is sufficient
    if (swipeDistance > _minSwipeDistance && (isSwipeLeft || isSwipeRight)) {
      // Haptic feedback for tab switch
      HapticFeedback.lightImpact();
      _switchTab(context, isSwipeLeft);
    }
    
    // Reset drag tracking
    _dragStartX = 0.0;
    _dragCurrentX = 0.0;
  }
  
  /// Switch to adjacent tab based on swipe direction
  void _switchTab(BuildContext context, bool swipeLeft) {
    final currentSection = widget.activeSection;
    if (currentSection == null) return;
    
    final sections = FooterNavigatorSection.values;
    final currentIndex = sections.indexOf(currentSection);
    
    FooterNavigatorSection? nextSection;
    
    if (swipeLeft && currentIndex < sections.length - 1) {
      // Swipe left = move to next tab (right)
      nextSection = sections[currentIndex + 1];
    } else if (!swipeLeft && currentIndex > 0) {
      // Swipe right = move to previous tab (left)
      nextSection = sections[currentIndex - 1];
    }
    
    if (nextSection != null) {
      _handleFooterNavigation(context, nextSection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final footerHeight = screenSize.width * (391.0 / 1490.0); // Footer aspect ratio
    
    // ✅ FIXED: Account for system navigation bar (Xiaomi, Samsung, etc.)
    // Mobile Gaming Best Practice: Treat system UI as NOT part of active screen
    // Flame Best Practice: Use actual viewport size excluding system UI
    final totalBottomPadding = ResponsiveConfig.getTotalBottomPadding(context, footerHeight);
    final safeFooterBottom = ResponsiveConfig.getSafeFooterBottomPosition(context, footerHeight);
    
    return Scaffold(
      body: GestureDetector(
        // ✅ Swipe detection for tab switching
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, context),
        behavior: HitTestBehavior.translucent, // Allow gestures to pass through when not handled
        child: Stack(
          children: [
            // Main content (with bottom padding for footer + system navigation bar)
            Padding(
              padding: EdgeInsets.only(bottom: totalBottomPadding),
              child: widget.child,
            ),
            
            // ✅ FIXED: Footer navigator positioned above system navigation bar
            // This prevents overlap on devices with system navigation bars (Xiaomi, etc.)
            Positioned(
              bottom: safeFooterBottom, // Position above system navigation bar
              left: 0,
              right: 0,
              child: HomepageFooterNavigator(
                activeSection: widget.activeSection,
                onSectionTap: (section) => _handleFooterNavigation(context, section),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Handle footer navigation
  void _handleFooterNavigation(BuildContext context, FooterNavigatorSection section) {
    switch (section) {
      case FooterNavigatorSection.store:
        _navigateToStore(context);
        break;
      case FooterNavigatorSection.tournaments:
        _navigateToTournaments(context);
        break;
      case FooterNavigatorSection.worldMap:
        _navigateToWorldMap(context);
        break;
      case FooterNavigatorSection.missions:
        _navigateToMissions(context);
        break;
      case FooterNavigatorSection.profile:
        _navigateToProfile(context);
        break;
    }
  }
  
  void _navigateToStore(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomepageLayout(
          activeSection: FooterNavigatorSection.store,
          child: StorePage(
            monetization: MonetizationManager(),
          ),
        ),
      ),
    );
  }
  
  void _navigateToTournaments(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomepageLayout(
          activeSection: FooterNavigatorSection.tournaments,
          child: TournamentHubScreen(
            monetization: MonetizationManager(),
            missions: MissionsManager(),
          ),
        ),
      ),
    );
  }
  
  void _navigateToWorldMap(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const WorldMapScreen(),
      ),
    );
  }
  
  void _navigateToMissions(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomepageLayout(
          activeSection: FooterNavigatorSection.missions,
          child: DailyMissionsScreen(
            missionsManager: MissionsManager(),
            achievementsManager: AchievementsManager(),
          ),
        ),
      ),
    );
  }
  
  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomepageLayout(
          activeSection: FooterNavigatorSection.profile,
          child: ProfilePage(
            achievements: AchievementsManager(),
          ),
        ),
      ),
    );
  }
}


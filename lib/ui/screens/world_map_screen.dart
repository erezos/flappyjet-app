/// 🗺️ STORY MODE - WORLD MAP SCREEN
/// 
/// Interactive world map showing level progression across zones.
/// Features animated paths, flying jet sprite, and responsive level nodes.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/systems/level_system_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../models/level_data_schema.dart';
import '../widgets/world_map_path_painter.dart';
import '../widgets/world_map_layout.dart';
import '../widgets/world_map_jet_widget.dart';
// ✅ REMOVED: WorldMapBanner import (banners removed, layout system kept for future use)
import 'level_objective_popup.dart';
import '../../core/debug_logger.dart';
import '../widgets/buttons/modern_game_button.dart';
import '../widgets/buttons/button_styles.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/missions_manager.dart';
import '../../game/systems/achievements_manager.dart';
import '../../integrations/ftue_integration.dart';
import '../../integrations/interstitial_ad_manager.dart';
// ✅ REMOVED: Old floating banner imports (replaced by homepage banners system)
import '../utils/responsive_config.dart';
import 'daily_missions_screen.dart';
// ✅ REMOVED: Legacy HomeNavigatorScreen import (replaced by HomepageLayout)
import '../widgets/status_bar/coins_gems_display.dart';
import '../widgets/status_bar/hearts_display.dart';
import '../widgets/daily_streak/daily_streak_homepage_integration.dart';
import '../widgets/daily_streak/daily_streak_floating_banner.dart';
import '../widgets/missions_achievements_claim_banner.dart';
import '../widgets/tournament/christmas_tournament_banner.dart';
import '../widgets/homepage_footer_navigator.dart';
import '../layouts/homepage_layout.dart';
import 'store_page.dart';
import 'tournament_hub_screen.dart';
import 'profile_page.dart';
import '../widgets/store/starter_boss_pack_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorldMapScreen extends StatefulWidget {
  /// ✅ NEW: Parameters for jet animation flow
  final bool shouldAnimateJet;
  final int? fromLevel;
  final int? toLevel;
  final bool fromCenter; // ✅ NEW: Start jet from center (zone completion)
  
  const WorldMapScreen({
    super.key,
    this.shouldAnimateJet = false,
    this.fromLevel,
    this.toLevel,
    this.fromCenter = false,
  });

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final LevelSystemManager _levelSystemManager = LevelSystemManager();
  final LivesManager _livesManager = LivesManager();
  final InventoryManager _inventoryManager = InventoryManager();
  bool _isInitialized = false;
  
  // ✅ NEW: PageView controller for zone swiping
  PageController? _pageController; // Nullable - will be initialized with correct page
  int _currentPageIndex = 0; // Tracks which zone page is currently visible
  
  // Animation state
  List<Offset> _nodePath = [];
  bool _isJetAnimating = false;
  
  // ✅ NEW: Jet movement animation system
  AnimationController? _jetAnimationController;
  Animation<Offset>? _jetPositionAnimation;
  Animation<double>? _jetScaleAnimation;
  bool _isAnimatingToNextLevel = false;
  bool _jetFacingLeft = false; // Track jet direction during animation

  @override
  void initState() {
    super.initState();
    // ✅ NEW: Add lifecycle observer to handle navigation back
    WidgetsBinding.instance.addObserver(this);
    // ✅ FIXED: Don't initialize PageController here - wait for managers to load
    // Will be initialized with correct page in _initializeManagers
    _initializeManagers();
    // Listen for zone changes
    _levelSystemManager.addListener(_onLevelSystemChanged);
  }

  bool _hasCheckedZoneOnBuild = false;
  int? _lastCheckedZone;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ FIXED: When navigating back to world map, ensure we're on the current level's zone
    // This fixes the issue where viewing a completed zone and navigating away/back
    // would keep you on that completed zone instead of returning to current level zone
    if (_isInitialized && _pageController != null) {
      _hasCheckedZoneOnBuild = false; // Reset to allow checking again
      _ensureCorrectZone();
    }
  }

  void _onLevelSystemChanged() {
    if (mounted) {
      setState(() {
        // Recalculate node positions when zone changes
        _calculateNodePositions();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _levelSystemManager.removeListener(_onLevelSystemChanged);
    _jetAnimationController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ✅ FIXED: When app resumes, ensure we're on the current level's zone
    if (state == AppLifecycleState.resumed && _isInitialized && _pageController != null) {
      _hasCheckedZoneOnBuild = false; // Reset to allow checking again
      _lastCheckedZone = null; // Reset to force check
      _ensureCorrectZone();
    }
  }
  
  /// ✅ NEW: Ensure we're viewing the current level's zone
  void _ensureCorrectZone() {
    if (!_isInitialized || _pageController == null || !_pageController!.hasClients) return;
    
    final currentLevel = _levelSystemManager.getLevelById(_levelSystemManager.currentLevel);
    final currentLevelZone = currentLevel?.zone ?? _levelSystemManager.currentZone;
    final allZones = _levelSystemManager.allZones;
    if (allZones.isEmpty) return;
    
    final expectedPageIndex = (currentLevelZone - 1).clamp(0, allZones.length - 1);
    
    // ✅ FIXED: Check if we need to jump to correct zone
    // Only jump if we're on the wrong zone AND we haven't already checked for this zone
    if (_currentPageIndex != expectedPageIndex && _lastCheckedZone != currentLevelZone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController != null && _pageController!.hasClients) {
          _pageController!.jumpToPage(expectedPageIndex);
          setState(() {
            _currentPageIndex = expectedPageIndex;
            _lastCheckedZone = currentLevelZone;
            _hasCheckedZoneOnBuild = true; // Mark as checked
          });
          _calculateNodePositionsForZone(currentLevelZone);
        }
      });
    } else if (_currentPageIndex == expectedPageIndex) {
      // We're on the correct zone, just update the tracking
      _lastCheckedZone = currentLevelZone;
      _hasCheckedZoneOnBuild = true;
    }
  }

  Future<void> _initializeManagers() async {
    if (!_levelSystemManager.isInitialized) {
      await _levelSystemManager.initialize();
    }
    await _livesManager.initialize();
    
    // ✅ FIXED: Set initial page to player's saved current zone (0-indexed)
    // Use saved currentZone directly - it's the source of truth for player's progress
    final initialZone = _levelSystemManager.currentZone;
    final allZones = _levelSystemManager.allZones;
    final initialPageIndex = (initialZone - 1).clamp(0, allZones.length > 0 ? allZones.length - 1 : 0); // Convert to 0-indexed, clamp to valid range
    
    if (mounted) {
      // ✅ FIXED: Initialize PageController with the correct initial page
      _pageController = PageController(initialPage: initialPageIndex);
      
      setState(() {
        _currentPageIndex = initialPageIndex;
        _isInitialized = true;
      });
      
      // Calculate node positions for the initial zone after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateNodePositionsForZone(initialZone);
          
          // ✅ NEW: Start jet animation if requested
          if (widget.shouldAnimateJet) {
            // ✅ FIX: Longer delay to ensure:
            // 1. Screen is fully painted and visible
            // 2. User can see the world map
            // 3. Brief moment to orient before animation starts
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) {
                _animateJetToNextLevel();
              }
            });
          }
        }
      });
    }
  }

  /// Calculate node positions for a specific zone
  void _calculateNodePositionsForZone(int zoneId) {
    final screenSize = MediaQuery.of(context).size;
    final zoneLevels = _levelSystemManager.allLevels
        .where((level) => level.zone == zoneId)
        .toList();
    
    if (zoneLevels.isEmpty) {
      setState(() {
        _nodePath = [];
      });
      return;
    }
    
    // ✅ NEW: Use layout system to get padding and exclusion zones
    final layout = WorldMapLayout(screenSize);
    final topOverlayHeight = layout.getTopPadding();
    final bottomOverlayHeight = layout.getBottomPadding();
    final exclusionZones = layout.getExclusionZones();
    
    setState(() {
      _nodePath = WorldMapPathCalculator.calculateZonePath(
        zoneId: zoneId,
        levelCount: zoneLevels.length,
        screenSize: screenSize,
        topPadding: topOverlayHeight, // Space for top overlays (balance)
        bottomPadding: bottomOverlayHeight, // Space for bottom overlay (footer navigator)
        exclusionZones: exclusionZones, // ✅ NEW: Avoid UI element areas
      );
    });
  }
  
  /// Calculate node positions for the currently visible zone
  void _calculateNodePositions() {
    final visibleZone = _currentPageIndex + 1; // Convert 0-indexed to 1-indexed
    _calculateNodePositionsForZone(visibleZone);
  }
  
  /// Handle page change in PageView
  void _onPageChanged(int pageIndex) {
    final newZone = pageIndex + 1; // Convert 0-indexed to 1-indexed
    setState(() {
      _currentPageIndex = pageIndex;
    });
    
    // ✅ FIXED: Only update current zone if:
    // 1. Zone is unlocked (can play levels)
    // 2. AND it's the player's actual current zone or a higher zone
    // This prevents overwriting progress when just viewing completed zones
    final unlockedZones = _levelSystemManager.getUnlockedZones();
    final playerCurrentZone = _levelSystemManager.currentZone;
    
    if (unlockedZones.contains(newZone)) {
      // Only update if viewing current zone or a higher zone (forward progress)
      // Don't update if viewing a lower/completed zone (would overwrite progress)
      if (newZone >= playerCurrentZone) {
        _levelSystemManager.setCurrentZone(newZone);
      } else {
        // Viewing a completed/lower zone - don't update saved progress
        // This allows viewing but preserves player's actual current zone
        safePrint('🗺️ Viewing completed zone $newZone (current zone: $playerCurrentZone) - not updating progress');
      }
    }
    // For locked zones, we just show them but don't update current zone
    
    // Recalculate node positions for the new zone (works for both locked and unlocked)
    _calculateNodePositionsForZone(newZone);
  }
  
  /// ✅ NEW: Animate jet from completed level to next level (or from center)
  Future<void> _animateJetToNextLevel() async {
    if (!widget.shouldAnimateJet) {
      return;
    }
    
    // Ensure node path is calculated
    if (_nodePath.isEmpty) {
      safePrint('⚠️ Node path not ready for animation, skipping');
      return;
    }
    
    // Determine starting position
    Offset fromPos;
    
    if (widget.fromCenter) {
      // 🏆 ZONE COMPLETION: Start from screen center
      final screenSize = MediaQuery.of(context).size;
      fromPos = Offset(screenSize.width / 2, screenSize.height / 2);
      safePrint('✈️ Animating jet from CENTER to first level of new zone');
    } else {
      // 🎮 NORMAL FLOW: Start from previous level
      if (widget.fromLevel == null || widget.toLevel == null) {
        return;
      }
      
      final fromLevel = widget.fromLevel!;
      
      // Get current zone levels to find the correct indices
      final currentZoneLevels = _levelSystemManager.allLevels
          .where((level) => level.zone == _levelSystemManager.currentZone)
          .toList();
      
      // Find index in the current zone's level list
      final fromIndex = currentZoneLevels.indexWhere((l) => l.id == fromLevel);
      
      if (fromIndex == -1 || fromIndex >= _nodePath.length) {
        safePrint('⚠️ From level not found in current zone for animation');
        return;
      }
      
      fromPos = _nodePath[fromIndex];
      safePrint('✈️ Animating jet from level $fromLevel (index $fromIndex)');
    }
    
    // Determine ending position
    final toLevel = widget.toLevel!;
    final currentZoneLevels = _levelSystemManager.allLevels
        .where((level) => level.zone == _levelSystemManager.currentZone)
        .toList();
    
    final toIndex = currentZoneLevels.indexWhere((l) => l.id == toLevel);
    
    if (toIndex == -1 || toIndex >= _nodePath.length) {
      safePrint('⚠️ To level not found in current zone for animation');
      return;
    }
    
    final toPos = _nodePath[toIndex];
    
    safePrint('✈️ Target: level $toLevel (index $toIndex)');
    
    // ✅ NEW: Detect jet direction based on X position
    final isMovingLeft = toPos.dx < fromPos.dx;
    
    // Block interactions during animation
    setState(() {
      _isAnimatingToNextLevel = true;
      _jetFacingLeft = isMovingLeft;
    });
    
    // Create animation controller
    _jetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 1.5 seconds
      vsync: this,
    );
    
    // Position animation (smooth movement)
    _jetPositionAnimation = Tween<Offset>(
      begin: fromPos,
      end: toPos,
    ).animate(CurvedAnimation(
      parent: _jetAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Scale animation (subtle grow/shrink for polish)
    _jetScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 50.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _jetAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start animation
    await _jetAnimationController!.forward();
    
    // Wait a moment after animation completes
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Auto-open next level preview
    if (mounted) {
      final nextLevel = _levelSystemManager.getLevelById(toLevel);
      if (nextLevel != null) {
        safePrint('🎯 Auto-opening preview for level $toLevel');
        _showLevelPreview(nextLevel);
      }
    }
    
    // Unblock interactions
    setState(() {
      _isAnimatingToNextLevel = false;
    });
  }
  
  /// ✅ NEW: Show level preview (used after jet animation)
  /// ✅ NEW: Shows Starter Boss Pack offer after level 5 preview opens
  Future<void> _showLevelPreview(LevelData level) async {
    // Show level preview dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelObjectivePopup(level: level),
    );
    
    // ✅ NEW: After level preview opens, show Starter Boss Pack offer if needed
    // Only show for level 5, and only if user doesn't have all skins and hasn't purchased
    // Use a small delay to ensure the preview dialog is fully rendered first
    if (level.id == 5 && mounted) {
      // Wait for the preview dialog to fully render
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _showStarterBossPackOfferIfNeeded();
      }
    }
  }
  
  /// ✅ NEW: Show Starter Boss Pack offer if conditions are met
  /// Checks if user has all 3 skins or already purchased, and shows popup if needed
  Future<void> _showStarterBossPackOfferIfNeeded() async {
    if (!mounted) return;
    
    try {
      // Check if user already purchased Starter Boss Pack
      final prefs = await SharedPreferences.getInstance();
      final hasPurchased = prefs.getBool('starter_boss_pack_purchased') ?? false;
      
      if (hasPurchased) {
        safePrint('⚔️ User already purchased Starter Boss Pack - skipping offer');
        return;
      }
      
      // Check if user already owns all Boss Pack jet skins
      const bossPackJetSkins = ['police_patrol', 'red_alert', 'green_lightning'];
      final inventoryManager = InventoryManager();
      final allSkinsOwned = bossPackJetSkins.every((skinId) => inventoryManager.isOwned(skinId));
      
      if (allSkinsOwned) {
        safePrint('⚔️ User already owns all Starter Boss Pack jet skins - skipping offer');
        return;
      }
      
      // Show the Starter Boss Pack offer popup
      safePrint('⚔️ Showing Starter Boss Pack offer after level 5 preview');
      await showStarterBossPackPopup(
        context: context,
        onPurchaseComplete: () {
          safePrint('⚔️ Starter Boss Pack purchased from level 5 offer');
          // Purchase handled - user can continue playing
        },
        onDismiss: () {
          safePrint('⚔️ Starter Boss Pack offer dismissed from level 5');
          // User dismissed - continue playing
        },
      );
    } catch (e) {
      safePrint('⚔️ ⚠️ Error showing Starter Boss Pack offer: $e');
      // Continue even if offer fails - don't block user progress
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A237E),
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    // ✅ FIXED: Always check zone on build to ensure we're on the correct zone
    // This handles the case where navigating back from a completed zone
    // Uses saved currentZone directly (not derived from currentLevel)
    if (_pageController != null && _pageController!.hasClients) {
      // ✅ FIXED: Use saved currentZone directly - it's the source of truth
      final playerCurrentZone = _levelSystemManager.currentZone;
      final allZones = _levelSystemManager.allZones;
      if (allZones.isNotEmpty) {
        final expectedPageIndex = (playerCurrentZone - 1).clamp(0, allZones.length - 1);
        
        // ✅ FIXED: Always check if we're on the wrong zone, regardless of check flag
        // This ensures we jump to the correct zone when navigating back
        if (_currentPageIndex != expectedPageIndex && _lastCheckedZone != playerCurrentZone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController != null && _pageController!.hasClients) {
              _pageController!.jumpToPage(expectedPageIndex);
              setState(() {
                _currentPageIndex = expectedPageIndex;
                _lastCheckedZone = playerCurrentZone;
                _hasCheckedZoneOnBuild = true;
              });
              _calculateNodePositionsForZone(playerCurrentZone);
            }
          });
        } else if (_currentPageIndex == expectedPageIndex) {
          // We're on the correct zone, just update tracking
          _lastCheckedZone = playerCurrentZone;
          _hasCheckedZoneOnBuild = true;
        }
      }
    }

    final allLevels = _levelSystemManager.allLevels;
    final screenSize = MediaQuery.sizeOf(context);
    
    // ✅ Calculate footer height (same as HomepageLayout)
    final footerHeight = screenSize.width * (391.0 / 1490.0); // Footer aspect ratio
    
    // ✅ FIXED: Account for system navigation bar (Xiaomi, Samsung, etc.)
    // Mobile Gaming Best Practice: Treat system UI as NOT part of active screen
    // Flame Best Practice: Use actual viewport size excluding system UI
    final totalBottomPadding = ResponsiveConfig.getTotalBottomPadding(context, footerHeight);
    final safeFooterBottom = ResponsiveConfig.getSafeFooterBottomPosition(context, footerHeight);

    // ✅ Home page - no back navigation needed
    return Scaffold(
        backgroundColor: Colors.transparent, // ✅ Transparent so background image shows through
        body: Stack(
          children: [
            // ✅ World map with bottom padding to respect footer + system navigation bar
            Padding(
              padding: EdgeInsets.only(bottom: totalBottomPadding),
              child: _buildWorldMapWithPageView(allLevels),
            ),
            
            // ✅ Top left: Balance (home page - no back button) - respect SafeArea top inset
            Positioned(
              top: MediaQuery.of(context).padding.top + ResponsiveConfig.responsivePadding(12.0, screenSize),
              left: ResponsiveConfig.responsivePadding(12.0, screenSize),
              child: CoinsGemsDisplay(),
            ),
            
            // ✅ Daily Streak Floating Banner - appears under balance when reward is available
            DailyStreakFloatingBanner(),
            
            // ✅ Missions & Achievements Claim Banner - appears below daily streak banner (or balance) when rewards are available
            MissionsAchievementsClaimBanner(),
            
            // ✅ Top right: Hearts display - respect SafeArea top inset
            Positioned(
              top: MediaQuery.of(context).padding.top + ResponsiveConfig.responsivePadding(12.0, screenSize),
              right: ResponsiveConfig.responsivePadding(12.0, screenSize),
              child: HeartsDisplay(),
            ),
            
            // ✅ Christmas Tournament Banner - appears at bottom left when tournament is available
            const ChristmasTournamentBanner(),
            
            // ✅ Banners removed - layout system still calculates exclusion zones for future use
            
            // ✅ Daily Streak Auto-Popup - shows automatically when reward is available
            DailyStreakHomepageIntegration(),
            
            // ✅ FIXED: Footer Navigator positioned above system navigation bar
            // This prevents overlap on devices with system navigation bars (Xiaomi, etc.)
            Positioned(
              bottom: safeFooterBottom, // Position above system navigation bar
              left: 0,
              right: 0,
              child: HomepageFooterNavigator(
                activeSection: FooterNavigatorSection.worldMap,
                onSectionTap: _handleFooterNavigation,
              ),
            ),
          ],
        ),
    );
  }
  
  /// Handle footer navigator section taps
  void _handleFooterNavigation(FooterNavigatorSection section) {
    switch (section) {
      case FooterNavigatorSection.store:
        _navigateToStore();
        break;
      case FooterNavigatorSection.tournaments:
        _navigateToTournaments();
        break;
      case FooterNavigatorSection.worldMap:
        // Already on world map, do nothing (or could show a subtle feedback)
        break;
      case FooterNavigatorSection.missions:
        _showMissionsScreen();
        break;
      case FooterNavigatorSection.profile:
        _navigateToProfile();
        break;
    }
  }
  
  /// Navigate to Store
  void _navigateToStore() {
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
  
  /// Navigate to Tournaments
  void _navigateToTournaments() {
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
  
  /// Navigate to Profile
  void _navigateToProfile() {
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

  // ✅ REMOVED: Banner rendering method
  // Layout system still calculates exclusion zones for future banner use
  // Banners can be added later without code changes - just add images and they'll be positioned correctly
  

  /// Build world map with PageView for zone swiping
  Widget _buildWorldMapWithPageView(List<LevelData> levels) {
    final allZones = _levelSystemManager.allZones;
    
    // ✅ FIXED: Ensure PageController is initialized before building PageView
    if (_pageController == null) {
      // Fallback: initialize with page 0 if somehow not initialized
      final fallbackPageIndex = (_levelSystemManager.currentZone - 1).clamp(0, allZones.length > 0 ? allZones.length - 1 : 0);
      _pageController = PageController(initialPage: fallbackPageIndex);
      _currentPageIndex = fallbackPageIndex;
    }
    
    return PageView.builder(
      controller: _pageController!,
      onPageChanged: _onPageChanged,
      itemCount: allZones.length,
      itemBuilder: (context, index) {
        final zoneId = index + 1; // Convert 0-indexed to 1-indexed
        return _buildWorldMapForZone(levels, zoneId);
      },
    );
  }

  /// Build world map for a specific zone
  Widget _buildWorldMapForZone(List<LevelData> levels, int zoneId) {
    // Get levels for this zone
    final zoneLevels = levels.where((level) => level.zone == zoneId).toList();
    
    // Check if zone exists but has no levels
    final zone = _levelSystemManager.getZoneById(zoneId);
    final hasLevels = zoneLevels.isNotEmpty;
    
    if (!hasLevels && zone != null) {
      return _buildEmptyZoneMessage();
    }
    
    // ✅ Map height: screen height minus footer and system navigation bar
    // Mobile Gaming Best Practice: Use active screen area (excluding system UI)
    final screenSize = MediaQuery.of(context).size;
    final footerHeight = screenSize.width * (391.0 / 1490.0); // Footer aspect ratio
    final systemNavBarHeight = ResponsiveConfig.getSystemNavigationBarHeight(context);
    final totalBottomPadding = footerHeight + systemNavBarHeight;
    final minMapHeight = screenSize.height - totalBottomPadding; // Content area above footer + system UI
    
    // Check if zone is unlocked
    final unlockedZones = _levelSystemManager.getUnlockedZones();
    final isZoneUnlocked = unlockedZones.contains(zoneId);
    
    // ✅ NEW: Use layout system to get padding and exclusion zones
    final layout = WorldMapLayout(screenSize);
    final topOverlayHeight = layout.getTopPadding();
    final bottomOverlayHeight = layout.getBottomPadding();
    final exclusionZones = layout.getExclusionZones();
    
    // ✅ FIXED: Pass actual content height to calculator
    // The calculator now expects screenSize.height to be the full screen,
    // but it will calculate content height internally (screen - footer)
    // Calculate node positions for this zone (respecting exclusion zones)
    final nodePath = zoneLevels.isEmpty
        ? <Offset>[]
        : WorldMapPathCalculator.calculateZonePath(
            zoneId: zoneId,
            levelCount: zoneLevels.length,
            screenSize: screenSize, // Full screen size - calculator handles content height
            topPadding: topOverlayHeight,
            bottomPadding: bottomOverlayHeight,
            exclusionZones: exclusionZones, // ✅ NEW: Avoid UI element areas
          );
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ✅ Background image - full screen, extends behind status bar
        Positioned.fill(
          child: Image.asset(
            'assets/images/backgrounds/world_map_zone$zoneId.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1A237E),
                child: Center(
                  child: Icon(
                    Icons.map,
                    size: ResponsiveConfig.responsiveIconSize(100.0, screenSize),
                    color: Colors.white24,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Content with fixed layout (no vertical scrolling - nodes should not move)
        SafeArea(
          bottom: false, // ✅ Don't apply bottom insets - footer should be at screen bottom
          child: SizedBox(
            height: minMapHeight, // ✅ Fixed: Use explicit height instead of minHeight to avoid infinite constraints
            width: screenSize.width,
            child: Stack(
                children: [
                
                // Animated path between nodes (only for unlocked zones)
                if (nodePath.isNotEmpty && isZoneUnlocked)
                  CustomPaint(
                    size: Size(screenSize.width, minMapHeight),
                    painter: WorldMapPathPainter(
                      nodePositions: nodePath,
                      completedUpTo: _levelSystemManager.totalLevelsCompleted,
                      pathColor: const Color(0xFF42A5F5),
                      completedPathColor: const Color(0xFF66BB6A),
                      pathWidth: 8.0,
                      showDots: true,
                    ),
                  ),
                
                // Level nodes overlay
                ...nodePath.asMap().entries.map((entry) {
                  final index = entry.key;
                  final position = entry.value;
                  final level = zoneLevels[index];
                  // For locked zones, all nodes are locked
                  final isLevelUnlocked = isZoneUnlocked && _levelSystemManager.isLevelUnlocked(level.id);
                  return _buildLevelNodeForZone(level, position, isLevelUnlocked, zoneId == _levelSystemManager.currentZone);
                }),
                
                // ✅ FIXED: Animated jet sprite (only for current zone)
                if (nodePath.isNotEmpty && zoneId == _levelSystemManager.currentZone)
                  _buildAnimatedJetForZone(nodePath, zoneLevels, zoneId),
              ],
            ),
          ),
        ), // ✅ Closes SafeArea
      ],
    );
  }

  // ✅ REMOVED: Legacy _showTournamentsScreen method (unused - navigation handled by _navigateToTournaments)
  
  /// ✅ NEW: Show missions screen (full screen navigation with footer)
  void _showMissionsScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomepageLayout(
          activeSection: FooterNavigatorSection.missions,
          child: DailyMissionsScreen(
            missionsManager: MissionsManager(),
            achievementsManager: AchievementsManager(),
          ),
        ),
      ),
    );
  }

  /// Build animated jet for a specific zone
  Widget _buildAnimatedJetForZone(List<Offset> nodePath, List<LevelData> zoneLevels, int zoneId) {
    // If animating to next level, use AnimatedBuilder
    if (_jetAnimationController != null && _jetPositionAnimation != null && zoneId == _levelSystemManager.currentZone) {
      return AnimatedBuilder(
        animation: _jetAnimationController!,
        builder: (context, child) {
          final currentPos = _jetPositionAnimation!.value;
          final scale = _jetScaleAnimation?.value ?? 1.0;
          
          final screenSize = MediaQuery.sizeOf(context);
          final jetSize = ResponsiveConfig.responsiveSize(70.0, screenSize);
          return Positioned(
            left: currentPos.dx - (jetSize / 2),
            top: currentPos.dy - (jetSize + 15),  // Position jet closer to the node
            child: SizedBox(
              width: jetSize,
              height: jetSize,
              child: Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(_jetFacingLeft ? -1.0 : 1.0, 1.0),
                  child: WorldMapJetWidget(
                    jetSkinId: _inventoryManager.equippedSkinId,
                    currentPosition: currentPos,
                    targetPosition: null,
                    animationDuration: Duration.zero,
                    onAnimationComplete: () {},
                    jetSize: jetSize,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    
    // Static position for current level in this zone
    Offset staticPosition = _getCurrentJetPositionForZone(nodePath, zoneLevels, zoneId);
    
    final screenSize = MediaQuery.sizeOf(context);
    final jetSize = ResponsiveConfig.responsiveSize(70.0, screenSize);
    return Positioned(
      left: staticPosition.dx - (jetSize / 2),
      top: staticPosition.dy - (jetSize + 15),  // Position jet closer to the node
      child: SizedBox(
        width: jetSize,
        height: jetSize,
        child: WorldMapJetWidget(
          jetSkinId: _inventoryManager.equippedSkinId,
          currentPosition: staticPosition,
          targetPosition: null,
          animationDuration: Duration.zero,
          onAnimationComplete: () {},
          jetSize: jetSize,
        ),
      ),
    );
  }

  /// Get current jet position for a specific zone
  Offset _getCurrentJetPositionForZone(List<Offset> nodePath, List<LevelData> zoneLevels, int zoneId) {
    if (nodePath.isEmpty || zoneLevels.isEmpty) return Offset.zero;
    
    // Find current level in this zone
    final currentLevel = _levelSystemManager.currentLevel;
    final currentLevelIndex = zoneLevels.indexWhere((level) => level.id == currentLevel);
    
    if (currentLevelIndex != -1 && currentLevelIndex < nodePath.length && zoneId == _levelSystemManager.currentZone) {
      return nodePath[currentLevelIndex];
    }
    
    // Default to first node if current level not in this zone
    return nodePath.first;
  }

  /// Build level node for a specific zone (supports locked zones)
  Widget _buildLevelNodeForZone(LevelData level, Offset position, bool isUnlocked, bool isCurrentZone) {
    final isCompleted = _levelSystemManager.isLevelCompleted(level.id);
    final isCurrent = level.id == _levelSystemManager.currentLevel && isCurrentZone;
    final isBotBattle = level.botBattle != null;

    // VS nodes are larger and have special styling
    final nodeSize = isBotBattle ? 85.0 : 60.0;
    final nodeOffset = nodeSize / 2;

    return Positioned(
      left: position.dx - nodeOffset,
      top: position.dy - nodeOffset,
      child: GestureDetector(
        onTap: isUnlocked ? () => _onLevelTap(level) : null,
        child: _HexagonalLevelNode(
          isUnlocked: isUnlocked,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isBotBattle: isBotBattle,
          nodeSize: nodeSize,
          child: _buildLevelNumber(level),
        ),
      ),
    );
  }

  
  Widget _buildLevelNumber(LevelData level) {
    // For all nodes, just show the level number centered
    final screenSize = MediaQuery.sizeOf(context);
    return Text(
      '${level.id}',
      style: TextStyle(
        color: Colors.white,
        fontSize: ResponsiveConfig.responsiveFontSize(32.0, screenSize, context),
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black54,
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyZoneMessage() {
    final screenSize = MediaQuery.sizeOf(context);
    final isZone1Completed = _levelSystemManager.isZoneCompleted(1);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isZone1Completed ? Icons.emoji_events : Icons.lock,
            size: ResponsiveConfig.responsiveIconSize(100.0, screenSize),
            color: isZone1Completed ? Colors.amber : Colors.white54,
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),
          Text(
            isZone1Completed ? '🎉 Zone 1 Completed! 🎉' : 'Zone ${_levelSystemManager.currentZone}',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveConfig.responsiveFontSize(32.0, screenSize, context),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          Text(
            isZone1Completed 
                ? 'New zones coming soon!\nStay tuned for more adventures!'
                : 'Coming Soon',
            style: TextStyle(
              color: Colors.white70,
              fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
            ),
            textAlign: TextAlign.center,
          ),
          if (isZone1Completed) ...[
            SizedBox(height: ResponsiveConfig.responsivePadding(40.0, screenSize)),
            ModernGameButton(
              label: 'BACK TO HOME',
              onPressed: () {
                // ✅ Navigate back to tab navigation (story tab)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              height: ResponsiveConfig.responsiveButtonHeight(56.0, screenSize),
              style: ModernButtonStyle.secondary, // Secondary blue
            ),
          ],
        ],
      ),
    );
  }

  void _onLevelTap(LevelData level) async {
    // Prevent tapping during jet animation
    if (_isJetAnimating || _isAnimatingToNextLevel) {
      safePrint('🚫 Cannot tap level during jet animation');
      return;
    }
    
    // Always ensure hearts are available — no waiting popup, just refill
    if (_livesManager.currentLives <= 0) {
      await _livesManager.refillToMax();
      if (!mounted) return;
    }

    // 📺 Check for loss streak ad before starting game
    final adShown = await InterstitialAdManager().showLossStreakAdIfNeeded(
      onAdClosed: () {
        if (!mounted) return;
        // Continue to level after ad is closed
        _proceedToLevel(level);
      },
    );
    
    // If no ad was shown, proceed immediately
    if (!adShown) {
      await _proceedToLevel(level);
    }
  }
  
  /// Helper method to proceed to level (after potential ad)
  Future<void> _proceedToLevel(LevelData level) async {
    // 🎮 TUTORIAL: Always show tutorial before Level 1 (repeatable for practice)
    if (level.id == 1) {
      safePrint('🎮 Tutorial: Showing before Level 1');
      await FTUEIntegration.showTutorialAnimation(context);
      
      // After tutorial completes, check if we're still mounted
      if (!mounted) {
        safePrint('🎮 Tutorial: Widget unmounted after tutorial, aborting level start');
        return;
      }
      safePrint('🎮 Tutorial: Complete, continuing to level objective popup');
    }

    // Show level objective popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelObjectivePopup(level: level),
    );
    
    // ✅ NEW: Show Starter Boss Pack offer after level 5 preview opens (manual tap)
    if (level.id == 5) {
      // Wait for the preview dialog to fully render
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _showStarterBossPackOfferIfNeeded();
      }
    }
  }

}

/// 🎨 MODERN LEVEL NODE WIDGET
/// 
/// A visually stunning node inspired by blockbuster mobile games like
/// Candy Crush, Clash of Clans, and similar titles.
/// Features layered depth, animations, and modern design patterns.
/// 🎨 Modern Hexagonal Level Node with 3D depth
/// Inspired by modern mobile games like Candy Crush and Brawl Stars
class _HexagonalLevelNode extends StatefulWidget {
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBotBattle;
  final double nodeSize;
  final Widget child;

  const _HexagonalLevelNode({
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    required this.isBotBattle,
    required this.nodeSize,
    required this.child,
  });

  @override
  State<_HexagonalLevelNode> createState() => _HexagonalLevelNodeState();
}

class _HexagonalLevelNodeState extends State<_HexagonalLevelNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000), // ✅ Faster for more attention
      vsync: this,
    );

    // ✅ ENHANCED: Much bigger pulse (1.0 -> 1.3) to make current level VERY obvious
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation for current level
    if (widget.isCurrent) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_HexagonalLevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !oldWidget.isCurrent) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCurrent ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: widget.nodeSize,
            height: widget.nodeSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🔥 SPECIAL: Epic glow for VS Battle nodes (always visible)
                if (widget.isBotBattle)
                  CustomPaint(
                    size: Size(widget.nodeSize + 20, widget.nodeSize + 20),
                    painter: _HexagonGlowPainter(
                      color: Colors.red.withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                  ),
                
                // 🔥 SPECIAL: Second glow layer for VS nodes (animated)
                if (widget.isBotBattle)
                  CustomPaint(
                    size: Size(widget.nodeSize + 30, widget.nodeSize + 30),
                    painter: _HexagonGlowPainter(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 25,
                    ),
                  ),
                
                // Outer glow for current level
                if (widget.isCurrent && !widget.isBotBattle)
                  CustomPaint(
                    size: Size(widget.nodeSize + 10, widget.nodeSize + 10),
                    painter: _HexagonGlowPainter(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ),

                // Main hexagonal badge with 3D depth
                CustomPaint(
                  size: Size(widget.nodeSize, widget.nodeSize),
                  painter: _HexagonBadgePainter(
                    isUnlocked: widget.isUnlocked,
                    isCompleted: widget.isCompleted,
                    isCurrent: widget.isCurrent,
                    isBotBattle: widget.isBotBattle,
                  ),
                ),

                // Content
                widget.child,

                // Lock icon for locked levels
                if (!widget.isUnlocked)
                  Container(
                    width: widget.nodeSize * 0.45, // 45% of node size
                    height: widget.nodeSize * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4), // Gold border
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.9), // Gold lock
                      size: widget.nodeSize * 0.28,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                // 🔥 SPECIAL: VS Badge at the bottom for battle nodes
                // ✅ FIX: Wrap in Align instead of Positioned to avoid ParentDataWidget errors
                if (widget.isBotBattle)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade900],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.yellow.shade600, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                          const BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.yellow.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          height: 1.0,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
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


/// 🎨 CustomPainter for hexagonal badge with 3D depth
class _HexagonBadgePainter extends CustomPainter {
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBotBattle;

  _HexagonBadgePainter({
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    this.isBotBattle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    // Get colors based on state
    final colors = _getColors();
    
    // Draw shadow (bottom hexagon, slightly offset)
    final shadowPath = _createHexagonPath(center + const Offset(0, 3), radius);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw main hexagon with gradient
    final hexPath = _createHexagonPath(center, radius);
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(hexPath, gradientPaint);

    // Draw inner border (lighter)
    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: isUnlocked ? 0.3 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final innerPath = _createHexagonPath(center, radius - 3);
    canvas.drawPath(innerPath, innerBorderPaint);

    // Draw outer border
    final borderColor = _getBorderColor();
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCurrent ? 3 : 2;
    canvas.drawPath(hexPath, borderPaint);

    // Add glossy top shine
    final shinePath = Path()
      ..moveTo(center.dx - radius * 0.6, center.dy - radius * 0.7)
      ..lineTo(center.dx + radius * 0.6, center.dy - radius * 0.7)
      ..lineTo(center.dx + radius * 0.4, center.dy - radius * 0.3)
      ..lineTo(center.dx - radius * 0.4, center.dy - radius * 0.3)
      ..close();
    
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.5 : 0.2),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(shinePath, shinePaint);
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * 3.14159 / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  List<Color> _getColors() {
    // 🔥 SPECIAL: Completed VS Battle nodes get emerald green (champion color)
    if (isBotBattle && isCompleted) {
      return const [
        Color(0xFF00C853), // Bright emerald green top
        Color(0xFF00695C), // Deep teal green bottom
      ];
    }
    
    // 🔥 SPECIAL: VS Battle nodes get epic red/orange gradient
    if (isBotBattle && isUnlocked) {
      return const [
        Color(0xFFFF1744), // Bright red top
        Color(0xFFD50000), // Deep red bottom
      ];
    }
    
    if (!isUnlocked) {
      return const [
        Color(0xFF757575), // Gray top
        Color(0xFF424242), // Dark gray bottom
      ];
    }

    if (isCompleted) {
      return const [
        Color(0xFF66BB6A), // Green top
        Color(0xFF2E7D32), // Dark green bottom
      ];
    }

    if (isCurrent) {
      return const [
        Color(0xFFFFD600), // Gold top
        Color(0xFFFF6F00), // Orange bottom
      ];
    }

    // Unlocked
    return const [
      Color(0xFF42A5F5), // Blue top
      Color(0xFF1976D2), // Dark blue bottom
    ];
  }

  Color _getBorderColor() {
    // 🔥 SPECIAL: Completed VS battles get gold border (champion)
    if (isBotBattle && isCompleted) return const Color(0xFFFFD700); // Gold
    
    // 🔥 SPECIAL: VS Battle nodes get golden border
    if (isBotBattle && isUnlocked) return const Color(0xFFFFD700); // Gold
    
    if (!isUnlocked) return const Color(0xFF616161);
    if (isCurrent) return const Color(0xFFFFEB3B);
    if (isCompleted) return const Color(0xFF81C784);
    return const Color(0xFF64B5F6);
  }

  @override
  bool shouldRepaint(_HexagonBadgePainter oldDelegate) =>
      isUnlocked != oldDelegate.isUnlocked ||
      isCompleted != oldDelegate.isCompleted ||
      isCurrent != oldDelegate.isCurrent ||
      isBotBattle != oldDelegate.isBotBattle;
}

/// 🎨 CustomPainter for glow effect around hexagon
class _HexagonGlowPainter extends CustomPainter {
  final Color color;
  final double blurRadius;

  _HexagonGlowPainter({
    required this.color,
    required this.blurRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * 3.14159 / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexagonGlowPainter oldDelegate) =>
      color != oldDelegate.color || blurRadius != oldDelegate.blurRadius;
}

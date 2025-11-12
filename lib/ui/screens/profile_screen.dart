/// 👤 Profile Screen - Clean, modular, and responsive design
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../../game/systems/player_identity_manager.dart';
import '../../game/systems/profile_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/game_events_tracker.dart';
import '../../game/core/jet_skins.dart';
import '../../game/core/economy_config.dart';
import '../widgets/profile/profile_component_system.dart';
import '../../game/systems/audio_settings_manager.dart';
import '../widgets/gem_3d_icon.dart';
import '../widgets/settings_toggle_buttons.dart';
import '../widgets/notification_analytics_dashboard.dart';
import 'store_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();
  final ProfileManager _profile = ProfileManager();
  // Use singleton instance (initialized in main.dart)
  final InventoryManager _inventory = InventoryManager();
  final AudioSettingsManager _audioSettings = AudioSettingsManager();
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    safePrint('🏗️ ProfileScreen initState() started');
    _profile.addListener(_refresh);
    _inventory.addListener(_refresh);
    _playerIdentity.addListener(
      _refresh,
    ); // Listen to PlayerIdentityManager changes
    _audioSettings.addListener(_refresh); // Listen to audio settings changes

    // Initialize audio settings (already initialized in main.dart, but ensure it's ready)
    _audioSettings.initialize();

    // 🚀 PERFORMANCE FIX: Run initialization asynchronously without blocking main thread
    _initializeAsync();
  }

  /// 🚀 PERFORMANCE: Async initialization that doesn't block the main thread
  Future<void> _initializeAsync() async {
    safePrint('🏗️ ProfileScreen async initialization started');

    // Run heavy operations in background
    await Future.microtask(() async {
      // Ensure dynamic catalog is loaded the first time Profile opens
      await JetSkinCatalog.initializeFromAssets();
      safePrint('🏗️ ProfileScreen JetSkinCatalog initialized');
      await _profile.initialize();
      safePrint('🏗️ ProfileScreen ProfileManager initialized');
      // InventoryManager is already initialized in main.dart
      safePrint('🏗️ ProfileScreen InventoryManager initialized');
    });

    if (mounted) {
      _nameCtrl.text = _playerIdentity.playerName.isNotEmpty
          ? _playerIdentity.playerName
          : _profile.nickname;
      safePrint('🏗️ ProfileScreen initialization complete, calling setState');
      setState(() {});
    }
  }

  @override
  void dispose() {
    _profile.removeListener(_refresh);
    _inventory.removeListener(_refresh);
    _playerIdentity.removeListener(
      _refresh,
    ); // Remove PlayerIdentityManager listener
    _audioSettings.removeListener(_refresh); // Remove audio settings listener
    _nameCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      // Update the text controller with the latest name
      _nameCtrl.text = _playerIdentity.playerName.isNotEmpty
          ? _playerIdentity.playerName
          : _profile.nickname;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    safePrint('🏗️ ProfileScreen build() called');
    final equippedSkin =
        JetSkinCatalog.getSkinById(_inventory.equippedSkinId) ??
        JetSkinCatalog.starterJet;
    safePrint('🏗️ ProfileScreen equippedSkin: ${equippedSkin.displayName}');

    return WillPopScope(
      onWillPop: () async => false, // Disable back button for bottom nav screen
      child: Scaffold(
      body: Stack(
        children: [
          // 1. Background Image Component
          const ProfileBackgroundComponent(),

          // 2. ✅ REDESIGNED: Nickname Banner - Full width at top (RED SQUARE AREA)
          Positioned(
            top: 50, // Top position
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ProfileNicknameBannerComponent(
                controller: _nameCtrl,
                onSave: _handleNicknameSave,
                alignment: Alignment.center,
                width: null, // Full width
                height: 200, // Compact height for banner
              ),
            ),
          ),

          // 3. ✅ REDESIGNED: High Score & Hottest Streak - Side by side (BLUE SQUARE AREA)
          Positioned(
            top: 280, // Below nickname banner
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // High Score (Left)
                Expanded(
                  child: ProfileHighScoreComponent(
                    alignment: Alignment.center,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Hottest Streak (Right)
                Expanded(
                  child: ProfileHottestStreakComponent(
                    alignment: Alignment.center,
                  ),
                ),
              ],
            ),
          ),

          // 4. ✅ REDESIGNED: Jet Section - Centered below stats (GREEN SQUARE AREA)
          LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenHeight < 700;
              final isVerySmallScreen = screenHeight < 600;
              
              return Align(
                alignment: Alignment(
                  0,
                  isVerySmallScreen ? 0.4 : isSmallScreen ? 0.45 : 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Jet Image
                    SizedBox(
                      height: isVerySmallScreen ? 100 : isSmallScreen ? 120 : 140,
                      child: Image.asset(
                        'assets/images/${equippedSkin.assetPath}',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.flight,
                            size: isVerySmallScreen ? 90 : isSmallScreen ? 110 : 130,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(height: isVerySmallScreen ? 8 : 10),
                    
                    // Jet Name
                    Text(
                      equippedSkin.displayName,
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 18 : isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade300,
                        shadows: const [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 14 : 16),
                    
                    // Choose Jet Button
                    ProfileActionButtonComponent(
                      onPressed: _openOwnedJetsSheet,
                      alignment: Alignment.center,
                      width: isSmallScreen ? screenWidth * 0.75 : screenWidth * 0.8,
                      height: isVerySmallScreen ? 70 : isSmallScreen ? 80 : 90,
                      text: '',
                    ),
                  ],
                ),
              );
            },
          ),


          // 7. Settings Toggle Buttons - Footer position with safe spacing
          Positioned(
            bottom: 20, // Fixed bottom position as footer
            left: 0,
            right: 0,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final isSmallScreen = screenHeight < 700;
                  final isVerySmallScreen = screenHeight < 600;
                  
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16, 
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      decoration: BoxDecoration(
                        // Premium footer design
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main settings toggles
                          SettingsToggleButtonsRow(
                            buttonSize: isVerySmallScreen ? 16.0 : isSmallScreen ? 18.0 : 20.0,
                            spacing: isVerySmallScreen ? 12.0 : isSmallScreen ? 14.0 : 16.0,
                          ),
                          
                          // Debug notification analytics (only in debug mode)
                          if (kDebugMode) ...[
                            SizedBox(height: isVerySmallScreen ? 8 : 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationAnalyticsDashboard(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.analytics, size: 16),
                                label: const Text(
                                  'Notification Analytics (DEBUG)',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                                  foregroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(0, 32),
                                ),
                              ),
                            ),
                          ],
                          
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Back Button Component removed - this is a bottom nav screen
        ],
      ),
      ),
    );
  }

  /// Handle nickname save with proper error handling and feedback
  Future<void> _handleNicknameSave() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Saving nickname...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _playerIdentity.updatePlayerName(_nameCtrl.text);
      
      // Force immediate backend sync for tournaments
      final syncSuccess = await _playerIdentity.forceNicknameSyncToBackend();
      
      if (!mounted) return;
      
      // Clear any existing snackbars
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (syncSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Nickname saved and synced! ✅')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Nickname saved locally. Tournament sync pending...'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to save nickname: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _openOwnedJetsSheet() {
    final all = JetSkinCatalog.getAllSkins();
    final owned = _inventory.ownedSkinIds;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'YOUR JETS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final skin = all[i];
                    final isOwned =
                        owned.contains(skin.id) || skin.id == 'sky_rookie';
                    return _OwnedJetCell(
                      skin: skin,
                      owned: isOwned,
                      equipped: _inventory.equippedSkinId == skin.id,
                      onTap: () async {
                        if (!isOwned) {
                          final ok = await _promptPurchase(skin);
                          if (!ok) return;
                        }
                        final equipped = await _inventory.equipSkin(skin.id);
                        if (!mounted) return;
                        if (equipped) Navigator.pop(context);
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _promptPurchase(JetSkin skin) async {
    final economy = EconomyConfig();
    final isGemExclusive = skin.isGemExclusive;
    final coinPrice = economy.getSkinCoinPrice(skin);
    final gemPrice = economy.getSkinGemPrice(skin);

    if (isGemExclusive) {
      return await _promptGemPurchase(skin, gemPrice);
    } else {
      return await _promptCoinPurchase(skin, coinPrice);
    }
  }

  /// Purchase dialog for coin-based skins
  Future<bool> _promptCoinPurchase(JetSkin skin, int price) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Purchase ${skin.displayName}?'),
          content: Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
              const SizedBox(width: 8),
              Text('$price coins'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success = await _inventory.spendSoftCurrency(price);
                if (success) {
                  await _inventory.unlockSkin(skin.id);
                  await _inventory.equipSkin(skin.id);

                  // 🏆 Track jet purchase for collection achievements
                  final gameEvents = GameEventsTracker();
                  await gameEvents.onSkinPurchased(
                    skinId: skin.id,
                    coinCost: price,
                    rarity: skin.rarity.name,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Purchased ${skin.displayName}')),
                  );
                  Navigator.pop(context, true);
                } else {
                  if (!mounted) return;
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough coins')),
                  );
                }
              },
              child: const Text('Buy'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Purchase dialog for gem-exclusive mythic skins
  Future<bool> _promptGemPurchase(JetSkin skin, int gemPrice) async {
    // Check if player has enough gems
    if (_inventory.gems < gemPrice) {
      return await _showInsufficientGemsDialog(skin, gemPrice);
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Purchase ${skin.displayName}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Gem3DIcon(size: 20),
                  const SizedBox(width: 8),
                  Text('$gemPrice gems'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '✨ ${skin.description}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success = await _inventory.spendGems(gemPrice);
                if (success) {
                  await _inventory.unlockSkin(skin.id);
                  await _inventory.equipSkin(skin.id);

                  // 🏆 Track mythic jet purchase for collection achievements
                  final gameEvents = GameEventsTracker();
                  await gameEvents.onSkinPurchased(
                    skinId: skin.id,
                    coinCost: 0, // No coins spent
                    rarity: skin.rarity.name,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '🎉 Purchased exclusive ${skin.displayName}!',
                      ),
                    ),
                  );
                  Navigator.pop(context, true);
                } else {
                  if (!mounted) return;
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('💎 Not enough gems!')),
                  );
                }
              },
              child: const Text('Buy'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }


  /// Show insufficient gems dialog with "Get Gems" button
  Future<bool> _showInsufficientGemsDialog(JetSkin skin, int gemPrice) async {
    final currentGems = _inventory.gems;
    final neededGems = gemPrice - currentGems;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Not Enough Gems'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Gem3DIcon(size: 20),
                  const SizedBox(width: 8),
                  Text('Need $gemPrice gems'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You have $currentGems gems.\nYou need $neededGems more gems to purchase ${skin.displayName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, false);
                // Navigate to store gems section
                _navigateToGemsStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Get Gems'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Navigate to store and select gems section
  void _navigateToGemsStore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoreScreen(initialCategory: 'Gems'),
      ),
    );
  }

}

class _OwnedJetCell extends StatelessWidget {
  final JetSkin skin;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;
  const _OwnedJetCell({
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: owned ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  'assets/images/${skin.assetPath}',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.flight),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skin.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

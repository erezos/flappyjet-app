/// 🎮 Profile Screen V2 - Modern Flutter Game UI Architecture
/// 
/// This screen demonstrates the new modular component system where:
/// - Each component can be positioned independently
/// - Components are responsive and adaptive
/// - Easy to move, resize, or restyle individual elements
/// - No more rigid Column layout constraints
/// - True separation of concerns

import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../../game/systems/player_identity_manager.dart';
import 'profile_component_system.dart';

class ProfileScreenV2 extends StatefulWidget {
  const ProfileScreenV2({super.key});

  @override
  State<ProfileScreenV2> createState() => _ProfileScreenV2State();
}

class _ProfileScreenV2State extends State<ProfileScreenV2> {
  late TextEditingController _nicknameController;
  late JetSkin _equippedSkin;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize nickname controller
    final playerName = PlayerIdentityManager().currentPlayerName;
    _nicknameController = TextEditingController(text: playerName);
    
    // Get equipped jet skin
    final inventory = InventoryManager();
    final equippedJetId = inventory.equippedJetSkin;
    _equippedSkin = JetSkinCatalog.getSkin(equippedJetId);
    
    // Listen to player name changes
    PlayerIdentityManager().addListener(_onPlayerNameChanged);
  }

  void _onPlayerNameChanged() {
    if (mounted) {
      final newName = PlayerIdentityManager().currentPlayerName;
      if (_nicknameController.text != newName) {
        _nicknameController.text = newName;
      }
    }
  }

  @override
  void dispose() {
    PlayerIdentityManager().removeListener(_onPlayerNameChanged);
    _nicknameController.dispose();
    super.dispose();
  }

  void _saveNickname() {
    final newName = _nicknameController.text.trim();
    if (newName.isNotEmpty && newName != PlayerIdentityManager().currentPlayerName) {
      PlayerIdentityManager().updatePlayerName(newName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nickname updated to: $newName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToJetSelection() {
    Navigator.of(context).pushNamed('/jet_selection').then((_) {
      // Refresh equipped skin when returning from jet selection
      if (mounted) {
        setState(() {
          final inventory = InventoryManager();
          final equippedJetId = inventory.equippedJetSkin;
          _equippedSkin = JetSkinCatalog.getSkin(equippedJetId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image Component
          const ProfileBackgroundComponent(),
          
          // 2. Title Text Component
          const ProfileTitleComponent(
            alignment: Alignment(0, -0.85), // Positioned at top
          ),
          
          // 3. Nickname Banner Component (image+text)
          ProfileNicknameBannerComponent(
            controller: _nicknameController,
            onSave: _saveNickname,
            alignment: const Alignment(0, -0.5), // Just below title
            height: 100, // Fixed height to prevent jet clipping
          ),
          
          // 4. High Score Widget Component (image+text)
          const ProfileHighScoreComponent(
            alignment: Alignment(-0.35, -0.1), // Left side, center vertically
          ),
          
          // 5. Hottest Streak Widget Component (image+text)
          const ProfileHottestStreakComponent(
            alignment: Alignment(0.35, -0.1), // Right side, center vertically
          ),
          
          // 6. Jet Preview Widget Component (image+text)
          ProfileJetPreviewComponent(
            equippedSkin: _equippedSkin,
            alignment: const Alignment(0, 0.35), // Lower center
          ),
          
          // 7. Action Button Component
          ProfileActionButtonComponent(
            onPressed: _navigateToJetSelection,
            alignment: const Alignment(0, 0.75), // Bottom center
          ),
          
          // Back Button Component (overlay)
          const ProfileBackButtonComponent(),
        ],
      ),
    );
  }
}

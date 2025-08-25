/// 👤 Profile Screen - Clean, modular, and responsive design
import 'package:flutter/material.dart';
import '../../game/systems/player_identity_manager.dart';
import '../../game/systems/profile_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/core/jet_skins.dart';
import '../../game/core/economy_config.dart';
import '../widgets/profile/profile_component_system.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();
  final ProfileManager _profile = ProfileManager();
  final InventoryManager _inventory = InventoryManager();
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🏗️ ProfileScreen initState() started');
    _profile.addListener(_refresh);
    _inventory.addListener(_refresh);
    _playerIdentity.addListener(_refresh); // Listen to PlayerIdentityManager changes
    () async {
      print('🏗️ ProfileScreen async initialization started');
      // Ensure dynamic catalog is loaded the first time Profile opens
      await JetSkinCatalog.initializeFromAssets();
      print('🏗️ ProfileScreen JetSkinCatalog initialized');
      await _profile.initialize();
      print('🏗️ ProfileScreen ProfileManager initialized');
      await _inventory.initialize();
      print('🏗️ ProfileScreen InventoryManager initialized');
      if (mounted) {
        _nameCtrl.text = _playerIdentity.playerName.isNotEmpty ? _playerIdentity.playerName : _profile.nickname;
        print('🏗️ ProfileScreen initialization complete, calling setState');
        setState(() {});
      }
    }();
  }

  @override
  void dispose() {
    _profile.removeListener(_refresh);
    _inventory.removeListener(_refresh);
    _playerIdentity.removeListener(_refresh); // Remove PlayerIdentityManager listener
    _nameCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      // Update the text controller with the latest name
      _nameCtrl.text = _playerIdentity.playerName.isNotEmpty ? _playerIdentity.playerName : _profile.nickname;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ ProfileScreen build() called');
    final equippedSkin = JetSkinCatalog.getSkinById(_inventory.equippedSkinId) ?? JetSkinCatalog.starterJet;
    print('🏗️ ProfileScreen equippedSkin: ${equippedSkin.displayName}');
    
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image Component
          const ProfileBackgroundComponent(),
          
          // 2. Nickname Banner Component (image+text) - NOW THE MAIN HEADER
          ProfileNicknameBannerComponent(
            controller: _nameCtrl,
            onSave: _handleNicknameSave,
            alignment: const Alignment(0, -0.75), // Header position at top
            width: 450, // Even wider for more prominence
            height: 220, // Even taller for bigger header
          ),
          
          // 4. High Score Widget Component (image+text) - Higher position below name
          const ProfileHighScoreComponent(
            alignment: Alignment(-0.55, -0.25), // Much higher, just below name widget
          ),
          
          // 5. Hottest Streak Widget Component (image+text) - Higher position below name
          const ProfileHottestStreakComponent(
            alignment: Alignment(0.55, -0.25), // Much higher, just below name widget
          ),
          
          // 6. Jet Preview Widget Component (image+text)
          ProfileJetPreviewComponent(
            equippedSkin: equippedSkin,
            alignment: const Alignment(0, 0.35), // Lower center
          ),
          
          // 7. Action Button Component - Footer position
          ProfileActionButtonComponent(
            onPressed: _openOwnedJetsSheet,
            alignment: const Alignment(0, 0.9), // Much lower - footer position
            text: '', // Empty text since the button image contains the text
          ),
          
          // Back Button Component (overlay)
          const ProfileBackButtonComponent(),
        ],
      ),
    );
  }

  /// Handle nickname save with proper error handling and feedback
  Future<void> _handleNicknameSave() async {
    try {
      await _playerIdentity.updatePlayerName(_nameCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save nickname: $e')),
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              const Text('YOUR JETS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final skin = all[i];
                    final isOwned = owned.contains(skin.id) || skin.price == 0;
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
    final price = _priceForSkin(skin);
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
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final success = await _inventory.spendSoftCurrency(price);
                if (success) {
                  await _inventory.unlockSkin(skin.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchased ${skin.displayName}')));
                  Navigator.pop(context, true);
                } else {
                  if (!mounted) return;
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins')));
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

  int _priceForSkin(JetSkin skin) {
    // 🔧 CRITICAL FIX: Use centralized EconomyConfig to prevent pricing exploits
    return EconomyConfig().getSkinCoinPrice(skin);
  }

}



class _OwnedJetCell extends StatelessWidget {
  final JetSkin skin;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;
  const _OwnedJetCell({required this.skin, required this.owned, required this.equipped, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: owned ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: equipped ? Colors.green : Colors.transparent, width: 2),
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

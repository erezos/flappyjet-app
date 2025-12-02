/// 🛒 Store Bottom Sheet - Swipeable store popup for World Map
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/core/jet_skins.dart';
import '../../game/core/economy_config.dart';
import '../../game/systems/inventory_manager.dart';
import '../../game/systems/monetization_manager.dart';
import '../../game/systems/lives_manager.dart';
import '../widgets/store/store_header.dart';
import '../widgets/store/store_navigation.dart';
import '../widgets/store/jets_store.dart';
import '../widgets/store/gems_store.dart';
import '../widgets/store/coins_store.dart';
import '../widgets/store/hearts_store.dart';
import '../widgets/store/heart_booster_store.dart';
import '../widgets/store/store_purchase_handler.dart';

/// Shows the store as a draggable bottom sheet
/// Swipe down to dismiss or tap X button
Future<void> showStoreBottomSheet(BuildContext context, {String? initialCategory}) {
  HapticFeedback.mediumImpact();
  
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => StoreBottomSheet(initialCategory: initialCategory),
  );
}

class StoreBottomSheet extends StatefulWidget {
  final String? initialCategory;

  const StoreBottomSheet({super.key, this.initialCategory});

  @override
  State<StoreBottomSheet> createState() => _StoreBottomSheetState();
}

class _StoreBottomSheetState extends State<StoreBottomSheet> {
  late String selectedCategory;
  final inv = InventoryManager();
  final monetization = MonetizationManager();
  final economy = EconomyConfig();
  final livesManager = LivesManager();
  late StorePurchaseHandler purchaseHandler;
  bool _isInitialized = false;

  final List<String> categories = [
    'Jets',
    'Gems',
    'Coins',
    'Hearts',
    'Heart Booster',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? 'Jets';
    _initializeStore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    purchaseHandler = StorePurchaseHandler(
      context: context,
      inventory: inv,
      monetization: monetization,
      economy: economy,
      livesManager: livesManager,
    );
  }

  Future<void> _initializeStore() async {
    await JetSkinCatalog.initializeFromAssets();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.9, 0.95],
      builder: (context, scrollController) => _buildSheetContent(scrollController),
    );
  }

  Widget _buildSheetContent(ScrollController scrollController) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4FC3F7), // Light blue
            Color(0xFF29B6F6), // Darker blue
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Drag handle
              _buildDragHandle(),
              
              // Header with currency displays
              Padding(
                padding: EdgeInsets.only(
                  top: isTablet ? 8 : 4,
                  left: 16,
                  right: 50, // Space for X button
                ),
                child: StoreHeader(inventory: inv),
              ),

              const SizedBox(height: 8),

              // Category navigation
              StoreNavigation(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  HapticFeedback.selectionClick();
                  setState(() => selectedCategory = category);
                },
              ),

              const SizedBox(height: 12),

              // Store content - scrollable
              Expanded(
                child: _isInitialized 
                  ? SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: _buildStoreContent(),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
              ),
            ],
          ),
          
          // X close button (top-right)
          Positioned(
            right: 12,
            top: 16,
            child: _buildCloseButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStoreContent() {
    switch (selectedCategory) {
      case 'Jets':
        return JetsStore(
          inventory: inv,
          economy: economy,
          onPurchaseJet: purchaseHandler.purchaseJetSkin,
          onEquipJet: purchaseHandler.equipJetSkin,
        );
      case 'Gems':
        return GemsStore(onPurchaseGemPack: purchaseHandler.purchaseGemPack);
      case 'Coins':
        return CoinsStore(
          inventory: inv,
          economy: economy,
          onPurchaseCoinPack: purchaseHandler.purchaseCoinPack,
        );
      case 'Hearts':
        return HeartsStore(
          livesManager: livesManager,
          economy: economy,
          onPurchaseFullHeartsRefill: purchaseHandler.purchaseFullHeartsRefill,
        );
      case 'Heart Booster':
        return HeartBoosterStore(
          inventory: inv,
          onPurchaseBooster: (duration) {
            purchaseHandler.purchaseHeartBooster(duration);
          },
        );
      default:
        return const SizedBox();
    }
  }
}


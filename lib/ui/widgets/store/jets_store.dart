/// 🛒 Jets Store Component - Jet skins with purchase and equip functionality
import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import '../../../game/core/economy_config.dart';
import '../../../game/systems/inventory_manager.dart';

class JetsStore extends StatelessWidget {
  final InventoryManager inventory;
  final EconomyConfig economy;
  final Function(JetSkin) onPurchaseJet;
  final Function(JetSkin) onEquipJet;

  const JetsStore({
    super.key,
    required this.inventory,
    required this.economy,
    required this.onPurchaseJet,
    required this.onEquipJet,
  });

  @override
  Widget build(BuildContext context) {
    final allSkins = [JetSkinCatalog.starterJet, ...JetSkinCatalog.premiumSkins];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: allSkins.length,
      itemBuilder: (context, index) {
        final skin = allSkins[index];
        return JetSkinCard(
          skin: skin,
          inventory: inventory,
          economy: economy,
          onPurchase: () => onPurchaseJet(skin),
          onEquip: () => onEquipJet(skin),
        );
      },
    );
  }
}

class JetSkinCard extends StatelessWidget {
  final JetSkin skin;
  final InventoryManager inventory;
  final EconomyConfig economy;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  const JetSkinCard({
    super.key,
    required this.skin,
    required this.inventory,
    required this.economy,
    required this.onPurchase,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: inventory,
      builder: (context, _) {
        final isOwned = inventory.isOwned(skin.id) || skin.isPurchased;
        final price = economy.getSkinCoinPrice(skin);
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isOwned
                  ? [Colors.green.shade600, Colors.green.shade800]
                  : [Colors.blue.shade600, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isOwned ? Colors.green : Colors.blue).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Jet Preview
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(
                    'assets/images/${skin.assetPath}',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.flight, 
                      size: 40, 
                      color: Colors.white
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                skin.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 6),
              
              if (isOwned)
                Column(
                  children: [
                    const Text(
                      'OWNED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildEquipButton(),
                  ],
                )
              else
                _buildBuyRow(price),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEquipButton() {
    final equipped = inventory.equippedSkinId == skin.id;
    
    return GestureDetector(
      onTap: onEquip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: equipped 
              ? Colors.greenAccent.withValues(alpha: 0.9) 
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          equipped ? 'EQUIPPED' : 'EQUIP',
          style: TextStyle(
            color: equipped ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBuyRow(int price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.monetization_on,
          color: Color(0xFFFFD700),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '$price',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onPurchase,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'BUY',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

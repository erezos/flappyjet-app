/// 🛒 Heart Booster Store Component - Premium heart booster with multiple duration options
library;

import 'package:flutter/material.dart';
import '../../../game/systems/inventory_manager.dart';
import '../../utils/responsive_config.dart';

/// Heart booster duration options
class BoosterDuration {
  final int hours;
  final String priceUSD;
  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;

  const BoosterDuration({
    required this.hours,
    required this.priceUSD,
    required this.displayName,
    required this.primaryColor,
    required this.secondaryColor,
  });

  static const List<BoosterDuration> options = [
    BoosterDuration(
      hours: 24,
      priceUSD: '\$0.99',
      displayName: '24H Booster',
      primaryColor: Color(0xFF4CAF50),
      secondaryColor: Color(0xFF2E7D32),
    ),
    BoosterDuration(
      hours: 48,
      priceUSD: '\$1.79',
      displayName: '48H Booster',
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF0D47A1),
    ),
    BoosterDuration(
      hours: 72,
      priceUSD: '\$2.39',
      displayName: '72H Booster',
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFF6A1B9A),
    ),
  ];
}

class HeartBoosterStore extends StatelessWidget {
  final InventoryManager inventory;
  final Function(BoosterDuration) onPurchaseBooster;

  const HeartBoosterStore({
    super.key,
    required this.inventory,
    required this.onPurchaseBooster,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: inventory,
      builder: (context, _) {
        return Padding(
          padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
            horizontal: 16.0,
            vertical: 12.0,
            screenSize: screenSize,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              _buildSectionHeader(context, screenSize),
              SizedBox(height: ResponsiveConfig.responsivePadding(16.0, screenSize)),
              
              // Products Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final crossAxisSpacing = ResponsiveConfig.responsivePadding(12.0, screenSize);
                  final cardWidth = (availableWidth - crossAxisSpacing) / 2;
                  
                  // Improved aspect ratio calculation - ensures cards fit content on all devices
                  final baseCardHeight = ResponsiveConfig.responsiveSize(220.0, screenSize, minScale: 0.85, maxScale: 1.2);
                  final aspectRatio = cardWidth / baseCardHeight.clamp(180.0, 280.0);
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: aspectRatio,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisSpacing: ResponsiveConfig.responsivePadding(12.0, screenSize),
                    ),
                    itemCount: BoosterDuration.options.length,
                    itemBuilder: (context, index) {
                      final duration = BoosterDuration.options[index];
                      return _buildBoosterCard(context, screenSize, duration);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, Size screenSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
                  child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
              // Much bigger image - engaging and prominent
              Image.asset(
                'assets/images/ui/six_hearts_booster_icon.png',
                width: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.7, maxScale: 1.2).clamp(40.0, 80.0),
                height: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.7, maxScale: 1.2).clamp(40.0, 80.0),
                errorBuilder: (_, __, ___) => Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.7, maxScale: 1.2).clamp(40.0, 80.0),
                ),
              ),
              SizedBox(width: ResponsiveConfig.responsivePadding(12.0, screenSize).clamp(4.0, 16.0)),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Heart Booster',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoosterCard(
    BuildContext context,
    Size screenSize,
    BoosterDuration duration,
  ) {
    final isRecommended = duration.hours == 48;
        
        return GestureDetector(
          onTap: () => onPurchaseBooster(duration),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
                colors: [duration.primaryColor, duration.secondaryColor],
              ),
          borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(20.0, screenSize)),
              border: isRecommended
                  ? Border.all(color: const Color(0xFFFFD700), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
              color: duration.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveConfig.responsivePadding(6.0, screenSize),
                    left: ResponsiveConfig.responsivePadding(12.0, screenSize),
                    right: ResponsiveConfig.responsivePadding(12.0, screenSize),
                    bottom: ResponsiveConfig.responsivePadding(12.0, screenSize),
                  ),
                  child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                      // Badge
                      SizedBox(
                        height: ResponsiveConfig.responsiveSize(24.0, screenSize, minScale: 0.8, maxScale: 1.2).clamp(20.0, 30.0),
                        child: Center(
                          child: isRecommended
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Container(
                                    padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                      screenSize: screenSize,
                                ),
                                decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(ResponsiveConfig.responsivePadding(8.0, screenSize)),
                                    ),
                                  child: Text(
                                      'BEST VALUE',
                                    style: TextStyle(
                                        fontSize: ResponsiveConfig.responsiveFontSize(10.0, screenSize, context),
                                      fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),

                      // Big Icon - Responsive and constrained
                      FittedBox(
                                          fit: BoxFit.scaleDown,
                        child: Image.asset(
                          'assets/images/ui/six_hearts_booster_icon.png',
                          width: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.8, maxScale: 1.2).clamp(48.0, 80.0),
                          height: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.8, maxScale: 1.2).clamp(48.0, 80.0),
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.favorite,
                                              color: Colors.white,
                            size: ResponsiveConfig.responsiveSize(64.0, screenSize, minScale: 0.8, maxScale: 1.2).clamp(48.0, 80.0),
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(4.0, screenSize)),

                      // Title - Responsive
                      FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                          duration.displayName,
                                  style: TextStyle(
                            fontSize: ResponsiveConfig.responsiveFontSize(18.0, screenSize, context),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize)),

                      // Description - Responsive with constraints
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Maximum Hearts: 6',
                            style: TextStyle(
                              fontSize: ResponsiveConfig.responsiveFontSize(13.0, screenSize, context),
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),

                      // Spacer to push price to bottom
                      const Spacer(),

                      // Price - Always at bottom
                      FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    duration.priceUSD,
                                    style: TextStyle(
                            fontSize: ResponsiveConfig.responsiveFontSize(20.0, screenSize, context),
                            fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            );
          },
            ),
      ),
    );
  }
}

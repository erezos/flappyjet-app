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
        final isActive = inventory.isHeartBoosterActive;

        return Padding(
          padding: ResponsiveConfig.responsiveEdgeInsetsSymmetric(
            horizontal: 16.0,
            vertical: 8.0,
            screenSize: screenSize,
          ),
          child: Column(
            children: [
              // Compact header with status
              _buildCompactHeader(isActive, screenSize),

              SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),

              // Main explanation card (half size)
              _buildCompactExplanationCard(screenSize, isActive),

              SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),

              // Purchase section title
              Builder(
                builder: (context) {
                  final fontSize = ResponsiveConfig.responsiveFontSize(12.0, screenSize, context);
                  return Text(
                    'PURCHASE OPTIONS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  );
                },
              ),

              SizedBox(height: ResponsiveConfig.responsivePadding(8.0, screenSize)),

              // ✅ FIX: Three purchase cards in a row with LayoutBuilder for responsive sizing
              // Use LayoutBuilder constraints to calculate optimal card height
              // Note: Scaffold's bottomNavigationBar is automatically accounted for by Expanded widget
              // SafeArea handles system UI (notches, status bars), not app navigation bars
              LayoutBuilder(
                builder: (context, constraints) {
                  // Use constraints.maxHeight from parent (already accounts for bottom nav bar)
                  // Calculate optimal card height based on available space
                  // Aim for consistent aspect ratio across all devices
                  final optimalCardHeight = ResponsiveConfig.responsiveSize(
                    120.0,
                    screenSize,
                    minScale: 0.85,
                    maxScale: 1.3,
                  ).clamp(
                    ResponsiveConfig.responsiveSize(100.0, screenSize, minScale: 0.85, maxScale: 1.3),
                    ResponsiveConfig.responsiveSize(150.0, screenSize, minScale: 0.85, maxScale: 1.3),
                  );
                  
                  return SizedBox(
                    height: optimalCardHeight,
                    child: _buildPurchaseCardsRow(isActive, screenSize),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader(bool isActive, Size screenSize) {
    return Builder(
      builder: (context) {
        final titleFontSize = ResponsiveConfig.responsiveFontSize(20.0, screenSize, context);
        final iconSize = ResponsiveConfig.responsiveIconSize(14.0, screenSize);
        final activeFontSize = ResponsiveConfig.responsiveFontSize(10.0, screenSize, context);
        final horizontalPadding = ResponsiveConfig.responsivePadding(10.0, screenSize);
        final verticalPadding = ResponsiveConfig.responsivePadding(4.0, screenSize);
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Centered title
            Text(
              'HEART BOOSTER',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            // Right-aligned active badge
            if (isActive)
              Positioned(
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: iconSize,
                      ),
                      SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: activeFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCompactExplanationCard(Size screenSize, bool isActive) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A1B9A), // Rich purple
            const Color(0xFF9C27B0),
            const Color(0xFFE91E63), // Pink accent
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Padding(
            padding: ResponsiveConfig.responsiveEdgeInsets(16.0, screenSize),
            child: Builder(
              builder: (context) {
                final iconContainerSize = ResponsiveConfig.responsiveSize(42.0, screenSize, minScale: 0.9, maxScale: 1.2);
                final iconSize = ResponsiveConfig.responsiveIconSize(22.0, screenSize);
                final titleFontSize = ResponsiveConfig.responsiveFontSize(14.0, screenSize, context);
                final subtitleFontSize = ResponsiveConfig.responsiveFontSize(11.0, screenSize, context);
                final flashIconSize = ResponsiveConfig.responsiveIconSize(16.0, screenSize);
                
                return Column(
                  children: [
                    // Header with value proposition
                    Row(
                      children: [
                        // Pulsing heart icon
                        Container(
                          width: iconContainerSize,
                          height: iconContainerSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),

                        SizedBox(width: ResponsiveConfig.responsivePadding(12.0, screenSize)),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'UNLIMITED POWER',
                                    style: TextStyle(
                                      color: const Color(0xFFFFD700),
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveConfig.responsivePadding(4.0, screenSize)),
                                  Icon(
                                    Icons.flash_on,
                                    color: const Color(0xFFFFD700),
                                    size: flashIconSize,
                                  ),
                                ],
                              ),
                              SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize)),
                              Text(
                                'Play longer, win bigger!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Timer badge if active
                        if (isActive) _buildActiveTimerBadge(screenSize),
                      ],
                    ),

                    SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),

                    // Value proposition with numbers
                    Container(
                      padding: ResponsiveConfig.responsiveEdgeInsets(12.0, screenSize),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildValueProp(
                              '6',
                              'MAX HEARTS',
                              'vs 3 normal',
                              Icons.favorite,
                              const Color(0xFFE91E63),
                              screenSize,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: ResponsiveConfig.responsiveSize(35.0, screenSize, minScale: 0.9, maxScale: 1.2),
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _buildValueProp(
                              '25%',
                              'FASTER',
                              '8min vs 10min',
                              Icons.speed,
                              const Color(0xFF4CAF50),
                              screenSize,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: ResponsiveConfig.responsiveSize(35.0, screenSize, minScale: 0.9, maxScale: 1.2),
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _buildValueProp(
                              '∞',
                              'STACK',
                              'Add more time',
                              Icons.layers,
                              const Color(0xFFFFD700),
                              screenSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTimerBadge(Size screenSize) {
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        return inventory.heartBoosterTimeRemaining ?? Duration.zero;
      }),
      builder: (context, snapshot) {
        final timeRemaining = snapshot.data ?? Duration.zero;

        if (timeRemaining.inSeconds <= 0) {
          return const SizedBox.shrink();
        }

        final hours = timeRemaining.inHours;
        final minutes = timeRemaining.inMinutes.remainder(60);

        return Builder(
          builder: (context) {
            final horizontalPadding = ResponsiveConfig.responsivePadding(8.0, screenSize);
            final verticalPadding = ResponsiveConfig.responsivePadding(4.0, screenSize);
            final iconSize = ResponsiveConfig.responsiveIconSize(12.0, screenSize);
            final fontSize = ResponsiveConfig.responsiveFontSize(10.0, screenSize, context);
            
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  SizedBox(width: ResponsiveConfig.responsivePadding(2.0, screenSize)),
                  Text(
                    hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildValueProp(
    String number,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Size screenSize,
  ) {
    return Builder(
      builder: (context) {
        final iconSize = ResponsiveConfig.responsiveIconSize(18.0, screenSize);
        final numberFontSize = ResponsiveConfig.responsiveFontSize(16.0, screenSize, context);
        final titleFontSize = ResponsiveConfig.responsiveFontSize(9.0, screenSize, context);
        final subtitleFontSize = ResponsiveConfig.responsiveFontSize(7.0, screenSize, context);
        
        return Column(
          children: [
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize)),
            Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: numberFontSize,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurchaseCardsRow(bool isActive, Size screenSize) {
    return Row(
      children: BoosterDuration.options.map((duration) {
        final isRecommended = duration.hours == 48;
        final index = BoosterDuration.options.indexOf(duration);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : ResponsiveConfig.responsivePadding(6.0, screenSize),
              right: index == BoosterDuration.options.length - 1
                  ? 0
                  : ResponsiveConfig.responsivePadding(6.0, screenSize),
            ),
            child: _buildCompactPurchaseCard(
              duration,
              isRecommended,
              isActive,
              screenSize,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactPurchaseCard(
    BoosterDuration duration,
    bool isRecommended,
    bool isActive,
    Size screenSize,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ FIX: Calculate card height based on available constraints, ensuring consistent aspect ratio
        final cardHeight = constraints.maxHeight.clamp(
          ResponsiveConfig.responsiveSize(100.0, screenSize, minScale: 0.85, maxScale: 1.3),
          ResponsiveConfig.responsiveSize(150.0, screenSize, minScale: 0.85, maxScale: 1.3),
        );
        
        return GestureDetector(
          onTap: () => onPurchaseBooster(duration),
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [duration.primaryColor, duration.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
              border: isRecommended
                  ? Border.all(color: const Color(0xFFFFD700), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                if (isRecommended)
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: ResponsiveConfig.responsiveEdgeInsets(6.0, screenSize),
                child: Builder(
                  builder: (context) {
                    final badgeHeight = ResponsiveConfig.responsiveSize(16.0, screenSize, minScale: 0.8, maxScale: 1.2);
                    final badgeFontSize = ResponsiveConfig.responsiveFontSize(8.0, screenSize, context);
                    final timerIconSize = ResponsiveConfig.responsiveIconSize(18.0, screenSize);
                    final durationFontSize = ResponsiveConfig.responsiveFontSize(16.0, screenSize, context);
                    final descFontSize = ResponsiveConfig.responsiveFontSize(9.0, screenSize, context);
                    final priceFontSize = ResponsiveConfig.responsiveFontSize(10.0, screenSize, context);
                    
                    return LayoutBuilder(
                      builder: (context, cardConstraints) {
                        // Calculate available height for content (excluding padding)
                        final availableHeight = cardConstraints.maxHeight.isFinite && cardConstraints.maxHeight > 0 
                            ? cardConstraints.maxHeight 
                            : double.infinity;
                        
                        // Calculate max badge height, ensuring it's >= min value
                        final maxBadgeHeight = (availableHeight * 0.15).clamp(12.0, double.infinity);
                        
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ FIX: BEST badge with proper margin and overflow handling
                            if (isRecommended)
                              Container(
                                margin: EdgeInsets.only(
                                  top: ResponsiveConfig.responsivePadding(2.0, screenSize),
                                  bottom: ResponsiveConfig.responsivePadding(2.0, screenSize),
                                ),
                                height: badgeHeight.clamp(12.0, maxBadgeHeight),
                                constraints: BoxConstraints(
                                  minHeight: badgeHeight * 0.8,
                                  maxHeight: badgeHeight * 1.2,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveConfig.responsivePadding(6.0, screenSize),
                                  vertical: ResponsiveConfig.responsivePadding(2.0, screenSize),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '⭐ BEST',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: badgeFontSize,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              SizedBox(height: (badgeHeight + ResponsiveConfig.responsivePadding(4.0, screenSize)).clamp(0.0, maxBadgeHeight)),

                            // Spacer
                            Expanded(
                              flex: 2,
                              child: SizedBox.shrink(),
                            ),

                            // Duration with icon - ✅ FIX: Use LayoutBuilder to prevent overflow
                            Flexible(
                              flex: 3,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Ensure content fits within available space
                                  final maxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0 
                                      ? constraints.maxHeight 
                                      : double.infinity;
                                  
                                  // Calculate max sizes, ensuring they're >= min values
                                  final maxIconSize = (maxHeight * 0.4).clamp(12.0, double.infinity);
                                  final maxTextSize = (maxHeight * 0.3).clamp(10.0, double.infinity);
                                  final maxSpacing = (maxHeight * 0.1).clamp(1.0, double.infinity);
                                  
                                  final iconSize = timerIconSize.clamp(8.0, maxIconSize);
                                  final textSize = durationFontSize.clamp(8.0, maxTextSize);
                                  final spacing = ResponsiveConfig.responsivePadding(2.0, screenSize).clamp(1.0, maxSpacing);
                                  
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Icon(
                                          Icons.timer,
                                          color: Colors.white,
                                          size: iconSize,
                                        ),
                                      ),
                                      SizedBox(height: spacing),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '${duration.hours}H',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: textSize,
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            // Spacer
                            Expanded(
                              flex: 1,
                              child: SizedBox.shrink(),
                            ),

                            // Description
                            Flexible(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isActive ? '+${duration.hours}h More' : 'Booster',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: descFontSize,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            SizedBox(height: ResponsiveConfig.responsivePadding(2.0, screenSize).clamp(1.0, availableHeight * 0.05)),

                            // ✅ FIX: Price button with proper constraints and overflow handling
                            Flexible(
                              flex: 2,
                              child: Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  minHeight: ResponsiveConfig.responsiveSize(20.0, screenSize, minScale: 0.6, maxScale: 1.2),
                                  maxHeight: ResponsiveConfig.responsiveSize(30.0, screenSize, minScale: 0.6, maxScale: 1.2).clamp(20.0, availableHeight * 0.25),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveConfig.responsivePadding(4.0, screenSize),
                                  vertical: ResponsiveConfig.responsivePadding(2.0, screenSize),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    duration.priceUSD,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: priceFontSize,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
      ),
        );
      },
    );
  }
}

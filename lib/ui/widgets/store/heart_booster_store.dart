/// 🛒 Heart Booster Store Component - Premium heart booster with multiple duration options
library;

import 'package:flutter/material.dart';
import '../../../game/systems/inventory_manager.dart';

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
    final isTablet = screenSize.width > 600;

    return AnimatedBuilder(
      animation: inventory,
      builder: (context, _) {
        final isActive = inventory.isHeartBoosterActive;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 12 : 8,
          ),
          child: Column(
            children: [
              // Compact header with status
              _buildCompactHeader(isActive, isTablet),

              SizedBox(height: isTablet ? 12 : 8),

              // Main explanation card (half size)
              _buildCompactExplanationCard(isTablet, isActive),

              SizedBox(height: isTablet ? 16 : 12),

              // Purchase section title
              Text(
                'PURCHASE OPTIONS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),

              SizedBox(height: isTablet ? 12 : 8),

              // Three purchase cards in a row
              SizedBox(
                height: isTablet ? 140 : 120,
                child: _buildPurchaseCardsRow(isActive, isTablet),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader(bool isActive, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'HEART BOOSTER',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        if (isActive)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 10,
              vertical: isTablet ? 6 : 4,
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
                  size: isTablet ? 16 : 14,
                ),
                SizedBox(width: isTablet ? 6 : 4),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactExplanationCard(bool isTablet, bool isActive) {
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
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              children: [
                // Header with value proposition
                Row(
                  children: [
                    // Pulsing heart icon
                    Container(
                      width: isTablet ? 50 : 42,
                      height: isTablet ? 50 : 42,
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
                        size: isTablet ? 26 : 22,
                      ),
                    ),

                    SizedBox(width: isTablet ? 16 : 12),

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
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: isTablet ? 6 : 4),
                              Icon(
                                Icons.flash_on,
                                color: const Color(0xFFFFD700),
                                size: isTablet ? 18 : 16,
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 4 : 2),
                          Text(
                            'Play longer, win bigger!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 13 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Timer badge if active
                    if (isActive) _buildActiveTimerBadge(isTablet),
                  ],
                ),

                SizedBox(height: isTablet ? 16 : 12),

                // Value proposition with numbers
                Container(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
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
                          isTablet,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: isTablet ? 40 : 35,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildValueProp(
                          '25%',
                          'FASTER',
                          '8min vs 10min',
                          Icons.speed,
                          const Color(0xFF4CAF50),
                          isTablet,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: isTablet ? 40 : 35,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildValueProp(
                          '∞',
                          'STACK',
                          'Add more time',
                          Icons.layers,
                          const Color(0xFFFFD700),
                          isTablet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTimerBadge(bool isTablet) {
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

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 12 : 8,
            vertical: isTablet ? 6 : 4,
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
                size: isTablet ? 14 : 12,
              ),
              SizedBox(width: isTablet ? 4 : 2),
              Text(
                hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
    bool isTablet,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: isTablet ? 20 : 18),
        SizedBox(height: isTablet ? 4 : 2),
        Text(
          number,
          style: TextStyle(
            color: color,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 10 : 9,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: isTablet ? 8 : 7,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPurchaseCardsRow(bool isActive, bool isTablet) {
    return Row(
      children: BoosterDuration.options.map((duration) {
        final isRecommended = duration.hours == 48;
        final index = BoosterDuration.options.indexOf(duration);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : (isTablet ? 8 : 6),
              right: index == BoosterDuration.options.length - 1
                  ? 0
                  : (isTablet ? 8 : 6),
            ),
            child: _buildCompactPurchaseCard(
              duration,
              isRecommended,
              isActive,
              isTablet,
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
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: () =>
          onPurchaseBooster(duration), // Always allow purchase for stacking
      child: Container(
        height: double.infinity,
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
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 8 : 6),
          child: Column(
            children: [
              // Badge (fixed height)
              SizedBox(
                height: isTablet ? 16 : 14,
                child: isRecommended
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 6 : 4,
                          vertical: isTablet ? 2 : 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⭐ BEST',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: isTablet ? 9 : 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),

              // Spacer
              const Spacer(),

              // Duration with icon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    color: Colors.white,
                    size: isTablet ? 20 : 18,
                  ),
                  SizedBox(height: isTablet ? 2 : 1),
                  Text(
                    '${duration.hours}H',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Spacer
              const Spacer(),

              // Description
              Text(
                isActive ? '+${duration.hours}h More' : 'Booster',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: isTablet ? 10 : 9,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: isTablet ? 4 : 2),

              // Price button
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 6 : 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  duration.priceUSD,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎮 BOTTOM NAVIGATOR BAR - Custom Fighter Jet Dashboard
/// Fully custom-painted UI with Canvas for fighter jet cockpit aesthetic
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavigatorBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigatorBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavigatorBar> createState() => _BottomNavigatorBarState();
}

class _BottomNavigatorBarState extends State<BottomNavigatorBar>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _scaleController;
  int? _tappedIndex;

  // Tab data (icons + labels)
  final List<_TabData> _tabs = [
    _TabData(icon: Icons.shopping_bag, label: 'STORE'),
    _TabData(icon: Icons.emoji_events, label: 'TOURNAMENT'),
    _TabData(icon: Icons.map, label: 'STORY'),
    _TabData(icon: Icons.checklist, label: 'MISSIONS'),
    _TabData(icon: Icons.person, label: 'PROFILE'),
  ];

  @override
  void initState() {
    super.initState();
    
    // Pulsing glow animation for active tab
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Scale animation for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;

    HapticFeedback.lightImpact();

    setState(() {
      _tappedIndex = index;
    });

    _scaleController.forward().then((_) {
      _scaleController.reverse();
      setState(() {
        _tappedIndex = null;
      });
    });

    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 🚀 BIGGER responsive height to match the page's vibrant style
    final navBarHeight = screenHeight > 800 
        ? 110.0  // Large screens (tablets) - INCREASED
        : screenHeight > 700 
            ? 100.0  // Medium screens - INCREASED
            : 90.0; // Small screens (phones) - INCREASED

    return Container(
      width: screenWidth,
      height: navBarHeight,
      decoration: BoxDecoration(
        // 🎨 VIBRANT gradient matching FlappyJet's bright theme
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3A5F), // Rich blue (like sky)
            const Color(0xFF0D1F2D), // Deep navy
          ],
        ),
        // ✨ BRIGHT cyan top border (matches page theme)
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00D9FF), // Brighter cyan
            width: 3, // Thicker for more impact
          ),
        ),
        // 💎 Glowing shadow for modern depth
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // 🎨 BACKGROUND PATTERN (HUD-style grid lines)
            CustomPaint(
              size: Size(screenWidth, navBarHeight),
              painter: _DashboardBackgroundPainter(),
            ),
            
            // 🎯 TAB BUTTONS
            Row(
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isActive = index == widget.currentIndex;
                final isTapped = index == _tappedIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _handleTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_glowController, _scaleController]),
                      builder: (context, child) {
                        // 💎 Pulsing glow intensity for active tab (MORE INTENSE)
                        final glowIntensity = isActive 
                            ? 0.4 + (_glowController.value * 0.5) // 40-90% (BRIGHTER)
                            : 0.0;
                        
                        // Scale animation for tap feedback
                        final scale = isTapped ? 0.9 : 1.0;

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
                            decoration: BoxDecoration(
                              // 🌟 GOLD active tab background
                              color: isActive 
                                  ? Color(0xFFFFD700).withOpacity(glowIntensity * 0.3) // Gold glow
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14), // Rounder
                              // ✨ GOLD active tab border
                              border: isActive ? Border.all(
                                color: const Color(0xFFFFD700), // Gold border
                                width: 2, // Thicker
                              ) : null,
                              // 💫 GOLD glow effect for active tab
                              boxShadow: isActive ? [
                                BoxShadow(
                                  color: Color(0xFFFFD700).withOpacity(glowIntensity * 0.6),
                                  blurRadius: 30, // Larger glow
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ] : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min, // ✅ FIX: Allow shrinking
                              children: [
                                // 🎮 ICON (sized to fit - reduced further to fix overflow)
                                Icon(
                                  tab.icon,
                                  size: isActive ? 22 : 20, // ✅ Reduced from 24/22 to fix 8px overflow
                                  color: isActive 
                                      ? const Color(0xFFFFD700) // ✅ Gold for active
                                      : const Color(0xFFFFD700).withOpacity(0.6), // ✅ Dim gold for inactive
                                ),
                                const SizedBox(height: 2), // ✅ Reduced from 3 to 2
                                // 📝 LABEL (sized to fit - reduced further to fix overflow)
                                Text(
                                  tab.label,
                                  style: TextStyle(
                                    fontSize: isActive ? 9.5 : 8.5, // ✅ Reduced from 10.5/9.5 to fix 8px overflow
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                    color: isActive 
                                        ? const Color(0xFFFFD700) // ✅ Gold for active
                                        : const Color(0xFFFFD700).withOpacity(0.6), // ✅ Dim gold for inactive
                                    letterSpacing: 0.6, // ✅ Reduced from 0.8
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎨 Custom painter for vibrant HUD-style background pattern
class _DashboardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 💎 Brighter grid lines
    final paint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.15) // Brighter
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines (HUD aesthetic)
    for (double y = 0; y < size.height; y += size.height / 4) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // ✨ BRIGHT corner accent lines (cockpit frame aesthetic)
    final accentPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.5) // Much brighter
      ..strokeWidth = 3 // Thicker
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width * 0.12, 0),
      accentPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width * 0.88, 0),
      Offset(size.width, 0),
      accentPaint,
    );
    
    // 🌟 Add glowing dots at corners for extra flair
    final dotPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.12, 0), 3, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.88, 0), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 📊 Tab data model
class _TabData {
  final IconData icon;
  final String label;

  _TabData({required this.icon, required this.label});
}

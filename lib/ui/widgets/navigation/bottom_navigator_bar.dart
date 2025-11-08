/// 🎮 BOTTOM NAVIGATOR BAR - Floating Translucent Bar (Brawl Stars Style)
/// Glowing active indicator, bouncing tap animations, modern gaming aesthetic
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;

class BottomNavigatorBar extends StatefulWidget {
  final int currentIndex;
  final List<String> titles;
  final List<IconData> icons;
  final Function(int) onTap;

  const BottomNavigatorBar({
    super.key,
    required this.currentIndex,
    required this.titles,
    required this.icons,
    required this.onTap,
  });

  @override
  State<BottomNavigatorBar> createState() => _BottomNavigatorBarState();
}

class _BottomNavigatorBarState extends State<BottomNavigatorBar>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  int? _bouncingIndex;
  late List<AnimationController> _bounceControllers;

  @override
  void initState() {
    super.initState();
    
    // Glow animation for active indicator (pulsing effect)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Bounce controllers for each icon
    _bounceControllers = List.generate(
      widget.icons.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    for (var controller in _bounceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;

    // Trigger bounce animation
    setState(() {
      _bouncingIndex = index;
    });
    _bounceControllers[index].forward().then((_) {
      _bounceControllers[index].reverse().then((_) {
        if (mounted) {
          setState(() {
            _bouncingIndex = null;
          });
        }
      });
    });

    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = math.min(screenWidth * 0.9, 500.0);
    final itemWidth = barWidth / widget.icons.length;

    return Center(
      child: Container(
        width: barWidth,
        height: 70,
        decoration: BoxDecoration(
          // Translucent dark background with blur effect
          color: const Color(0xFF1a1a2e).withOpacity(0.85),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            // Subtle inner glow
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: -5,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glowing active indicator (slides behind icons)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: widget.currentIndex * itemWidth + (itemWidth - 60) / 2,
              top: 10,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glowIntensity = 0.6 + (_glowController.value * 0.4);
                  return Container(
                    width: 60,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withOpacity(glowIntensity * 0.4),
                          Colors.deepOrange.withOpacity(glowIntensity * 0.2),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.orange.shade400.withOpacity(0.3),
                            Colors.deepOrange.shade600.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.orange.withOpacity(glowIntensity * 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation icons
            Row(
              children: List.generate(widget.icons.length, (index) {
                final isActive = index == widget.currentIndex;
                final isBouncing = _bouncingIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _handleTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: _bounceControllers[index],
                      builder: (context, child) {
                        final bounceScale = isBouncing
                            ? 1.0 + (_bounceControllers[index].value * 0.3)
                            : 1.0;

                        return Transform.scale(
                          scale: bounceScale,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon with color transition
                              Icon(
                                widget.icons[index],
                                size: isActive ? 30 : 26,
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Label text (smaller, subtle)
                              Text(
                                widget.titles[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive
                                      ? Colors.orange.shade300
                                      : Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ],
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


/// 🏠 HOMEPAGE FOOTER NAVIGATOR
/// 
/// Image-based footer navigation with 5 clickable sections:
/// 1. Store
/// 2. Tournaments
/// 3. World Map (current page)
/// 4. Daily Missions & Achievements
/// 5. Profile
/// 
/// ✅ Responsive Design: Scales based on screen width
/// ✅ Flame Best Practices: Efficient gesture detection, clear separation of concerns
/// ✅ Mobile Gaming Standards: Haptic feedback, visual press animations
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_config.dart';
import '../../core/debug_logger.dart';

/// Footer navigator sections
enum FooterNavigatorSection {
  store,
  tournaments,
  worldMap,
  missions,
  profile,
}

class HomepageFooterNavigator extends StatefulWidget {
  /// Current active section (for highlighting)
  final FooterNavigatorSection? activeSection;
  
  /// Callback when a section is tapped
  final void Function(FooterNavigatorSection section)? onSectionTap;
  
  const HomepageFooterNavigator({
    super.key,
    this.activeSection,
    this.onSectionTap,
  });

  @override
  State<HomepageFooterNavigator> createState() => _HomepageFooterNavigatorState();
}

class _HomepageFooterNavigatorState extends State<HomepageFooterNavigator>
    with SingleTickerProviderStateMixin {
  // Original image dimensions: 1490 x 391 pixels
  static const double _originalImageWidth = 1490.0;
  static const double _originalImageHeight = 391.0;
  static const int _numSections = 5;
  
  // Press animation controller
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  FooterNavigatorSection? _pressedSection;
  
  // Swipe gesture tracking for footer
  double _footerDragStartX = 0.0;
  double _footerDragCurrentX = 0.0;
  static const double _footerMinSwipeDistance = 30.0; // Smaller threshold for footer

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  /// Calculate the width of each section based on screen width
  double _getSectionWidth(double screenWidth) {
    return screenWidth / _numSections;
  }

  /// Calculate the height of the footer based on screen width (maintain aspect ratio)
  double _getFooterHeight(double screenWidth) {
    final aspectRatio = _originalImageHeight / _originalImageWidth;
    return screenWidth * aspectRatio;
  }

  /// Get the horizontal position of a section (left edge)
  double _getSectionLeft(int sectionIndex, double screenWidth) {
    return _getSectionWidth(screenWidth) * sectionIndex;
  }

  /// Handle tap on a section
  void _handleSectionTap(FooterNavigatorSection section) {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Press animation
    setState(() => _pressedSection = section);
    _pressController.forward().then((_) {
      _pressController.reverse().then((_) {
        if (mounted) {
          setState(() => _pressedSection = null);
        }
      });
    });
    
    // Call callback
    widget.onSectionTap?.call(section);
    
    safePrint('🏠 Footer Navigator: ${section.name} tapped');
  }
  
  /// Handle horizontal drag start on footer
  void _onFooterDragStart(DragStartDetails details) {
    _footerDragStartX = details.globalPosition.dx;
    _footerDragCurrentX = _footerDragStartX;
  }
  
  /// Handle horizontal drag update on footer
  void _onFooterDragUpdate(DragUpdateDetails details) {
    _footerDragCurrentX = details.globalPosition.dx;
  }
  
  /// Handle horizontal drag end on footer - switch tabs
  void _onFooterDragEnd(DragEndDetails details) {
    if (widget.activeSection == null) return;
    
    // Calculate actual swipe distance
    final swipeDistance = (_footerDragStartX - _footerDragCurrentX).abs();
    
    // Determine swipe direction
    final isSwipeLeft = _footerDragCurrentX < _footerDragStartX;
    final isSwipeRight = _footerDragCurrentX > _footerDragStartX;
    
    // Only switch if swipe distance is sufficient
    if (swipeDistance > _footerMinSwipeDistance && (isSwipeLeft || isSwipeRight)) {
      final sections = FooterNavigatorSection.values;
      final currentIndex = sections.indexOf(widget.activeSection!);
      
      FooterNavigatorSection? nextSection;
      
      if (isSwipeLeft && currentIndex < sections.length - 1) {
        // Swipe left = move to next tab (right)
        nextSection = sections[currentIndex + 1];
      } else if (isSwipeRight && currentIndex > 0) {
        // Swipe right = move to previous tab (left)
        nextSection = sections[currentIndex - 1];
      }
      
      if (nextSection != null) {
        // Haptic feedback for tab switch
        HapticFeedback.mediumImpact();
        widget.onSectionTap?.call(nextSection);
        safePrint('🏠 Footer Navigator: Swiped to ${nextSection.name}');
      }
    }
    
    // Reset drag tracking
    _footerDragStartX = 0.0;
    _footerDragCurrentX = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final footerHeight = _getFooterHeight(screenSize.width);
    final sectionWidth = _getSectionWidth(screenSize.width);
    
    return GestureDetector(
      // ✅ Swipe detection on footer itself - always switches tabs
      onHorizontalDragStart: _onFooterDragStart,
      onHorizontalDragUpdate: _onFooterDragUpdate,
      onHorizontalDragEnd: _onFooterDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: footerHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          // Optional: Add subtle shadow or gradient overlay
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 51),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
        children: [
          // Background image (full width, maintains aspect ratio)
          Positioned.fill(
            child: Image.asset(
              'assets/images/homepage/footer_navigator.png',
              fit: BoxFit.fill, // Fill the entire footer area
              errorBuilder: (context, error, stackTrace) {
                safePrint('⚠️ Footer navigator image not found');
                return Container(
                  color: const Color(0xFF1A237E),
                  child: Center(
                    child: Text(
                      'Footer Navigator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveConfig.responsiveSize(14.0, screenSize),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Clickable regions overlay
          ...List.generate(_numSections, (index) {
            final section = FooterNavigatorSection.values[index];
            final isPressed = _pressedSection == section;
            
            return Positioned(
              left: _getSectionLeft(index, screenSize.width),
              top: 0,
              width: sectionWidth,
              height: footerHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, // ✅ Ensure taps are captured
                onTap: () => _handleSectionTap(section),
                child: AnimatedBuilder(
                  animation: _pressAnimation,
                  builder: (context, child) {
                    final scale = isPressed ? _pressAnimation.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: SizedBox.expand( // ✅ Use SizedBox.expand to ensure full area is tappable
                        // Active section indicator removed - no visual indicator needed
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
        ),
      ),
    );
  }
}


/// 🏷️ Responsive Banner Component - Cross-platform text centering solution
///
/// This component ensures perfect text centering within banner images
/// across all platforms (iOS, Android) and screen sizes using Flutter best practices.
///
/// Key Features:
/// - Uses LayoutBuilder for responsive sizing
/// - MediaQuery for platform-specific adjustments
/// - Intrinsic dimensions for accurate centering
/// - Flexible text scaling based on content length
/// - Cross-platform consistency
library;

import 'package:flutter/material.dart';

class ResponsiveBannerComponent extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final String bannerImagePath;
  final Color textColor;
  final Color hintColor;
  final String hintText;
  final int maxLength;
  final double? width;
  final double? height;

  const ResponsiveBannerComponent({
    super.key,
    required this.controller,
    required this.onSave,
    required this.bannerImagePath,
    this.textColor = Colors.black87,
    this.hintColor = Colors.black54,
    this.hintText = 'Enter your name',
    this.maxLength = 16,
    this.width,
    this.height,
  });

  @override
  State<ResponsiveBannerComponent> createState() =>
      _ResponsiveBannerComponentState();
}

class _ResponsiveBannerComponentState extends State<ResponsiveBannerComponent> {
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        final wasFocused = _isEditing;
        final isFocused = _focusNode.hasFocus;

        setState(() {
          _isEditing = isFocused;
        });

        // 🎯 CRITICAL FIX: Auto-save nickname when user taps away (loses focus)
        if (wasFocused && !isFocused) {
          // User just lost focus, save the nickname
          widget.onSave();
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.shortestSide >= 600;

        // Calculate responsive dimensions - use full available width when width is null
        final bannerWidth =
            widget.width ??
            constraints.maxWidth; // Use full available width from parent
        final bannerHeight = widget.height ?? (isTablet ? 180.0 : 140.0);

        // Debug output to see actual values
        print(
          '🎯 ResponsiveBanner: widget.width=${widget.width}, calculated bannerWidth=$bannerWidth, availableWidth=${constraints.maxWidth}, screenWidth=${screenSize.width}',
        );

        return SizedBox(
          width: bannerWidth,
          height: bannerHeight,
          child: _buildBannerWithText(
            context,
            bannerWidth,
            bannerHeight,
            isTablet,
          ),
        );
      },
    );
  }

  Widget _buildBannerWithText(
    BuildContext context,
    double bannerWidth,
    double bannerHeight,
    bool isTablet,
  ) {
    return Stack(
      children: [
        // Banner background image - full container
        Positioned.fill(
          child: Image.asset(
            widget.bannerImagePath,
            fit:
                BoxFit.fill, // Fill the entire container (stretch to fit width)
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackBanner(bannerWidth, bannerHeight),
          ),
        ),

        // Text field - precisely centered using mathematical positioning
        _buildCenteredTextField(context, bannerWidth, bannerHeight, isTablet),
      ],
    );
  }

  Widget _buildCenteredTextField(
    BuildContext context,
    double bannerWidth,
    double bannerHeight,
    bool isTablet,
  ) {
    return Positioned(
      // Center the text field within the banner using calculated positioning
      left: bannerWidth * 0.15, // 15% margin from left
      right: bannerWidth * 0.15, // 15% margin from right
      top:
          bannerHeight *
          0.45, // Position in the yellow banner area (45% from top)
      height: bannerHeight * 0.25, // 25% of banner height for text area
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, child) {
          return _buildResponsiveTextField(context, value, isTablet);
        },
      ),
    );
  }

  Widget _buildResponsiveTextField(
    BuildContext context,
    TextEditingValue value,
    bool isTablet,
  ) {
    final textLength = value.text.length;

    // Dynamic font sizing based on text length and device type
    double baseFontSize = isTablet ? 28.0 : 22.0;
    double fontSize = _calculateFontSize(textLength, baseFontSize);

    // Platform-specific adjustments
    double letterSpacing = _calculateLetterSpacing(textLength);

    return Container(
      alignment: Alignment.center, // Ensure container centers its child
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        maxLength: widget.maxLength,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: widget.textColor,
          letterSpacing: letterSpacing,
          height: 1.0, // Line height for better vertical centering
        ),
        decoration: InputDecoration(
          counterText: _isEditing ? '$textLength/${widget.maxLength}' : '',
          counterStyle: TextStyle(
            fontSize: isTablet ? 12.0 : 10.0,
            color: textLength > (widget.maxLength * 0.75)
                ? Colors.orange
                : Colors.grey,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero, // Remove default padding
          isDense: true, // Reduce internal padding
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: widget.hintColor,
            fontWeight: FontWeight.w600,
            fontSize: fontSize * 0.9, // Slightly smaller hint text
          ),
        ),
        onSubmitted: (_) => widget.onSave(),
      ),
    );
  }

  double _calculateFontSize(int textLength, double baseFontSize) {
    if (textLength <= 8) {
      return baseFontSize;
    } else if (textLength <= 12) {
      return baseFontSize * 0.85; // 15% smaller
    } else {
      return baseFontSize * 0.7; // 30% smaller for long text
    }
  }

  double _calculateLetterSpacing(int textLength) {
    if (textLength <= 6) {
      return 1.5;
    } else if (textLength <= 10) {
      return 1.0;
    } else if (textLength <= 14) {
      return 0.5;
    } else {
      return 0.2; // Tight spacing for very long text
    }
  }

  Widget _buildFallbackBanner(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFFFA500), // Orange
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade700, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'BANNER',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Extension for easy responsive calculations
extension ResponsiveBannerExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;
}

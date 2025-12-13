import 'package:flutter/material.dart';
import '../../utils/responsive_config.dart';

class TournamentGameOverPopup extends StatelessWidget {
  final String jetAssetPath;
  final String levelLabel;
  final String subtitle;
  final String message;
  final int continuesRemaining;
  final VoidCallback? onContinueWithAd;
  final VoidCallback? onContinueWithGems;
  final VoidCallback onStartOver;
  final VoidCallback onClose;
  final String startOverLabel;
  final int continueGemCost;

  const TournamentGameOverPopup({
    super.key,
    required this.jetAssetPath,
    required this.levelLabel,
    required this.subtitle,
    required this.message,
    required this.continuesRemaining,
    required this.onContinueWithAd,
    required this.onContinueWithGems,
    required this.onStartOver,
    required this.onClose,
    required this.startOverLabel,
    required this.continueGemCost,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = ResponsiveConfig.responsivePopupWidth(screen, percent: 0.9, maxWidth: 360);
    final padding = ResponsiveConfig.responsiveSize(18, screen, minScale: 0.9, maxScale: 1.1);
    final titleSize = ResponsiveConfig.responsiveSize(22, screen, minScale: 0.9, maxScale: 1.15);
    final bodySize = ResponsiveConfig.responsiveSize(14, screen, minScale: 0.9, maxScale: 1.1);
    final buttonHeight = ResponsiveConfig.responsiveSize(54, screen, minScale: 0.95, maxScale: 1.15);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B1B2F), Color(0xFF0F1326)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),

              SizedBox(height: padding * 0.5),

              // Jet image with smoke background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2833), Color(0xFF0B0F1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    jetAssetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: padding * 0.8),

              Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.4,
                ),
              ),

              SizedBox(height: padding * 0.4),
              Text(
                levelLabel,
                style: TextStyle(
                  fontSize: bodySize,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: padding * 0.2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: bodySize * 0.95,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),

              SizedBox(height: padding * 0.8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: bodySize,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: padding * 0.8),

              // Continue options
              _buildContinueRow(bodySize, buttonHeight),

              SizedBox(height: padding * 0.8),

              // Continue count
              Text(
                'Continue? $continuesRemaining left',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: bodySize * 0.95,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: padding * 0.9),

              // Start over button
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: const Color(0xFFFFC107),
                    shadowColor: Colors.amber.withOpacity(0.5),
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: onStartOver,
                  child: Text(
                    startOverLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: bodySize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueRow(double fontSize, double buttonHeight) {
    final adEnabled = onContinueWithAd != null;
    final gemsEnabled = onContinueWithGems != null;
    return Row(
      children: [
        Expanded(
          child: _pillButton(
            labelTop: 'FREE',
            labelBottom: 'watch ad',
            color: const Color(0xFF17C964),
            enabled: adEnabled,
            onTap: onContinueWithAd,
            fontSize: fontSize,
            height: buttonHeight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pillButton(
            labelTop: '$continueGemCost GEMS',
            labelBottom: 'continue',
            color: const Color(0xFF8B5CF6),
            enabled: gemsEnabled,
            onTap: onContinueWithGems,
            fontSize: fontSize,
            height: buttonHeight,
          ),
        ),
      ],
    );
  }

  Widget _pillButton({
    required String labelTop,
    required String labelBottom,
    required Color color,
    required bool enabled,
    required VoidCallback? onTap,
    required double fontSize,
    required double height,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                labelTop,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                labelBottom,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: fontSize * 0.85,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


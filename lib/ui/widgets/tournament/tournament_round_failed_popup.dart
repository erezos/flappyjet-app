/// 🏆 Tournament Round Failed Popup - Mobile-Optimized
/// 
/// Shows when player fails a round in tournament mode.
/// Compact design for mobile with continue options.
library;

import 'package:flutter/material.dart';
import '../../../models/tournament_config.dart';
import '../../../models/tournament_entry.dart';
import '../../utils/responsive_config.dart';

class TournamentRoundFailedPopup extends StatelessWidget {
  final TournamentConfig tournament;
  final TournamentEntry entry;
  final int obstaclesPassed;
  final int obstacleTarget;
  final bool canContinue;
  final int continuesRemaining;
  final int playerGems;
  final int gemCost;
  final VoidCallback? onContinueWithAd;
  final VoidCallback? onContinueWithGems;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  const TournamentRoundFailedPopup({
    super.key,
    required this.tournament,
    required this.entry,
    required this.obstaclesPassed,
    required this.obstacleTarget,
    required this.canContinue,
    required this.continuesRemaining,
    required this.playerGems,
    required this.gemCost,
    this.onContinueWithAd,
    this.onContinueWithGems,
    required this.onRetry,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final hasEnoughGems = playerGems >= gemCost;
    final progress = obstacleTarget > 0 ? obstaclesPassed / obstacleTarget : 0.0;

    // Responsive sizing
    final dialogWidth = ResponsiveConfig.responsivePopupWidth(screenSize, percent: 0.88, maxWidth: 340);
    final padding = ResponsiveConfig.responsiveSize(14, screenSize);
    final iconSize = ResponsiveConfig.responsiveSize(40, screenSize, minScale: 0.9, maxScale: 1.1);
    final titleSize = ResponsiveConfig.responsiveSize(18, screenSize, minScale: 0.9, maxScale: 1.1);
    final bodySize = ResponsiveConfig.responsiveSize(12, screenSize, minScale: 0.9, maxScale: 1.1);
    final buttonHeight = ResponsiveConfig.responsiveSize(40, screenSize, minScale: 0.9, maxScale: 1.1);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D1B4E),
              Color(0xFF1A1A2E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red,
                  size: iconSize * 0.55,
                ),
              ),

              SizedBox(height: padding * 0.6),

              // Title
              Text(
                'ROUND FAILED',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),

              SizedBox(height: padding * 0.3),

              // Round info
              Text(
                '${tournament.name} - Round ${entry.currentRound}',
                style: TextStyle(
                  fontSize: bodySize,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: padding),

              // Progress bar
              _buildProgressBar(progress, bodySize, padding),

              SizedBox(height: padding),

              // Continue options (if available)
              if (canContinue && continuesRemaining > 0)
                _buildContinueOptions(hasEnoughGems, bodySize, buttonHeight, padding),

              if (canContinue && continuesRemaining > 0)
                SizedBox(height: padding * 0.6),

              // Tries remaining info
              _buildTriesInfo(bodySize, padding),

              SizedBox(height: padding),

              // Action buttons
              _buildActionButtons(bodySize, buttonHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, double fontSize, double padding) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: fontSize,
              ),
            ),
            Text(
              '$obstaclesPassed / $obstacleTarget',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
        SizedBox(height: padding * 0.4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.7 ? Colors.green : Colors.amber,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueOptions(bool hasEnoughGems, double fontSize, double buttonHeight, double padding) {
    return Container(
      padding: EdgeInsets.all(padding * 0.8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Continue? ($continuesRemaining left)',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: fontSize + 1,
            ),
          ),
          SizedBox(height: padding * 0.5),
          Row(
            children: [
              // Watch Ad button
              Expanded(
                child: _buildContinueButton(
                  icon: Icons.play_circle_filled,
                  label: 'AD',
                  color: Colors.amber,
                  onTap: onContinueWithAd,
                  height: buttonHeight - 4,
                  fontSize: fontSize,
                ),
              ),
              SizedBox(width: padding * 0.5),
              // Gems button
              Expanded(
                child: _buildContinueButton(
                  icon: Icons.diamond,
                  label: '$gemCost',
                  color: hasEnoughGems ? Colors.cyan : Colors.grey,
                  onTap: hasEnoughGems ? onContinueWithGems : null,
                  height: buttonHeight - 4,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    required double height,
    required double fontSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : null,
          color: onTap == null ? color.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: fontSize + 4),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriesInfo(double fontSize, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, color: Colors.red, size: fontSize + 2),
          const SizedBox(width: 6),
          Text(
            '${entry.triesRemaining} tries remaining',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double fontSize, double buttonHeight) {
    return Row(
      children: [
        // Quit button
        Expanded(
          child: _buildActionButton(
            label: 'QUIT',
            color: Colors.grey.shade700,
            onTap: onQuit,
            height: buttonHeight,
            fontSize: fontSize,
          ),
        ),
        const SizedBox(width: 10),
        // Retry button
        Expanded(
          flex: 2,
          child: _buildActionButton(
            label: entry.triesRemaining > 0 ? 'USE TRY' : 'END',
            color: entry.triesRemaining > 0 ? Colors.orange : Colors.red,
            onTap: onRetry,
            height: buttonHeight,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double height,
    required double fontSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize + 1,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

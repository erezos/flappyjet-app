/// 🏆 Tournament Round Complete Popup - Mobile-Optimized
/// 
/// Shows when player completes a round in tournament mode.
/// Designed for mobile screens with compact, centered layout.
library;

import 'package:flutter/material.dart';
import '../../../models/tournament_config.dart';
import '../../utils/responsive_config.dart';
import '../coin_3d_icon.dart';
import '../gem_3d_icon.dart';

class TournamentRoundCompletePopup extends StatefulWidget {
  final TournamentConfig tournament;
  final int roundNumber;
  final int coinsEarned;
  final int gemsEarned;
  final VoidCallback onNextRound;

  const TournamentRoundCompletePopup({
    super.key,
    required this.tournament,
    required this.roundNumber,
    required this.coinsEarned,
    required this.gemsEarned,
    required this.onNextRound,
  });

  @override
  State<TournamentRoundCompletePopup> createState() => _TournamentRoundCompletePopupState();
}

class _TournamentRoundCompletePopupState extends State<TournamentRoundCompletePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLastRound = widget.roundNumber >= widget.tournament.totalRounds;

    // Responsive sizing
    final dialogWidth = ResponsiveConfig.responsivePopupWidth(screenSize, percent: 0.88, maxWidth: 340);
    final padding = ResponsiveConfig.responsiveSize(16, screenSize);
    final iconSize = ResponsiveConfig.responsiveSize(50, screenSize, minScale: 0.9, maxScale: 1.1);
    final titleSize = ResponsiveConfig.responsiveSize(20, screenSize, minScale: 0.9, maxScale: 1.1);
    final bodySize = ResponsiveConfig.responsiveSize(13, screenSize, minScale: 0.9, maxScale: 1.1);
    final buttonHeight = ResponsiveConfig.responsiveSize(44, screenSize, minScale: 0.9, maxScale: 1.1);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: padding),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B4E2D),
                  Color(0xFF1A2E1A),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
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
                  // Checkmark icon
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: iconSize * 0.5,
                    ),
                  ),

                  SizedBox(height: padding * 0.8),

                  // Title
                  Text(
                    'ROUND COMPLETE!',
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
                    'Round ${widget.roundNumber} of ${widget.tournament.totalRounds}',
                    style: TextStyle(
                      fontSize: bodySize,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),

                  SizedBox(height: padding),

                  // Rewards section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(padding * 0.8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'REWARDS',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: bodySize - 1,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: padding * 0.6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.coinsEarned > 0)
                              _buildRewardItem(
                                icon: Coin3DIcon(size: bodySize + 14),
                                value: '+${widget.coinsEarned}',
                                fontSize: bodySize,
                              ),
                            if (widget.gemsEarned > 0)
                              _buildRewardItem(
                                icon: Gem3DIcon(size: bodySize + 14),
                                value: '+${widget.gemsEarned}',
                                fontSize: bodySize,
                              ),
                            if (widget.coinsEarned == 0 && widget.gemsEarned == 0)
                              Text(
                                'No rewards this round',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: bodySize,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: padding * 0.8),

                  // Progress indicator
                  _buildProgressIndicator(bodySize),

                  SizedBox(height: padding),

                  // Next button
                  GestureDetector(
                    onTap: widget.onNextRound,
                    child: Container(
                      width: double.infinity,
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLastRound
                              ? [Colors.amber, Colors.orange]
                              : [Colors.green, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isLastRound ? Colors.amber : Colors.green)
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLastRound ? Icons.emoji_events : Icons.arrow_forward,
                            color: Colors.white,
                            size: bodySize + 6,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLastRound ? 'CLAIM VICTORY!' : 'NEXT ROUND',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: bodySize + 2,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    String? emoji,
    Widget? icon,
    required String value,
    required double fontSize,
  }) {
    return Column(
      children: [
        if (icon != null)
          icon
        else if (emoji != null)
          Text(emoji, style: TextStyle(fontSize: fontSize + 14)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize + 4,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(double fontSize) {
    final rounds = widget.tournament.totalRounds;
    // Use smaller dots if many rounds
    final dotSize = rounds > 5 ? 18.0 : (rounds > 3 ? 20.0 : 22.0);
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: List.generate(rounds, (index) {
        final roundNum = index + 1;
        final isCompleted = roundNum <= widget.roundNumber;
        final isCurrent = roundNum == widget.roundNumber;
        
        final currentDotSize = isCurrent ? dotSize + 4 : dotSize;
        
        return Container(
          width: currentDotSize,
          height: currentDotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : Colors.white.withValues(alpha: 0.2),
            border: isCurrent
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: currentDotSize * 0.55)
                : Text(
                    '$roundNum',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: fontSize - 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

/// ✈️ Profile Jet Preview Component - Display equipped jet with responsive sizing
import 'package:flutter/material.dart';
import '../../../game/core/jet_skins.dart';
import 'profile_responsive_config.dart';

class ProfileJetPreview extends StatelessWidget {
  final JetSkin equippedSkin;
  
  const ProfileJetPreview({
    super.key,
    required this.equippedSkin,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.profileConfig;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Jet Image
        Flexible(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * config.jetPreviewWidthRatio,
            height: MediaQuery.of(context).size.height * config.jetPreviewHeightRatio,
            child: Image.asset(
              'assets/images/${equippedSkin.assetPath}',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.flight, 
                size: config.getResponsiveIconSize(110), 
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // Spacing between jet and name
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        
        // Jet Name with gradient
        _GradientText(
          equippedSkin.displayName.toUpperCase(),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD256), Color(0xFFF57C00)],
          ),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: config.getResponsiveFontSize(24),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

/// Gradient text widget for jet name styling
class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  
  const _GradientText(
    this.text, {
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(Offset.zero & bounds.size),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style),
    );
  }
}

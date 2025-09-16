/// 📱 Social Sharing Manager - Template-Based Score Card Sharing for FlappyJet
library;
import '../../core/debug_logger.dart';

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'firebase_analytics_manager.dart';
import 'missions_manager.dart';
import 'achievements_manager.dart';

/// Supported social platforms
enum SocialPlatform {
  whatsapp,
  instagram,
  facebook,
  tiktok,
}

/// Template positioning configuration with relative coordinates
class TemplateConfig {
  final String assetPath;
  final Offset relativeScorePosition; // Percentage-based position (0.0 to 1.0)
  final double relativeFontSize; // Percentage of image height
  final Color textColor;
  final List<Shadow> shadows;

  const TemplateConfig({
    required this.assetPath,
    required this.relativeScorePosition,
    required this.relativeFontSize,
    required this.textColor,
    required this.shadows,
  });

  /// Calculate absolute position based on image dimensions
  Offset getAbsolutePosition(int imageWidth, int imageHeight) {
    return Offset(
      imageWidth * relativeScorePosition.dx,
      imageHeight * relativeScorePosition.dy,
    );
  }

  /// Calculate absolute font size based on image dimensions
  double getAbsoluteFontSize(int imageHeight) {
    return imageHeight * relativeFontSize;
  }
}

/// Available share card templates with precise positioning
enum ShareTemplate {
  challengeMe,
  beatMyScore,
  scoreBox,
  tryToBeatMe;

  /// Get template configuration with smart positioning strategy
  TemplateConfig get config {
    switch (this) {
      case ShareTemplate.challengeMe:
        return const TemplateConfig(
          assetPath: 'assets/images/share_templates/challange_me.png',
          relativeScorePosition: Offset(0.5, 0.78), // User-specified precise positioning
          relativeFontSize: 0.08, // 8% of image height - smaller, cleaner
          textColor: Colors.white,
          shadows: [
            Shadow(offset: Offset(3, 3), blurRadius: 6, color: Color(0xEE000000)),
            Shadow(offset: Offset(-1, -1), blurRadius: 2, color: Color(0x88000000)),
          ],
        );
      case ShareTemplate.beatMyScore:
        return const TemplateConfig(
          assetPath: 'assets/images/share_templates/beat_my_score.png',
          relativeScorePosition: Offset(0.85, 0.8), // User-specified precise positioning
          relativeFontSize: 0.08, // 8% of image height - smaller, cleaner
          textColor: Colors.white,
          shadows: [
            Shadow(offset: Offset(3, 3), blurRadius: 6, color: Color(0xEE000000)),
            Shadow(offset: Offset(-1, -1), blurRadius: 2, color: Color(0x88000000)),
          ],
        );
      case ShareTemplate.scoreBox:
        return const TemplateConfig(
          assetPath: 'assets/images/share_templates/score_box.png',
          relativeScorePosition: Offset(0.35, 0.61), // Fine-tuned positioning
          relativeFontSize: 0.10, // 10% of image height - better fit for the box
          textColor: Color(0xFF2B5AA0), // Darker blue for better contrast
          shadows: [
            Shadow(offset: Offset(2, 2), blurRadius: 4, color: Color(0x66000000)),
            Shadow(offset: Offset(-1, -1), blurRadius: 2, color: Color(0x33000000)),
          ],
        );
      case ShareTemplate.tryToBeatMe:
        return const TemplateConfig(
          assetPath: 'assets/images/share_templates/try_to_beat_me.png',
          relativeScorePosition: Offset(0.5, 0.565), // Fine-tuned positioning
          relativeFontSize: 0.10, // 10% of image height
          textColor: Colors.white,
          shadows: [
            Shadow(offset: Offset(3, 3), blurRadius: 6, color: Color(0xDD000000)),
            Shadow(offset: Offset(-1, -1), blurRadius: 2, color: Color(0x88000000)),
          ],
        );
    }
  }
}

/// Result of a sharing operation
class ShareResult {
  final bool isSuccess;
  final String? error;
  final String? platform;
  final String? imagePath;
  final String? message;
  
  const ShareResult({
    required this.isSuccess,
    this.error,
    this.platform,
    this.imagePath,
    this.message,
  });
  
  factory ShareResult.success(String platform, {String? imagePath}) => ShareResult(
    isSuccess: true,
    platform: platform,
    imagePath: imagePath,
  );
  
  factory ShareResult.failure(String error) => ShareResult(
    isSuccess: false,
    error: error,
    message: error,
  );
}

/// Share content configuration
class ShareContent {
  final String text;
  final String? imagePath;
  final Map<String, dynamic> metadata;
  
  const ShareContent({
    required this.text,
    this.imagePath,
    this.metadata = const {},
  });
}

/// Comprehensive social sharing manager
class SocialSharingManager extends ChangeNotifier {
  static final SocialSharingManager _instance = SocialSharingManager._internal();
  factory SocialSharingManager({
    FirebaseAnalyticsManager? analytics,
    MissionsManager? missions,
    AchievementsManager? achievements,
  }) {
    if (analytics != null) _instance._analytics = analytics;
    if (missions != null) _instance._missions = missions;
    if (achievements != null) _instance._achievements = achievements;
    return _instance;
  }
  SocialSharingManager._internal();

  FirebaseAnalyticsManager? _analytics;
  MissionsManager? _missions;
  AchievementsManager? _achievements;
  
  bool _isInitialized = false;
  int _totalShares = 0;
  final Set<SocialPlatform> _platformsUsedToday = {};
  
  bool get isInitialized => _isInitialized;
  int get totalShares => _totalShares;

  /// Initialize the social sharing system
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize dependencies if not provided
      _analytics ??= FirebaseAnalyticsManager();
      _missions ??= MissionsManager();
      _achievements ??= AchievementsManager();
      
      // Load sharing statistics
      await _loadSharingStats();
      
      _isInitialized = true;
      safePrint('📱 Social Sharing Manager initialized');
    } catch (e) {
      safePrint('❌ Failed to initialize Social Sharing Manager: $e');
    }
  }

  /// Share score with randomized template-based score card
  Future<ShareResult> shareScore({
    required int score,
    required SocialPlatform platform,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Generate platform-specific content
      final content = generateShareContent(
        score: score,
        platform: platform,
        customMessage: customMessage,
      );

      // Generate score card with random template
      final scoreCardPath = await _generateScoreCard(score);

      // Perform the actual sharing
      final shareResult = await _performShare(content, platform, scoreCardPath);
      
      if (shareResult.isSuccess) {
        // Track the sharing event
        await _trackSharingEvent(score, platform);
        
        // Update missions and achievements
        await _updateSharingProgress(platform);
        
        // Update local statistics
        _totalShares++;
        _platformsUsedToday.add(platform);
        await _saveSharingStats();
        
        notifyListeners();
      }

      return shareResult;
    } catch (e) {
      safePrint('❌ Share failed: $e');
      return ShareResult.failure('Failed to share: $e');
    }
  }

  /// Generate platform-specific share content
  ShareContent generateShareContent({
    required int score,
    required SocialPlatform platform,
    String? customMessage,
  }) {
    if (customMessage != null) {
      return ShareContent(text: customMessage);
    }

    final baseMessage = _getScoreBasedMessage(score);
    final platformSpecificMessage = _formatForPlatform(baseMessage, platform, score);
    
    return ShareContent(
      text: platformSpecificMessage,
      metadata: {
        'score': score,
        'platform': platform.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// App store links for download promotion
  static const String _androidStoreLink = 'https://play.google.com/store/apps/details?id=com.flappyjet.pro.flappy_jet_pro';
  static const String _iosStoreLink = 'https://apps.apple.com/app/flappy-jet/id6752501703';
  
  /// Universal smart link that detects platform
  static const String _universalLink = 'https://flappyjet.page.link/download'; // Firebase Dynamic Link (recommended)
  
  /// Fallback smart link using a simple redirect service
  static const String _smartLink = 'https://linktr.ee/flappyjet'; // Alternative: Linktree
  
  /// Get platform-appropriate download link
  String _getDownloadLink() {
    // For now, use Android link as primary (since iOS is pending approval)
    // TODO: Update to use _iosStoreLink once iOS app is approved
    // TODO: Implement Firebase Dynamic Links for true universal linking
    return _androidStoreLink;
  }
  
  /// Update to use iOS link once approved (call this method after iOS approval)
  static void enableIOSLink() {
    // This will be used to switch to iOS link or universal link
    // For now, just a placeholder for future implementation
  }

  /// Get score-based motivational message
  String _getScoreBasedMessage(int score) {
    if (score < 10) {
      return "Just scored $score in FlappyJet! 🚁 Getting the hang of it!";
    } else if (score < 25) {
      return "Scored $score points in FlappyJet! ✈️ Flying higher every time!";
    } else if (score < 50) {
      return "Amazing! Just hit $score points in FlappyJet! 🛩️ I'm on fire!";
    } else if (score < 100) {
      return "INCREDIBLE! $score points in FlappyJet! 🚀 Can you beat this?";
    } else if (score < 200) {
      return "LEGENDARY! $score points in FlappyJet! 👑 I'm a Sky Master!";
    } else {
      return "UNBELIEVABLE! $score points in FlappyJet! 🌟 This is INSANE!";
    }
  }

  /// Format message for specific platform with enhanced viral mechanics
  String _formatForPlatform(String baseMessage, SocialPlatform platform, int score) {
    final downloadLink = _getDownloadLink();
    
    switch (platform) {
      case SocialPlatform.whatsapp:
        // WhatsApp: Personal challenge with direct link
        return "$baseMessage\n\n🎮 Think you can beat my score? Download FlappyJet and prove it!\n\n📱 Get it here: $downloadLink\n\n#FlappyJetChallenge";
        
      case SocialPlatform.instagram:
        // Instagram: Visual-focused with trending hashtags
        return "$baseMessage\n\n🚁 Can you fly higher? Challenge accepted!\n\n📱 Download FlappyJet: $downloadLink\n\n#FlappyJet #MobileGaming #HighScore #Challenge #Gaming #FlappyJetPro #AviationGame #ScoreChallenge";
        
      case SocialPlatform.facebook:
        // Facebook: Community-focused with call-to-action
        return "$baseMessage\n\n🏆 Think you can do better? Download FlappyJet and show me your skills! Who's up for the challenge?\n\n📱 Download now: $downloadLink\n\n#FlappyJet #Challenge #MobileGaming";
        
      case SocialPlatform.tiktok:
        // TikTok: Trending hashtags and viral language
        return "$baseMessage\n\n🔥 This game is addictive! Who can beat this score?\n\n📱 Download FlappyJet: $downloadLink\n\n#FlappyJet #Gaming #HighScore #Challenge #MobileGame #Viral #GameChallenge #FYP";
    }
  }

  /// Generate score card with random template and precise positioning
  Future<String?> _generateScoreCard(int score) async {
    try {
      // Select random template
      final templates = ShareTemplate.values;
      final randomTemplate = templates[Random().nextInt(templates.length)];
      final templateConfig = randomTemplate.config;
      
      safePrint('🎨 Selected template: ${randomTemplate.name} for score: $score');

      // Load template image
      final ByteData templateData = await rootBundle.load(templateConfig.assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(templateData.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image templateImage = frameInfo.image;

      // Create canvas for drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw template image
      canvas.drawImage(templateImage, Offset.zero, Paint());
      
      // Add score text overlay with template-specific positioning
      await _drawScoreTextWithConfig(canvas, score, templateConfig, templateImage.width, templateImage.height);
      
      // Convert to image
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(templateImage.width, templateImage.height);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return null;

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/flappyjet_scorecard_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byteData.buffer.asUint8List());
      
      safePrint('🎨 Score card generated: $imagePath (${randomTemplate.name})');
      return imagePath;
    } catch (e) {
      safePrint('❌ Failed to generate score card: $e');
      return null;
    }
  }

  /// Draw score text using template-specific configuration with dynamic sizing
  Future<void> _drawScoreTextWithConfig(Canvas canvas, int score, TemplateConfig config, int imageWidth, int imageHeight) async {
    // Calculate absolute position and font size based on actual image dimensions
    final absolutePosition = config.getAbsolutePosition(imageWidth, imageHeight);
    final absoluteFontSize = config.getAbsoluteFontSize(imageHeight);
    
    final textStyle = TextStyle(
      color: config.textColor,
      fontSize: absoluteFontSize,
      fontWeight: FontWeight.w900, // Extra bold for visibility
      shadows: config.shadows,
    );

    final textSpan = TextSpan(text: score.toString(), style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    textPainter.layout();
    
    // Center the text on the calculated position
    final xPosition = absolutePosition.dx - (textPainter.width / 2);
    final yPosition = absolutePosition.dy - (textPainter.height / 2);
    
    textPainter.paint(canvas, Offset(xPosition, yPosition));
    
    safePrint('🎯 Score positioned at: (${xPosition.toStringAsFixed(1)}, ${yPosition.toStringAsFixed(1)}) with font size ${absoluteFontSize.toStringAsFixed(1)} (${imageWidth}x${imageHeight})');
  }

  /// Perform the actual sharing operation with optional screenshot and direct app opening
  Future<ShareResult> _performShare(ShareContent content, SocialPlatform platform, [String? scoreCardPath]) async {
    try {
      // First, try direct app opening for supported platforms
      final directShareSuccess = await _tryDirectAppSharing(content, platform, scoreCardPath);
      
      if (directShareSuccess) {
        safePrint('📱 Direct app sharing successful for ${platform.name}');
        return ShareResult.success(platform.name);
      }
      
      // Fallback to system share sheet
      safePrint('📱 Using fallback share sheet for ${platform.name}');
      if (scoreCardPath != null) {
        // Share with score card template
        await Share.shareXFiles(
          [XFile(scoreCardPath)],
          text: content.text,
          subject: 'Check out my FlappyJet score! 🚁',
        );
      } else {
        // Share text only
        await Share.share(
          content.text,
          subject: 'Check out my FlappyJet score! 🚁',
        );
      }
      
      return ShareResult.success(platform.name);
    } catch (e) {
      return ShareResult.failure('Platform sharing failed: $e');
    }
  }

  /// Try direct app opening for supported platforms
  Future<bool> _tryDirectAppSharing(ShareContent content, SocialPlatform platform, String? scoreCardPath) async {
    try {
      final urlScheme = _getPlatformUrlScheme(platform, content);
      if (urlScheme == null) return false;
      
      final uri = Uri.parse(urlScheme);
      
      // Check if the app can be launched
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Track direct app opening success
        await _analytics?.trackEvent('direct_app_share', {
          'platform': platform.name,
          'method': 'direct_app_opening',
          'success': true,
        });
        
        return true;
      }
      
      return false;
    } catch (e) {
      safePrint('❌ Direct app sharing failed for ${platform.name}: $e');
      
      // Track direct app opening failure
      await _analytics?.trackEvent('direct_app_share', {
        'platform': platform.name,
        'method': 'direct_app_opening',
        'success': false,
        'error': e.toString(),
      });
      
      return false;
    }
  }

  /// Get platform-specific URL scheme for direct app opening
  String? _getPlatformUrlScheme(SocialPlatform platform, ShareContent content) {
    switch (platform) {
      case SocialPlatform.whatsapp:
        // WhatsApp direct sharing with text
        final encodedText = Uri.encodeComponent(content.text);
        return 'whatsapp://send?text=$encodedText';
        
      case SocialPlatform.instagram:
        // Instagram opens to camera/stories - limited direct sharing
        // Note: Instagram doesn't support direct text sharing via URL scheme
        return 'instagram://camera';
        
      case SocialPlatform.facebook:
        // Facebook has limited URL scheme support, requires Facebook SDK for full functionality
        // This opens Facebook app to compose post
        return 'fb://publish';
        
      case SocialPlatform.tiktok:
        // TikTok opens to creation flow - limited direct sharing
        // Note: TikTok doesn't support direct text sharing via URL scheme
        return 'tiktok://create';
    }
  }

  /// Track sharing event in analytics
  Future<void> _trackSharingEvent(int score, SocialPlatform platform) async {
    try {
      await _analytics?.trackEvent('social_share', {
        'platform': platform.name,
        'score': score,
        'content_type': 'score_share',
        'total_shares': _totalShares + 1,
      });
    } catch (e) {
      safePrint('❌ Failed to track sharing event: $e');
    }
  }

  /// Update sharing-related missions and achievements
  Future<void> _updateSharingProgress(SocialPlatform platform) async {
    try {
      // Update daily sharing mission
      await _missions?.updateMissionProgress(MissionType.shareScore, 1);
      
      // Update sharing achievements
      await _achievements?.updateProgress('social_pilot', 1);
      await _achievements?.updateProgress('influencer', 1);
      await _achievements?.updateProgress('viral_star', 1);
      await _achievements?.updateProgress('social_legend', 1);
      
      // Check platform master achievement (all 4 platforms in one session)
      if (_platformsUsedToday.length >= 4) {
        await _achievements?.updateProgress('platform_master', 1);
      }
    } catch (e) {
      safePrint('❌ Failed to update sharing progress: $e');
    }
  }

  /// Load sharing statistics from storage
  Future<void> _loadSharingStats() async {
    // Implementation would load from SharedPreferences
    // For now, initialize with defaults
    _totalShares = 0;
    _platformsUsedToday.clear();
  }

  /// Save sharing statistics to storage
  Future<void> _saveSharingStats() async {
    // Implementation would save to SharedPreferences
    // For now, just log the action
    safePrint('📱 Saving sharing stats: $_totalShares total shares');
  }

  /// Get sharing statistics for UI display
  Map<String, dynamic> getSharingStats() {
    return {
      'totalShares': _totalShares,
      'platformsUsedToday': _platformsUsedToday.length,
      'isInitialized': _isInitialized,
    };
  }

  /// Get platform-specific sharing behavior description for UI
  String getPlatformSharingDescription(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.whatsapp:
        return "Opens WhatsApp with your score and challenge message ready to send!";
      case SocialPlatform.instagram:
        return "Opens Instagram camera - perfect for sharing your score as a story!";
      case SocialPlatform.facebook:
        return "Opens Facebook to share your achievement with friends!";
      case SocialPlatform.tiktok:
        return "Opens TikTok creation flow - create a viral video of your score!";
    }
  }

  /// Check if platform supports direct app opening
  bool supportDirectAppOpening(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.whatsapp:
        return true; // Full text sharing support
      case SocialPlatform.instagram:
        return true; // Opens to camera/stories
      case SocialPlatform.facebook:
        return true; // Opens to compose
      case SocialPlatform.tiktok:
        return true; // Opens to creation flow
    }
  }

}

// Note: shareScore mission type is now part of the MissionType enum in missions_manager.dart

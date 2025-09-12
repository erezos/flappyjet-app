/// 📱 Social Sharing Manager - Comprehensive social sharing system for FlappyJet
library;
import '../../core/debug_logger.dart';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
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

/// Result of a sharing operation
class ShareResult {
  final bool isSuccess;
  final String? error;
  final String? platform;
  
  const ShareResult({
    required this.isSuccess,
    this.error,
    this.platform,
  });
  
  factory ShareResult.success(String platform) => ShareResult(
    isSuccess: true,
    platform: platform,
  );
  
  factory ShareResult.failure(String error) => ShareResult(
    isSuccess: false,
    error: error,
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

  /// Share score with platform-specific content and optional screenshot
  Future<ShareResult> shareScore({
    required int score,
    required SocialPlatform platform,
    String? customMessage,
    ScreenshotController? screenshotController,
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

      // Capture screenshot if controller provided
      String? screenshotPath;
      if (screenshotController != null) {
        screenshotPath = await _captureScreenshot(screenshotController);
      }

      // Perform the actual sharing
      final shareResult = await _performShare(content, platform, screenshotPath);
      
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
    const appStoreLink = "https://play.google.com/store/apps/details?id=com.flappyjet.pro";
    
    switch (platform) {
      case SocialPlatform.whatsapp:
        // WhatsApp: Personal challenge with direct link
        return "$baseMessage\n\n🎮 Think you can beat my score? Download FlappyJet and prove it!\n$appStoreLink\n\n#FlappyJetChallenge";
        
      case SocialPlatform.instagram:
        // Instagram: Visual-focused with trending hashtags
        return "$baseMessage\n\n🚁 Can you fly higher? Challenge accepted!\n\n#FlappyJet #MobileGaming #HighScore #Challenge #Gaming #FlappyJetPro #AviationGame #ScoreChallenge";
        
      case SocialPlatform.facebook:
        // Facebook: Community-focused with call-to-action
        return "$baseMessage\n\n🏆 Think you can do better? Download FlappyJet and show me your skills! Who's up for the challenge?\n\n$appStoreLink\n\n#FlappyJet #Challenge #MobileGaming";
        
      case SocialPlatform.tiktok:
        // TikTok: Trending hashtags and viral language
        return "$baseMessage\n\n🔥 This game is addictive! Who can beat this score?\n\n#FlappyJet #Gaming #HighScore #Challenge #MobileGame #Viral #GameChallenge #FYP";
    }
  }

  /// Capture screenshot from the game
  Future<String?> _captureScreenshot(ScreenshotController controller) async {
    try {
      final image = await controller.capture();
      if (image == null) return null;

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/flappyjet_score_${DateTime.now().millisecondsSinceEpoch}.png';

      // Save screenshot
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);
      
      safePrint('📸 Screenshot captured: $imagePath');
      return imagePath;
    } catch (e) {
      safePrint('❌ Failed to capture screenshot: $e');
      return null;
    }
  }

  /// Perform the actual sharing operation with optional screenshot and direct app opening
  Future<ShareResult> _performShare(ShareContent content, SocialPlatform platform, [String? screenshotPath]) async {
    try {
      // First, try direct app opening for supported platforms
      final directShareSuccess = await _tryDirectAppSharing(content, platform, screenshotPath);
      
      if (directShareSuccess) {
        safePrint('📱 Direct app sharing successful for ${platform.name}');
        return ShareResult.success(platform.name);
      }
      
      // Fallback to system share sheet
      safePrint('📱 Using fallback share sheet for ${platform.name}');
      if (screenshotPath != null) {
        // Share with screenshot
        await Share.shareXFiles(
          [XFile(screenshotPath)],
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
  Future<bool> _tryDirectAppSharing(ShareContent content, SocialPlatform platform, String? screenshotPath) async {
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

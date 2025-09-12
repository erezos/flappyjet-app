/// 🎨 Mission & Achievement 3D Icons - Beautiful asset-based icons
library;

import 'package:flutter/material.dart';

/// 3D Icon widget for missions and achievements
class Mission3DIcon extends StatelessWidget {
  final MissionIconType iconType;
  final double size;
  final Color? tintColor;

  const Mission3DIcon({
    super.key,
    required this.iconType,
    required this.size,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconPath = _getIconPath(iconType);
    print('🎨 Mission3DIcon: Loading $iconPath for $iconType');

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: tintColor,
        colorBlendMode: tintColor != null ? BlendMode.srcATop : null,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Mission3DIcon: Failed to load $iconPath - Error: $error');
          // Fallback to material icon if asset fails
          return Icon(
            _getFallbackIcon(iconType),
            size: size,
            color: tintColor ?? Colors.white,
          );
        },
      ),
    );
  }

  String _getIconPath(MissionIconType type) {
    switch (type) {
      // === GAMEPLAY MISSIONS ===
      case MissionIconType.playGames:
        return 'assets/images/icons/missions/pilot_helmet_icon.png'; // Pilot helmet for playing games
      case MissionIconType.reachScore:
        return 'assets/images/icons/missions/target_icon.png'; // Target for score goals
      case MissionIconType.surviveTime:
        return 'assets/images/icons/missions/timer_icon.png'; // Timer for survival
      case MissionIconType.perfectStart:
        return 'assets/images/icons/missions/gold_timer_icon.png'; // Gold timer for perfect starts
      case MissionIconType.closeCalls:
        return 'assets/images/icons/missions/shild_icon.png'; // Shield for close calls
      case MissionIconType.speedDemon:
        return 'assets/images/icons/missions/engine_icon.png'; // Engine for speed
      case MissionIconType.precision:
        return 'assets/images/icons/missions/radar_icon.png'; // Radar for precision
      case MissionIconType.comeback:
        return 'assets/images/icons/missions/surviving_hearts_icon.png'; // Hearts for comeback/continue

      // === COLLECTION MISSIONS ===
      case MissionIconType.collectCoins:
        return 'assets/images/icons/missions/gold_star_badge_icon.png'; // Gold star for coin collection
      case MissionIconType.coinStreak:
        return 'assets/images/icons/missions/star_icon.png'; // Star for streaks
      case MissionIconType.bigSpender:
        return 'assets/images/icons/missions/gold_star_badge_icon.png'; // Gold badge for spending
      case MissionIconType.gemHunter:
        return 'assets/images/icons/missions/star_icon.png'; // Star for gems
      case MissionIconType.heartSaver:
        return 'assets/images/icons/missions/surviving_hearts_icon.png'; // Hearts for saving lives
      case MissionIconType.bargainHunter:
        return 'assets/images/icons/missions/gold_star_badge_icon.png'; // Gold badge for bargains

      // === SKILL MISSIONS ===
      case MissionIconType.streakMaster:
        return 'assets/images/icons/missions/gold_trophy.png'; // Gold trophy for streaks
      case MissionIconType.consistency:
        return 'assets/images/icons/missions/silver_trophy.png'; // Silver trophy for consistency
      case MissionIconType.improvement:
        return 'assets/images/icons/missions/bronze_trophy.png'; // Bronze trophy for improvement
      case MissionIconType.endurance:
        return 'assets/images/icons/missions/gold_timer_icon.png'; // Gold timer for endurance
      case MissionIconType.quickReflexes:
        return 'assets/images/icons/missions/radar_icon.png'; // Radar for quick reflexes
      case MissionIconType.noContinue:
        return 'assets/images/icons/missions/gold_trophy.png'; // Gold trophy for no continue

      // === CUSTOMIZATION MISSIONS ===
      case MissionIconType.stylePoints:
        return 'assets/images/icons/missions/star_icon.png'; // Star for style
      case MissionIconType.profilePolish:
        return 'assets/images/icons/missions/radar_icon.png'; // Radar for profile changes
      case MissionIconType.jetCollector:
        return 'assets/images/icons/missions/pilot_helmet_icon.png'; // Pilot helmet for jet collection

      // === SPECIAL MISSIONS ===
      case MissionIconType.dailyChallenge:
        return 'assets/images/icons/missions/gold_star_badge_icon.png'; // Gold badge for daily challenges
      case MissionIconType.communityGoal:
        return 'assets/images/icons/missions/gold_trophy.png'; // Gold trophy for community goals

      // === DEFAULT ===
      case MissionIconType.generic:
        return 'assets/images/icons/missions/star_icon.png'; // Star for generic missions
    }
  }

  IconData _getFallbackIcon(MissionIconType type) {
    switch (type) {
      case MissionIconType.playGames:
        return Icons.videogame_asset;
      case MissionIconType.reachScore:
        return Icons.emoji_events;
      case MissionIconType.surviveTime:
        return Icons.timer;
      case MissionIconType.perfectStart:
        return Icons.flash_on;
      case MissionIconType.closeCalls:
        return Icons.shield;
      case MissionIconType.speedDemon:
        return Icons.speed;
      case MissionIconType.precision:
        return Icons.gps_fixed;
      case MissionIconType.comeback:
        return Icons.favorite;
      case MissionIconType.collectCoins:
        return Icons.monetization_on;
      case MissionIconType.coinStreak:
        return Icons.stars;
      case MissionIconType.bigSpender:
        return Icons.shopping_cart;
      case MissionIconType.gemHunter:
        return Icons.diamond;
      case MissionIconType.heartSaver:
        return Icons.favorite_border;
      case MissionIconType.bargainHunter:
        return Icons.card_giftcard;
      case MissionIconType.streakMaster:
        return Icons.local_fire_department;
      case MissionIconType.consistency:
        return Icons.balance;
      case MissionIconType.improvement:
        return Icons.trending_up;
      case MissionIconType.endurance:
        return Icons.hourglass_bottom;
      case MissionIconType.quickReflexes:
        return Icons.bolt;
      case MissionIconType.noContinue:
        return Icons.military_tech;
      case MissionIconType.stylePoints:
        return Icons.palette;
      case MissionIconType.profilePolish:
        return Icons.person;
      case MissionIconType.jetCollector:
        return Icons.flight;
      case MissionIconType.dailyChallenge:
        return Icons.calendar_today;
      case MissionIconType.communityGoal:
        return Icons.public;
      case MissionIconType.generic:
        return Icons.star;
    }
  }
}

/// Achievement 3D Icon widget
class Achievement3DIcon extends StatelessWidget {
  final AchievementIconType iconType;
  final double size;
  final Color? tintColor;

  const Achievement3DIcon({
    super.key,
    required this.iconType,
    required this.size,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _getIconPath(iconType),
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: tintColor,
        colorBlendMode: tintColor != null ? BlendMode.srcATop : null,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            _getFallbackIcon(iconType),
            size: size,
            color: tintColor ?? Colors.white,
          );
        },
      ),
    );
  }

  String _getIconPath(AchievementIconType type) {
    switch (type) {
      // === SCORE ACHIEVEMENTS ===
      case AchievementIconType.scoreBronze:
        return 'assets/images/icons/missions/bronze_trophy.png';
      case AchievementIconType.scoreSilver:
        return 'assets/images/icons/missions/silver_trophy.png';
      case AchievementIconType.scoreGold:
        return 'assets/images/icons/missions/gold_trophy.png';
      case AchievementIconType.scorePlatinum:
        return 'assets/images/icons/missions/gold_trophy.png'; // Use gold for platinum
      case AchievementIconType.scoreDiamond:
        return 'assets/images/icons/missions/gold_trophy.png'; // Use gold for diamond

      // === SURVIVAL ACHIEVEMENTS ===
      case AchievementIconType.survivalClock:
        return 'assets/images/icons/missions/timer_icon.png';
      case AchievementIconType.survivalHourglass:
        return 'assets/images/icons/missions/gold_timer_icon.png';
      case AchievementIconType.survivalEndurance:
        return 'assets/images/icons/missions/surviving_hearts_icon.png';

      // === COLLECTION ACHIEVEMENTS ===
      case AchievementIconType.coinMaster:
        return 'assets/images/icons/missions/gold_star_badge_icon.png';
      case AchievementIconType.gemCollector:
        return 'assets/images/icons/missions/star_icon.png';
      case AchievementIconType.jetCollector:
        return 'assets/images/icons/missions/pilot_helmet_icon.png';

      // === MASTERY ACHIEVEMENTS ===
      case AchievementIconType.masteryMedal:
        return 'assets/images/icons/missions/gold_star_badge_icon.png';
      case AchievementIconType.masteryCrown:
        return 'assets/images/icons/missions/gold_trophy.png';
      case AchievementIconType.masteryLegend:
        return 'assets/images/icons/missions/gold_trophy.png';

      // === SPECIAL ACHIEVEMENTS ===
      case AchievementIconType.specialStar:
        return 'assets/images/icons/missions/star_icon.png';
      case AchievementIconType.specialShield:
        return 'assets/images/icons/missions/shild_icon.png';
      case AchievementIconType.specialFlame:
        return 'assets/images/icons/missions/engine_icon.png';

      // === DEFAULT ===
      case AchievementIconType.generic:
        return 'assets/images/icons/missions/star_icon.png';
    }
  }

  IconData _getFallbackIcon(AchievementIconType type) {
    switch (type) {
      case AchievementIconType.scoreBronze:
      case AchievementIconType.scoreSilver:
      case AchievementIconType.scoreGold:
      case AchievementIconType.scorePlatinum:
      case AchievementIconType.scoreDiamond:
        return Icons.emoji_events;
      case AchievementIconType.survivalClock:
      case AchievementIconType.survivalHourglass:
      case AchievementIconType.survivalEndurance:
        return Icons.timer;
      case AchievementIconType.coinMaster:
        return Icons.monetization_on;
      case AchievementIconType.gemCollector:
        return Icons.diamond;
      case AchievementIconType.jetCollector:
        return Icons.flight;
      case AchievementIconType.masteryMedal:
        return Icons.military_tech;
      case AchievementIconType.masteryCrown:
      case AchievementIconType.masteryLegend:
        return Icons.workspace_premium;
      case AchievementIconType.specialStar:
        return Icons.star;
      case AchievementIconType.specialShield:
        return Icons.shield;
      case AchievementIconType.specialFlame:
        return Icons.local_fire_department;
      case AchievementIconType.generic:
        return Icons.emoji_events;
    }
  }
}

/// Mission icon types mapped to 3D assets
enum MissionIconType {
  // Gameplay
  playGames,
  reachScore,
  surviveTime,
  perfectStart,
  closeCalls,
  speedDemon,
  precision,
  comeback,

  // Collection
  collectCoins,
  coinStreak,
  bigSpender,
  gemHunter,
  heartSaver,
  bargainHunter,

  // Skill
  streakMaster,
  consistency,
  improvement,
  endurance,
  quickReflexes,
  noContinue,

  // Customization
  stylePoints,
  profilePolish,
  jetCollector,

  // Special
  dailyChallenge,
  communityGoal,

  // Default
  generic,
}

/// Achievement icon types mapped to 3D assets
enum AchievementIconType {
  // Score trophies
  scoreBronze,
  scoreSilver,
  scoreGold,
  scorePlatinum,
  scoreDiamond,

  // Survival
  survivalClock,
  survivalHourglass,
  survivalEndurance,

  // Collection
  coinMaster,
  gemCollector,
  jetCollector,

  // Mastery
  masteryMedal,
  masteryCrown,
  masteryLegend,

  // Special
  specialStar,
  specialShield,
  specialFlame,

  // Default
  generic,
}

/// Helper class to map mission types to icon types
class MissionIconMapper {
  static MissionIconType getIconForMissionType(String missionType) {
    switch (missionType.toLowerCase()) {
      case 'playgames':
      case 'play_games':
        return MissionIconType.playGames;
      case 'reachscore':
      case 'reach_score':
        return MissionIconType.reachScore;
      case 'survivetime':
      case 'survive_time':
        return MissionIconType.surviveTime;
      case 'usecontinue':
      case 'use_continue':
        return MissionIconType.comeback;
      case 'collectcoins':
      case 'collect_coins':
        return MissionIconType.collectCoins;
      case 'changenickname':
      case 'change_nickname':
        return MissionIconType.profilePolish;
      case 'maintainstreak':
      case 'maintain_streak':
        return MissionIconType.streakMaster;
      default:
        return MissionIconType.generic;
    }
  }
}

/// Helper class to map achievement categories to icon types
class AchievementIconMapper {
  static AchievementIconType getIconForAchievement(
    String category,
    String rarity,
  ) {
    switch (category.toLowerCase()) {
      case 'score':
        switch (rarity.toLowerCase()) {
          case 'bronze':
            return AchievementIconType.scoreBronze;
          case 'silver':
            return AchievementIconType.scoreSilver;
          case 'gold':
            return AchievementIconType.scoreGold;
          case 'platinum':
            return AchievementIconType.scorePlatinum;
          case 'diamond':
            return AchievementIconType.scoreDiamond;
          default:
            return AchievementIconType.scoreBronze;
        }
      case 'survival':
        return AchievementIconType.survivalClock;
      case 'collection':
        return AchievementIconType.coinMaster;
      case 'mastery':
        return AchievementIconType.masteryMedal;
      case 'special':
        return AchievementIconType.specialStar;
      default:
        return AchievementIconType.generic;
    }
  }
}

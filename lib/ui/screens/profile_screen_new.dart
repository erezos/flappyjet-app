/// 👤 Profile Screen - New Design
/// 
/// Modern "Pilot License" style profile page with collectible jet album.
/// Follows mobile gaming best practices and Flame game engine standards.
library;

import 'package:flutter/material.dart';
import '../../core/debug_logger.dart';
import '../../game/systems/player_identity_manager.dart';
import '../../game/systems/profile_manager.dart';
import '../../game/systems/inventory_manager.dart';
import '../utils/responsive_config.dart';
import '../widgets/profile/profile_pilot_license_header.dart';
import '../widgets/profile/profile_hero_section.dart';
import '../widgets/profile/profile_stats_grid.dart';
import '../widgets/profile/profile_jet_collection_album.dart';
import '../widgets/profile/profile_data_aggregator.dart';
import '../widgets/settings_toggle_buttons.dart';
import '../../game/systems/audio_settings_manager.dart';

class ProfileScreenNew extends StatefulWidget {
  const ProfileScreenNew({super.key});

  @override
  State<ProfileScreenNew> createState() => _ProfileScreenNewState();
}

class _ProfileScreenNewState extends State<ProfileScreenNew> with WidgetsBindingObserver {
  final PlayerIdentityManager _playerIdentity = PlayerIdentityManager();
  final ProfileManager _profile = ProfileManager();
  final InventoryManager _inventory = InventoryManager();
  final ProfileDataAggregator _dataAggregator = ProfileDataAggregator();
  final AudioSettingsManager _audioSettings = AudioSettingsManager();
  final TextEditingController _nameCtrl = TextEditingController();
  
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dataAggregator.addListener(_refresh);
    _playerIdentity.addListener(_refresh);
    _profile.addListener(_refresh);
    _inventory.addListener(_refresh);
    _audioSettings.addListener(_refresh);
    _audioSettings.initialize();
    _initializeAsync();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ Refresh profile data when app resumes (user might have completed a level)
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _dataAggregator.refresh();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Refresh profile data when screen becomes visible
    if (_isInitialized) {
      _dataAggregator.refresh();
    }
  }

  Future<void> _initializeAsync() async {
    try {
      // Initialize dependencies
      // Note: InventoryManager is already initialized in main.dart (singleton)
      await _playerIdentity.initialize();
      await _profile.initialize();
      // _inventory is already initialized in main.dart, no need to re-initialize
      await _dataAggregator.initialize();
      
      // Set nickname controller
      if (mounted) {
        _nameCtrl.text = _playerIdentity.playerName.isNotEmpty
            ? _playerIdentity.playerName
            : _profile.nickname;
        
        // Refresh data
        await _dataAggregator.refresh();
        
        setState(() {
          _isInitialized = true;
        });
      }
      
      safePrint('✅ ProfileScreenNew initialized');
    } catch (e) {
      safePrint('❌ ProfileScreenNew initialization error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dataAggregator.removeListener(_refresh);
    _playerIdentity.removeListener(_refresh);
    _profile.removeListener(_refresh);
    _inventory.removeListener(_refresh);
    _audioSettings.removeListener(_refresh);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      _nameCtrl.text = _playerIdentity.playerName.isNotEmpty
          ? _playerIdentity.playerName
          : _profile.nickname;
      setState(() {});
    }
  }

  Future<void> _handleNicknameSave() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Saving nickname...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _playerIdentity.updatePlayerName(_nameCtrl.text);
      final syncSuccess = await _playerIdentity.forceNicknameSyncToBackend();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (syncSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Nickname saved! ✅'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nickname saved locally. Sync pending...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Refresh profile data
      await _dataAggregator.refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final profileData = _dataAggregator.profileData;
    
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/sky_with_clouds.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveConfig.responsivePadding(16.0, screenSize),
              vertical: ResponsiveConfig.responsivePadding(12.0, screenSize),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pilot License Header
                ProfilePilotLicenseHeader(),
                
                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),
                
                // Hero Section
                ProfileHeroSection(
                  nicknameController: _nameCtrl,
                  onNicknameSave: _handleNicknameSave,
                  profileData: profileData,
                ),
                
                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),
                
                // Stats Grid
                ProfileStatsGrid(profileData: profileData),
                
                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),
                
                // Jet Collection Album
                ProfileJetCollectionAlbum(
                  profileData: profileData,
                ),
                
                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),
                
                // Settings Section (Music, Sound, Privacy)
                _buildSettingsSection(context, screenSize),
                
                SizedBox(height: ResponsiveConfig.responsivePadding(20.0, screenSize)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsSection(BuildContext context, Size screenSize) {
    final isTablet = ResponsiveConfig.isTablet(screenSize);
    final isLargeTablet = ResponsiveConfig.isLargeTablet(screenSize);
    
    return Container(
      padding: EdgeInsets.all(ResponsiveConfig.responsivePadding(16.0, screenSize)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveConfig.responsiveSize(16.0, screenSize)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: ResponsiveConfig.responsiveSize(2.0, screenSize),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: ResponsiveConfig.responsiveSize(12.0, screenSize),
            offset: Offset(0, ResponsiveConfig.responsiveSize(4.0, screenSize)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Settings Title
          Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: ResponsiveConfig.responsiveFontSize(
                isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0,
                screenSize,
                context,
              ),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: ResponsiveConfig.responsiveSize(1.5, screenSize),
            ),
          ),
          
          SizedBox(height: ResponsiveConfig.responsivePadding(12.0, screenSize)),
          
          // Settings Toggle Buttons
          SettingsToggleButtonsRow(
            buttonSize: ResponsiveConfig.responsiveIconSize(
              isLargeTablet ? 32.0 : isTablet ? 28.0 : 24.0,
              screenSize,
            ),
            spacing: ResponsiveConfig.responsivePadding(20.0, screenSize),
          ),
        ],
      ),
    );
  }
}


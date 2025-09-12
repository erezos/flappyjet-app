import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../core/debug_logger.dart';

import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import '../../services/prize_distribution_service.dart';

import '../../game/systems/inventory_manager.dart';
import '../../game/systems/player_identity_manager.dart';
import '../widgets/tournament/tournament_header.dart';
import '../widgets/tournament/tournament_leaderboard_widget.dart';
import '../widgets/tournament/tournament_registration_card.dart';
import '../widgets/tournament/tournament_stats_card.dart';
import '../widgets/tournament/tournament_prize_pool_widget.dart';
import '../widgets/tournament/prize_notification_widget.dart';

/// Modern, colorful tournament screen with engaging animations
class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _contentController;
  late final TournamentService _tournamentService;
  
  Tournament? _currentTournament;
  bool _isLoading = true;
  bool _isPlayerRegistered = false;
  String? _error;
  
  // Animation controllers for different sections
  late final AnimationController _headerController;
  late final AnimationController _leaderboardController;
  late final AnimationController _statsController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _leaderboardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Initialize tournament service
    _tournamentService = TournamentService(
      baseUrl: 'https://flappyjet-backend-production.up.railway.app',
    );
    
    // Load tournament data
    _loadTournamentData();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _headerController.dispose();
    _leaderboardController.dispose();
    _statsController.dispose();
    _tournamentService.dispose();
    super.dispose();
  }

  Future<void> _loadTournamentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _tournamentService.getCurrentTournament();
      
      if (result.isSuccess) {
        setState(() {
          _currentTournament = result.data;
          _isLoading = false;
        });
        
        // Check if player is already registered
        await _checkPlayerRegistration();
        
        // Start animations
        _contentController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _headerController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        _leaderboardController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _statsController.forward();
      } else {
        setState(() {
          _error = result.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load tournament data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Prize Distribution Service
        ChangeNotifierProvider(
          create: (context) => PrizeDistributionService(
            baseUrl: 'https://flappyjet-backend-production.up.railway.app',
            tournamentService: _tournamentService,
            inventoryManager: context.read<InventoryManager>(),
          ),
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // Main tournament content
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Container(
                  decoration: _buildAnimatedBackground(),
                  child: SafeArea(
                    child: _isLoading
                        ? _buildLoadingState()
                        : _error != null
                            ? _buildErrorState()
                            : _buildTournamentContent(),
                  ),
                );
              },
            ),

            // Prize notifications overlay
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: SafeArea(
                child: PrizeNotificationWidget(
                  onNotificationTap: () {
                    // Refresh tournament data when prize is claimed
                    _loadTournamentData();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates an animated gradient background with floating particles
  BoxDecoration _buildAnimatedBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            (math.sin(_backgroundController.value * 2 * math.pi) + 1) / 2,
          )!,
          Color.lerp(
            const Color(0xFF0F3460),
            const Color(0xFF533483),
            (math.cos(_backgroundController.value * 2 * math.pi) + 1) / 2,
          )!,
          Color.lerp(
            const Color(0xFF533483),
            const Color(0xFFE94560),
            (math.sin(_backgroundController.value * 4 * math.pi) + 1) / 4,
          )!,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 1000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
                duration: 1000.ms,
              ),
          const SizedBox(height: 24),
          Text(
            'Loading Tournament...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 12),
          Text(
            'Preparing epic battles!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          )
              .animate()
              .fadeIn(duration: 800.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 50,
              ),
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .shake(duration: 800.ms, delay: 600.ms),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 500.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadTournamentData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 700.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
                .shimmer(duration: 2000.ms, delay: 1000.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Tournament Header
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _headerController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  50 * (1 - _headerController.value),
                ),
                child: Opacity(
                  opacity: _headerController.value,
                  child: TournamentHeader(
                    tournament: _currentTournament,
                  ),
                ),
              );
            },
          ),
        ),

        // Prize Pool Widget
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _contentController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _contentController.value),
                child: Opacity(
                  opacity: _contentController.value,
                  child: TournamentPrizePoolWidget(
                    tournament: _currentTournament,
                  ),
                ),
              );
            },
          ),
        ),

        // Registration Card (if not registered and registration is open)
        if (_currentTournament?.isRegistrationOpen == true && !_isPlayerRegistered)
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -100 * (1 - _contentController.value),
                    0,
                  ),
                  child: Opacity(
                    opacity: _contentController.value,
                    child: TournamentRegistrationCard(
                      tournament: _currentTournament!,
                      onRegister: _handleRegistration,
                    ),
                  ),
                );
              },
            ),
          ),

        // Tournament Stats
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _statsController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  100 * (1 - _statsController.value),
                  0,
                ),
                child: Opacity(
                  opacity: _statsController.value,
                  child: TournamentStatsCard(
                    tournament: _currentTournament,
                  ),
                ),
              );
            },
          ),
        ),

        // Leaderboard
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _leaderboardController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  100 * (1 - _leaderboardController.value),
                ),
                child: Opacity(
                  opacity: _leaderboardController.value,
                  child: TournamentLeaderboardWidget(
                    tournament: _currentTournament,
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Future<void> _checkPlayerRegistration() async {
    if (_currentTournament == null) return;
    
    try {
      final playerIdentity = PlayerIdentityManager();
      if (!playerIdentity.isBackendRegistered) {
        _isPlayerRegistered = false;
        return;
      }

      // Use unified tournament session endpoint to check registration status
      final sessionResult = await _tournamentService.handleTournamentSession(
        tournamentId: _currentTournament!.id,
        action: 'get_status',
      );

      if (sessionResult.isSuccess && sessionResult.data != null) {
        final data = sessionResult.data!;
        setState(() {
          _isPlayerRegistered = data.player.registered;
        });
        safePrint('🏆 Player registration check: ${_isPlayerRegistered ? 'Registered (Rank: ${data.player.rank}, Score: ${data.player.bestScore})' : 'Not registered'}');
      } else {
        setState(() {
          _isPlayerRegistered = false;
        });
        safePrint('⚠️ Could not check registration status: ${sessionResult.error}');
      }
    } catch (e) {
      safePrint('⚠️ Failed to check player registration: $e');
      setState(() {
        _isPlayerRegistered = false;
      });
    }
  }

  Future<void> _handleRegistration() async {
    if (_currentTournament == null) {
      _showErrorMessage('No active tournament available');
      return;
    }

    try {
      // Get player identity
      final playerIdentity = PlayerIdentityManager();

      // Ensure player is registered with backend
      if (!playerIdentity.isBackendRegistered) {
        _showErrorMessage('Please restart the app to complete registration');
        return;
      }

      // Get or create auth token
      String authToken = playerIdentity.authToken;
      if (authToken.isEmpty) {
        authToken = 'temp_${playerIdentity.playerId}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
      }

      // Create tournament service and register
      final tournamentService = TournamentService(
        baseUrl: 'https://flappyjet-backend-production.up.railway.app'
      );

      final result = await tournamentService.registerForTournament(
        tournamentId: _currentTournament!.id,
        playerName: playerIdentity.playerName,
        authToken: authToken,
      );

      if (result.isSuccess) {
        _showSuccessMessage('Successfully registered for ${_currentTournament!.name}!');
        
        // Update registration status and refresh tournament data
        setState(() {
          _isPlayerRegistered = true;
        });
        await _loadTournamentData();
      } else {
        _showErrorMessage('Registration failed: ${result.error}');
      }
    } catch (e) {
      safePrint('Tournament registration error: $e');
      _showErrorMessage('Registration failed. Please try again.');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
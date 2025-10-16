/// 🗺️ STORY MODE - ZONE SELECTOR DROPDOWN
/// 
/// Beautiful dropdown for zone navigation with FlappyJet's design language.
/// Features: Gradient backgrounds, 3D text, smooth animations, locked/unlocked states.
library;

import 'package:flutter/material.dart';
import '../../models/level_data_schema.dart';
import '../../core/debug_logger.dart';

class ZoneSelectorDropdown extends StatefulWidget {
  final List<ZoneData> allZones;
  final int currentZone;
  final Set<int> unlockedZones;
  final Function(int zoneId) onZoneSelected;

  const ZoneSelectorDropdown({
    super.key,
    required this.allZones,
    required this.currentZone,
    required this.unlockedZones,
    required this.onZoneSelected,
  });

  @override
  State<ZoneSelectorDropdown> createState() => _ZoneSelectorDropdownState();
}

class _ZoneSelectorDropdownState extends State<ZoneSelectorDropdown>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectZone(int zoneId) {
    if (!widget.unlockedZones.contains(zoneId)) {
      safePrint('🔒 Zone $zoneId is locked');
      _showLockedZoneMessage(zoneId);
      return;
    }

    safePrint('🗺️ Zone $zoneId selected');
    widget.onZoneSelected(zoneId);
    _toggleDropdown();
  }

  void _showLockedZoneMessage(int zoneId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Complete Zone ${zoneId - 1} to unlock this zone!',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1A237E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getZoneEmoji(int zoneId) {
    switch (zoneId) {
      case 1:
        return '🌊';
      case 2:
        return '🏜️';
      case 3:
        return '🌋';
      case 4:
        return '❄️';
      case 5:
        return '🌌';
      default:
        return '🗺️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentZoneData = widget.allZones.firstWhere(
      (zone) => zone.id == widget.currentZone,
      orElse: () => widget.allZones.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropdown Button
        _buildDropdownButton(currentZoneData),

        // Dropdown Menu
        if (_isExpanded) _buildDropdownMenu(),
      ],
    );
  }

  Widget _buildDropdownButton(ZoneData currentZone) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          // Modern card-style with vibrant gradient border
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade400,
              Colors.orange.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            if (_isExpanded)
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            // Inner card with deep blue gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E3A8A),
                const Color(0xFF312E81),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zone emoji in a badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade300,
                      Colors.orange.shade400,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getZoneEmoji(currentZone.id),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),

              // Zone name with modern typography
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ZONE ${currentZone.id}',
                      style: TextStyle(
                        color: Colors.amber.shade200,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      currentZone.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Dropdown arrow in a pill
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: Colors.amber.shade300,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownMenu() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          // Gradient border like the button
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade400,
              Colors.orange.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            // Deep blue background
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF312E81),
              ],
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              children: widget.allZones.map((zone) {
                return _buildZoneMenuItem(zone);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneMenuItem(ZoneData zone) {
    final isUnlocked = widget.unlockedZones.contains(zone.id);
    final isCurrent = zone.id == widget.currentZone;

    return Material(
      color: isCurrent
          ? Colors.amber.withOpacity(0.2)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _selectZone(zone.id),
        splashColor: Colors.amber.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                ),
                child: Icon(
                  isUnlocked
                      ? (isCurrent ? Icons.play_arrow : Icons.check_circle)
                      : Icons.lock,
                  color: isUnlocked ? Colors.greenAccent : Colors.white38,
                  size: 16,
                ),
              ),

              const SizedBox(width: 12),

              // Zone emoji
              Text(
                _getZoneEmoji(zone.id),
                style: TextStyle(
                  fontSize: 20,
                  color: isUnlocked ? Colors.white : Colors.white38,
                ),
              ),

              const SizedBox(width: 8),

              // Zone name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONE ${zone.id}',
                      style: TextStyle(
                        color: isUnlocked
                            ? Colors.amber.shade300
                            : Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      zone.name,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white38,
                        fontSize: 14,
                        fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow for current zone
              if (isCurrent)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.amber,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}


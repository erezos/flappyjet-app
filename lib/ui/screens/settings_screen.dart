/// ⚙️ Settings Screen
library;
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEnabled = true;
  bool musicEnabled = true;
  bool hapticEnabled = true;
  double soundVolume = 0.8;
  double musicVolume = 0.6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF374151), Color(0xFF1F2937)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'SETTINGS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              // Settings Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSettingCard(
                      'AUDIO',
                      [
                        _buildSwitchSetting('Sound Effects', soundEnabled, (value) {
                          setState(() => soundEnabled = value);
                        }),
                        _buildSwitchSetting('Music', musicEnabled, (value) {
                          setState(() => musicEnabled = value);
                        }),
                        _buildSliderSetting('Sound Volume', soundVolume, (value) {
                          setState(() => soundVolume = value);
                        }, enabled: soundEnabled),
                        _buildSliderSetting('Music Volume', musicVolume, (value) {
                          setState(() => musicVolume = value);
                        }, enabled: musicEnabled),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSettingCard(
                      'CONTROLS',
                      [
                        _buildSwitchSetting('Haptic Feedback', hapticEnabled, (value) {
                          setState(() => hapticEnabled = value);
                        }),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSettingCard(
                      'GAME',
                      [
                        _buildButtonSetting('Reset High Score', Icons.refresh, () {
                          _showResetDialog();
                        }),
                        _buildButtonSetting('Clear Game Data', Icons.delete, () {
                          _showClearDataDialog();
                        }),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSettingCard(
                      'ABOUT',
                      [
                        _buildInfoSetting('Version', '1.0.0'),
                        _buildButtonSetting('Rate Us', Icons.star, () {
                          // App store rating integration ready
                        }),
                        _buildButtonSetting('Privacy Policy', Icons.privacy_tip, () {
                          // Privacy policy integration ready
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF32CD32),
      ),
    );
  }

  Widget _buildSliderSetting(String title, double value, ValueChanged<double> onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey,
            ),
          ),
          Slider(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: const Color(0xFF32CD32),
            inactiveColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildButtonSetting(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoSetting(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: Text(
        value,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset High Score'),
        content: const Text('Are you sure you want to reset your high score?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // High score reset functionality ready
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('High score reset!')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Game Data'),
        content: const Text('This will delete all your progress. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Game data clearing functionality ready
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Game data cleared!')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
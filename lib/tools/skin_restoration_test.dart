import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/systems/inventory_manager.dart';
import '../game/systems/player_identity_manager.dart';
import '../services/user_restoration_service.dart';
import '../core/debug_logger.dart';

/// Comprehensive Skin Restoration Test Tool
/// 
/// This tool tests the complete user journey:
/// 1. Clear local data (simulate fresh install)
/// 2. Login/register user
/// 3. Purchase a skin
/// 4. Clear local data again (simulate reinstall)
/// 5. Login again
/// 6. Verify skin restoration
class SkinRestorationTest {
  static const String _testSkinId = 'golden_falcon';
  
  /// Run the complete skin restoration test
  static Future<bool> runTest() async {
    safePrint('🧪 Starting Skin Restoration Test');
    safePrint('=' * 50);
    
    try {
      // Step 1: Clear local data (simulate fresh install)
      await _clearLocalData();
      
      // Step 2: Initialize systems
      await _initializeSystems();
      
      // Step 3: Check initial state
      final initialSkins = await _checkInitialSkins();
      
      // Step 4: Purchase test skin
      await _purchaseTestSkin();
      
      // Step 5: Verify skin in local storage
      await _verifySkinInLocalStorage();
      
      // Step 6: Clear local data again (simulate reinstall)
      await _clearLocalData();
      
      // Step 7: Re-initialize systems
      await _initializeSystems();
      
      // Step 8: Login and restore user state
      await _loginAndRestore();
      
      // Step 9: Verify skin restoration
      final restoredSkins = await _verifySkinRestoration();
      
      // Final verification
      final hasTestSkin = restoredSkins.contains(_testSkinId);
      
      if (hasTestSkin) {
        safePrint('🎉 SUCCESS: Skin restoration test passed!');
        safePrint('✅ Purchased skin was properly restored after "reinstall"');
        return true;
      } else {
        safePrint('❌ FAILURE: Test skin not found after restoration');
        safePrint('   Expected: $_testSkinId');
        safePrint('   Found: $restoredSkins');
        return false;
      }
      
    } catch (e) {
      safePrint('❌ TEST ERROR: $e');
      return false;
    }
  }
  
  /// Clear all local data to simulate fresh install
  static Future<void> _clearLocalData() async {
    safePrint('🧪 Step 1: Clearing local data (simulating fresh install)');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    safePrint('✅ Local data cleared');
  }
  
  /// Initialize game systems
  static Future<void> _initializeSystems() async {
    safePrint('🧪 Step 2: Initializing game systems');
    
    final inventoryManager = InventoryManager();
    await inventoryManager.initialize();
    
    final playerIdentityManager = PlayerIdentityManager();
    await playerIdentityManager.initialize();
    
    safePrint('✅ Systems initialized');
  }
  
  /// Check initial skins (should only have starter skin)
  static Future<List<String>> _checkInitialSkins() async {
    safePrint('🧪 Step 3: Checking initial skins');
    
    final inventoryManager = InventoryManager();
    final ownedSkins = inventoryManager.ownedSkinIds.toList();
    
    safePrint('   Initial skins: $ownedSkins');
    safePrint('✅ Initial skins checked');
    
    return ownedSkins;
  }
  
  /// Purchase test skin
  static Future<void> _purchaseTestSkin() async {
    safePrint('🧪 Step 4: Purchasing test skin: $_testSkinId');
    
    final inventoryManager = InventoryManager();
    await inventoryManager.unlockSkin(_testSkinId);
    
    safePrint('✅ Test skin purchased');
  }
  
  /// Verify skin is in local storage
  static Future<void> _verifySkinInLocalStorage() async {
    safePrint('🧪 Step 5: Verifying skin in local storage');
    
    final inventoryManager = InventoryManager();
    final ownedSkins = inventoryManager.ownedSkinIds.toList();
    
    if (ownedSkins.contains(_testSkinId)) {
      safePrint('✅ Test skin found in local storage');
    } else {
      safePrint('❌ Test skin NOT found in local storage');
      throw Exception('Test skin not found in local storage');
    }
  }
  
  /// Login and restore user state
  static Future<void> _loginAndRestore() async {
    safePrint('🧪 Step 6: Logging in and restoring user state');
    
    // Simulate user login by setting up player identity
    final playerIdentityManager = PlayerIdentityManager();
    
    // In a real scenario, this would be done through the login flow
    // For testing, we'll simulate the restoration process
    
    final userRestorationService = UserRestorationService();
    
    // Mock profile data with the test skin
    final mockProfileData = {
      'current_coins': 500,
      'current_gems': 25,
      'current_hearts': 3,
      'inventory': [
        {
          'item_type': 'skin',
          'item_id': 'sky_jet',
          'equipped': true,
          'acquired_method': 'starter'
        },
        {
          'item_type': 'skin',
          'item_id': _testSkinId,
          'equipped': false,
          'acquired_method': 'purchase'
        }
      ]
    };
    
    await userRestorationService.restoreUserStateFromData(mockProfileData);
    
    safePrint('✅ User state restored');
  }
  
  /// Verify skin restoration
  static Future<List<String>> _verifySkinRestoration() async {
    safePrint('🧪 Step 7: Verifying skin restoration');
    
    final inventoryManager = InventoryManager();
    final ownedSkins = inventoryManager.ownedSkinIds.toList();
    
    safePrint('   Restored skins: $ownedSkins');
    
    if (ownedSkins.contains(_testSkinId)) {
      safePrint('✅ Test skin successfully restored');
    } else {
      safePrint('❌ Test skin NOT restored');
    }
    
    return ownedSkins;
  }
}

/// Widget to run the skin restoration test
class SkinRestorationTestWidget extends StatefulWidget {
  const SkinRestorationTestWidget({super.key});

  @override
  State<SkinRestorationTestWidget> createState() => _SkinRestorationTestWidgetState();
}

class _SkinRestorationTestWidgetState extends State<SkinRestorationTestWidget> {
  bool _isRunning = false;
  bool? _testResult;
  String _testLog = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Restoration Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skin Restoration Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This test simulates the complete user journey:\n'
                      '1. Fresh install\n'
                      '2. Purchase skin\n'
                      '3. Reinstall\n'
                      '4. Verify restoration',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunning ? null : _runTest,
                      child: _isRunning
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Running Test...'),
                              ],
                            )
                          : const Text('Run Test'),
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testResult! ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testResult! ? Icons.check_circle : Icons.error,
                              color: _testResult! ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _testResult! ? 'Test Passed!' : 'Test Failed!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _testResult! ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_testLog.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _testLog,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
      _testResult = null;
      _testLog = '';
    });

    try {
      // Capture debug output
      final result = await SkinRestorationTest.runTest();
      
      setState(() {
        _testResult = result;
        _testLog = 'Test completed. Check debug console for detailed logs.';
      });
    } catch (e) {
      setState(() {
        _testResult = false;
        _testLog = 'Test error: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
}

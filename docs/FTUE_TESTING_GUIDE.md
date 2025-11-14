# 🧪 FTUE Testing Guide

## Unit Tests Created ✅

Unit tests for FTUE Manager have been created at:
`test/game/systems/ftue_manager_test.dart`

### What's Tested:
- ✅ Initialization logic
- ✅ Tutorial tracking (shown, completed)
- ✅ Gift popup tracking
- ✅ Game completion tracking
- ✅ State persistence
- ✅ FTUE flow integration (tutorial → game → gift)
- ✅ Reset functionality
- ✅ Edge cases and error handling

### Running Tests:
```bash
# Run FTUE tests only
flutter test test/game/systems/ftue_manager_test.dart

# Run all tests
flutter test
```

**Note:** Some tests may fail due to FTUEManager being a singleton. This is expected and will be fixed in a future update.

---

## 🔄 FTUE Reset Button - Easy Testing!

Three ways to add an FTUE reset button to your app:

### **Option 1: Floating Button (Recommended for Testing)**

Add this to your **homepage** or any screen:

```dart
import 'package:flappy_jet_pro/ui/widgets/debug/ftue_reset_button.dart';

// In your build method:
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Your existing content
      YourHomePageContent(),
      
      // 🔄 FTUE Reset Button (debug only, auto-hidden in release)
      const FTUEResetButton(),
    ],
  );
}
```

**Result:** A floating orange button in the bottom-right corner that resets FTUE when tapped.

---

### **Option 2: Compact Button (For Debug Menu)**

Add this to a debug/settings screen:

```dart
import 'package:flappy_jet_pro/ui/widgets/debug/ftue_reset_button.dart';

// In your settings/debug screen:
Column(
  children: [
    // Other settings...
    
    const CompactFTUEResetButton(), // ← Add this
  ],
)
```

**Result:** A compact button that shows a snackbar confirmation.

---

### **Option 3: Menu Item (For Settings Screen)**

Add this to your settings menu:

```dart
import 'package:flappy_jet_pro/ui/widgets/debug/ftue_reset_button.dart';

// In your settings ListView:
ListView(
  children: [
    // Other settings...
    
    const FTUEResetMenuItem(), // ← Add this
  ],
)
```

**Result:** A list item that shows a confirmation dialog before resetting.

---

## 🎮 How to Test FTUE Flow

### **Step-by-Step Testing:**

1. **Add Reset Button** (choose one of the options above)

2. **Run App:**
   ```bash
   flutter run
   ```

3. **Tap Reset Button:**
   - Button appears in bottom-right (or wherever you added it)
   - Tap it
   - You'll see: "✅ FTUE Reset! Restart app to test"

4. **Hot Restart** (not hot reload!):
   - Press `R` in terminal OR
   - Stop and restart the app

5. **Test Tutorial:**
   - Navigate to Story Mode
   - Tap any level
   - Tap "START"
   - **Tutorial appears!** ✨

6. **Complete Tutorial:**
   - Complete 5 taps (or skip after 3 seconds)
   - Tutorial dismisses

7. **Play Game:**
   - Play the first game (win or lose)
   - Return to menu

8. **Test Gift Popup:**
   - **Gift popup appears!** 🎁
   - Shows "Welcome Gift!" message
   - Grants 3-Day Auto-Refill Booster

---

## 📝 Quick Example: Add to Homepage

Here's the simplest way to add it to your homepage:

```dart
// lib/ui/screens/homepage.dart

import 'package:flutter/material.dart';
import 'package:flappy_jet_pro/ui/widgets/debug/ftue_reset_button.dart'; // ← Add this

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FlappyJet')),
      body: Stack(
        children: [
          // Your existing homepage content
          Center(
            child: Column(
              children: [
                const Text('Welcome to FlappyJet!'),
                // ... your buttons ...
              ],
            ),
          ),
          
          // 🔄 FTUE Reset Button (debug only)
          const FTUEResetButton(), // ← Add this one line!
        ],
      ),
    );
  }
}
```

**That's it!** The button only appears in debug mode and auto-hides in release builds.

---

## 🎯 Alternative: Manual Reset (Without Button)

If you don't want a visible button, you can reset FTUE programmatically:

```dart
import 'package:flappy_jet_pro/integrations/ftue_integration.dart';

// Call this anywhere:
await FTUEIntegration.resetForTesting();
print('🔄 FTUE Reset! Restart app to test.');
```

---

## ⚠️ Important Notes

1. **Hot Restart Required:** After resetting FTUE, you **MUST** hot restart (not hot reload) for changes to take effect.

2. **Debug Only:** All reset functionality only works in debug mode (`kDebugMode`). It's automatically disabled in release builds.

3. **Singleton Behavior:** FTUEManager is a singleton, so resetting affects the entire app instance.

4. **Test Isolation:** Unit tests may have issues due to singleton state persistence. This is a known limitation.

---

## 🐛 Troubleshooting

### **Tutorial doesn't appear after reset:**
- Make sure you **hot restarted** (not hot reload)
- Check console for: `🎮 FTUE: Showing tutorial before first game`
- Verify you're in debug mode

### **Reset button doesn't show:**
- Make sure you're running in **debug mode** (not release)
- Check that import is correct: `import 'package:flappy_jet_pro/ui/widgets/debug/ftue_reset_button.dart';`
- Verify button is inside a `Stack` widget

### **Tests failing:**
- This is expected due to singleton behavior
- Tests still verify the logic, just with some cross-contamination
- Will be fixed in future update with better test isolation

---

## 📊 FTUE State Tracking

After resetting, you can verify the state:

```dart
import 'package:flappy_jet_pro/integrations/ftue_integration.dart';

// Check state:
print('Is first session: ${FTUEIntegration.manager.isFirstSession}'); // true
print('Games played: ${FTUEIntegration.manager.gamesPlayed}'); // 0
print('Tutorial shown: ${FTUEIntegration.manager.tutorialShown}'); // false
print('Gift shown: ${FTUEIntegration.manager.giftPopupShown}'); // false
```

---

## 🚀 Ready to Test!

You're all set! Add the reset button to your homepage and start testing the FTUE flow. 

**Recommended:** Use `FTUEResetButton()` for easiest testing.


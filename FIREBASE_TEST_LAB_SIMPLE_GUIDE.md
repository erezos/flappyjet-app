# 🎯 Firebase Test Lab - Simple Popup Testing Guide

## ✅ Yes, That's Exactly the Idea!

You build a test that:
1. **Opens popup #1** → Takes screenshot → Closes it
2. **Opens popup #2** → Takes screenshot → Closes it  
3. **Opens popup #3** → Takes screenshot → Closes it
4. And so on...

Firebase Test Lab will automatically:
- ✅ Take screenshots at key moments
- ✅ Record videos of the entire test
- ✅ Capture logs
- ✅ Run on multiple devices

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Create the Test File

I've created `integration_test/popup_screenshot_test.dart` for you. It:
- Opens each popup one by one
- Takes screenshots (Firebase does this automatically)
- Verifies popups are visible
- Closes each popup
- Moves to the next one

### Step 2: Build Test APK

```bash
# Build the app
flutter build apk --release

# Build the test (this creates the instrumentation test)
flutter build apk --debug --target=integration_test/popup_screenshot_test.dart
```

### Step 3: Run on Firebase Test Lab

```bash
gcloud firebase test android run \
  --app build/app/outputs/flutter-apk/app-release.apk \
  --test build/app/outputs/flutter-apk/app-debug-androidTest.apk \
  --device model=Pixel5,version=31 \
  --device model=Pixel6,version=32 \
  --device model=GalaxyS21,version=31
```

---

## 📸 What You'll See in Firebase Console

After the test runs, you'll see:

1. **Videos** - Watch the entire test run
   - See each popup open
   - See screenshots being taken
   - See popups close

2. **Screenshots** - One for each popup
   - Daily Streak Popup screenshot
   - Rate Us Popup screenshot
   - Tournament Popup screenshot
   - etc.

3. **Logs** - See what happened
   - "Testing: Daily Streak Popup"
   - "Screenshot captured"
   - "Popup closed"

---

## 🎯 The Test Flow

```
App Starts
    ↓
Open Daily Streak Popup
    ↓
Take Screenshot (automatic)
    ↓
Verify it's visible
    ↓
Click "X" or "Claim"
    ↓
Wait for close animation
    ↓
Open Rate Us Popup
    ↓
Take Screenshot (automatic)
    ↓
Verify it's visible
    ↓
Click "Maybe Later"
    ↓
... and so on
```

---

## 🔧 Customize for Your Popups

Edit `integration_test/popup_screenshot_test.dart`:

1. **Find the trigger** - How to open each popup
   ```dart
   triggerAction: () async {
     // Find button and tap it
     final button = find.byKey(Key('your_button_key'));
     await tester.tap(button);
   }
   ```

2. **Verify content** - What text/elements should be visible
   ```dart
   verifyPopup: () {
     expect(find.text('Your Popup Title'), findsOneWidget);
   }
   ```

3. **Close action** - How to close the popup
   ```dart
   closeAction: () async {
     final closeButton = find.byIcon(Icons.close);
     await tester.tap(closeButton);
   }
   ```

---

## 🎬 Example: Complete Flow

```dart
// 1. Open Daily Streak Popup
await tester.tap(find.byKey(Key('daily_streak_button')));
await tester.pumpAndSettle();
// → Firebase takes screenshot here automatically

// 2. Verify it's visible
expect(find.text('Daily Streak'), findsOneWidget);

// 3. Close it
await tester.tap(find.byIcon(Icons.close));
await tester.pumpAndSettle();

// 4. Move to next popup
// ... repeat for each popup
```

---

## ✅ Benefits

- ✅ **Guaranteed Coverage** - Every popup is tested
- ✅ **Visual Verification** - Screenshots prove popups appear
- ✅ **Multiple Devices** - Test on 10+ devices automatically
- ✅ **Videos** - See exactly what happened
- ✅ **No Manual Work** - Fully automated

---

## 🚨 Important Notes

1. **Firebase takes screenshots automatically** - You don't need to code it
2. **Videos are recorded** - You can watch the entire test
3. **Screenshots are at key moments** - When popups appear
4. **Test runs on real devices** - Not emulators

---

## 📊 What Gets Tested

- ✅ Popup appears correctly
- ✅ Popup content is visible
- ✅ No overflow errors
- ✅ Close button works
- ✅ Responsive on different screen sizes
- ✅ Animations complete

---

## 🎯 Next Steps

1. **Edit the test file** - Add your specific popup triggers
2. **Run locally first** - `flutter test integration_test/popup_screenshot_test.dart`
3. **Build test APK** - `flutter build apk --debug --target=integration_test/popup_screenshot_test.dart`
4. **Upload to Firebase** - Use the gcloud command above
5. **View results** - Check Firebase Console for screenshots and videos

---

**That's it! Simple and effective! 🎉**


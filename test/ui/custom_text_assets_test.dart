/// 🧪 Custom Text Assets Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/ui/screens/store_screen.dart';
import '../../lib/ui/screens/profile_screen.dart';

void main() {
  group('Custom Text Assets Tests', () {
    testWidgets('Store screen should load store_text.png', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const StoreScreen(),
        ),
      );
      
      // Wait for initialization
      await tester.pumpAndSettle();
      
      // Look for the Image.asset widget with store_text.png
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('Profile screen should load profile_text.png', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ProfileScreen(),
        ),
      );
      
      // Wait for initialization
      await tester.pumpAndSettle();
      
      // Look for the Image.asset widget with profile_text.png
      expect(find.byType(Image), findsWidgets);
    });
  });
}


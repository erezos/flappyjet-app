/// 🧪 3D Text Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/ui/widgets/text_3d_widget.dart';

void main() {
  group('3D Text Widget Tests', () {
    testWidgets('should render basic 3D text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text3D(text: 'TEST'),
          ),
        ),
      );
      
      expect(find.text('TEST'), findsWidgets);
    });

    testWidgets('should render header style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text3DStyles.header('PROFILE'),
          ),
        ),
      );
      
      expect(find.text('PROFILE'), findsWidgets);
    });

    testWidgets('should render title style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text3DStyles.title('FLAPPY JET'),
          ),
        ),
      );
      
      expect(find.text('FLAPPY JET'), findsWidgets);
    });
  });
}


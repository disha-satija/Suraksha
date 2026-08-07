import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/views/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets(
      'renders the four tab labels, fires onTap with the tapped index, and fires onMenuTap',
      (tester) async {
    int? tappedIndex;
    bool menuTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: SurakshaBottomNavBar(
            currentIndex: 0,
            onTap: (i) => tappedIndex = i,
            onMenuTap: () => menuTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Safe Routing'), findsOneWidget);
    expect(find.text('Safe Spot'), findsOneWidget);
    expect(find.text('Guardian'), findsOneWidget);

    await tester.tap(find.text('Guardian'));
    await tester.pump();

    expect(tappedIndex, 3);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();

    expect(menuTapped, true);
  });
}

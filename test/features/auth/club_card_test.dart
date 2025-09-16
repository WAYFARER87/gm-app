import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_club/features/auth/club_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('formats YYYY-MM-DD into MM/YY', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubCard(cardNum: '123', expireDate: '2025-08-15'),
      ),
    );
    expect(find.text('VALID THRU 08/25'), findsOneWidget);
  });

  testWidgets('formats MM/YY input', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubCard(cardNum: '123', expireDate: '08/25'),
      ),
    );
    expect(find.text('VALID THRU 08/25'), findsOneWidget);
  });

  testWidgets('shows name when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClubCard(
          cardNum: '123',
          expireDate: '2025-08-15',
          firstName: 'Ivan',
          lastName: 'Petrov',
        ),
      ),
    );
    expect(find.text('Ivan Petrov'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavendia/features/shared/widgets/custom_button.dart';

/// Wraps [child] in the minimum needed to pump it.
///
/// Deliberately not AppTheme - that pulls in google_fonts, which reaches for
/// the network and makes widget tests flaky.
Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('CustomButton', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(host(
        CustomButton(text: 'Create Receipt', onPressed: () {}),
      ));

      expect(find.text('Create Receipt'), findsOneWidget);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;

      await tester.pumpWidget(host(
        CustomButton(text: 'Submit', onPressed: () => taps++),
      ));
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(host(
        const CustomButton(text: 'Submit'),
      ));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows a spinner instead of the label while loading',
        (tester) async {
      await tester.pumpWidget(host(
        CustomButton(text: 'Submit', isLoading: true, onPressed: () {}),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('swallows taps while loading', (tester) async {
      var taps = 0;

      await tester.pumpWidget(host(
        CustomButton(text: 'Submit', isLoading: true, onPressed: () => taps++),
      ));
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(taps, 0, reason: 'a loading button must not double-submit');
    });

    testWidgets('renders an icon alongside the label', (tester) async {
      await tester.pumpWidget(host(
        CustomButton(
          text: 'Scan',
          icon: Icons.qr_code_scanner,
          onPressed: () {},
        ),
      ));

      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets('uses an OutlinedButton in outlined mode', (tester) async {
      await tester.pumpWidget(host(
        CustomButton(text: 'Cancel', isOutlined: true, onPressed: () {}),
      ));

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('stretches to full width by default', (tester) async {
      await tester.pumpWidget(host(
        CustomButton(text: 'Wide', onPressed: () {}),
      ));

      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(CustomButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(box.width, double.infinity);
      expect(box.height, 50);
    });

    testWidgets('honours an explicit width', (tester) async {
      await tester.pumpWidget(host(
        Center(
          child: CustomButton(text: 'Narrow', width: 120, onPressed: () {}),
        ),
      ));

      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(CustomButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(box.width, 120);
    });
  });

  group('CustomTextButton', () {
    testWidgets('renders its label and fires onPressed', (tester) async {
      var taps = 0;

      await tester.pumpWidget(host(
        CustomTextButton(text: 'Forgot password?', onPressed: () => taps++),
      ));

      expect(find.text('Forgot password?'), findsOneWidget);

      await tester.tap(find.byType(CustomTextButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('renders an optional icon', (tester) async {
      await tester.pumpWidget(host(
        CustomTextButton(
          text: 'Back',
          icon: Icons.arrow_back,
          onPressed: () {},
        ),
      ));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}

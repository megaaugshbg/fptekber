import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/widgets/markir_widgets.dart';

void main() {
  testWidgets('KartuPutih dan TombolUtama tampil tanpa Supabase',
      (WidgetTester tester) async {
    var ditekan = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KartuPutih(
            child: TombolUtama(label: 'Masuk', onPressed: () => ditekan++),
          ),
        ),
      ),
    );

    expect(find.text('Masuk'), findsOneWidget);
    await tester.tap(find.text('Masuk'));
    expect(ditekan, 1);
  });
}

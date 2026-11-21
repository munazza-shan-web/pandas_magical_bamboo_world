import 'package:flutter_test/flutter_test.dart';
import 'package:pandas_magical_bamboo_world/main.dart';

void main() {
  testWidgets('Panda world menu opens', (tester) async {
    await tester.pumpWidget(const PandaWorldApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MAGICAL BAMBOO WORLD'), findsOneWidget);
    expect(find.text('PANDA HOME'), findsOneWidget);
  });
}

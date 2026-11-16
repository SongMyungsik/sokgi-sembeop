import 'package:flutter_test/flutter_test.dart';
import 'package:neighbor_multiply/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('앱이 열리고 규칙 카드가 보인다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const NeighborMultiplyApp());
    await tester.pump();
    expect(find.text('× 6 규칙'), findsOneWidget);
    expect(find.text('풀이 보기'), findsOneWidget);
    expect(find.text('연습하기'), findsOneWidget);
    expect(find.text('직접 곱셈'), findsWidgets);
    expect(find.text('덧셈'), findsWidgets);
  });
}
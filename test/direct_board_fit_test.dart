import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neighbor_multiply/direct.dart';
import 'package:neighbor_multiply/direct_page.dart';

void main() {
  testWidgets('5자리 × 3자리 숫자판이 좁은 화면 너비에 맞춰진다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          DirectBoardView(
            solution: solveDirect('99999', '999'),
            done: 0,
            mark: true,
          ),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    final w = tester.getSize(find.byType(DirectBoardView)).width;
    expect(w, lessThanOrEqualTo(320));
  });
}

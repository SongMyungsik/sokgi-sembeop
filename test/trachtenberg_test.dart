import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:neighbor_multiply/trachtenberg.dart';

void main() {
  void check(String number, int m) {
    final sol = solve(number, m);
    final expected = (BigInt.parse(number) * BigInt.from(m)).toString();
    expect(sol.answer, expected, reason: '$number × $m');
    for (final step in sol.steps) {
      expect(step.value >= 0, isTrue, reason: '$number × $m 의 중간값');
    }
  }

  test('모든 곱하는 수에 대해 0~2999가 실제 곱셈과 일치한다', () {
    for (final m in multipliers) {
      for (var x = 0; x < 3000; x++) {
        check('$x', m);
      }
    }
  });

  test('무작위 큰 수가 실제 곱셈과 일치한다', () {
    final random = Random(42);
    for (final m in multipliers) {
      for (var t = 0; t < 2000; t++) {
        check('${random.nextInt(999999999)}', m);
      }
      check('999999999', m);
    }
  });

  test('11을 곱할 때 맨 앞 올림을 받아 적는다', () {
    final sol = solve('91', 11);
    expect(sol.answer, '1001');
    expect(sol.leadCount, 2);
  });

  test('단계 설명이 규칙대로 나온다', () {
    final sol = solve('2684', 6);
    expect(sol.answer, '16104');
    expect(sol.steps[1].calc(), '8 + 이웃 절반 2 = 10 → 0 적고 1 올림');
  });

  test('쉼표 표기', () {
    expect(withCommas('1234567'), '1,234,567');
    expect(withCommas('123'), '123');
  });
}

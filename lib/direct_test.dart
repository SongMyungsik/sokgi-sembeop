import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:neighbor_multiply/direct.dart';

void main() {
  void check(String a, String b) {
    final sol = solveDirect(a, b);
    final expected = (BigInt.parse(a) * BigInt.parse(b)).toString();
    expect(sol.answer, expected, reason: '$a × $b');
    expect(sol.steps.last.carry, 0, reason: '$a × $b 의 마지막 올림');
    // 자릿수 합 검산도 항상 통과해야 한다.
    final left = digitSum('${digitSum(a) * digitSum(b)}') % 9;
    expect(left, digitSum(expected) % 9, reason: '$a × $b 의 검산');
  }

  test('작은 수 전체가 실제 곱셈과 일치한다', () {
    for (var a = 0; a < 300; a++) {
      for (var b = 0; b < 120; b++) {
        check('$a', '$b');
      }
    }
  });

  test('무작위 큰 수가 실제 곱셈과 일치한다', () {
    final random = Random(7);
    for (var t = 0; t < 20000; t++) {
      check('${random.nextInt(1000000)}', '${random.nextInt(10000)}');
    }
    check('999999', '9999');
  });

  test('단계 설명이 규칙대로 나온다', () {
    final sol = solveDirect('312', '24');
    expect(sol.answer, '7488');
    expect(sol.k, 2);
    expect(sol.steps[2].calc(), '3×4 + 1×2 = 14 → 4 적고 1 올림');
    expect(sol.steps[3].calc(), '0×4 + 3×2 + 올림 1 = 7 → 7 적음');
  });

  test('자릿수 합과 자리 이름', () {
    expect(digitSum('7488'), 9);
    expect(digitSum('6324'), 6);
    expect(placeName(0), '일의 자리');
    expect(placeName(3), '천의 자리');
  });
}
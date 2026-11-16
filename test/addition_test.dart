import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:neighbor_multiply/addition.dart';

void main() {
  void check(List<String> numbers) {
    final sol = solveAddition(numbers);
    var total = BigInt.zero;
    for (final s in numbers) {
      total += BigInt.parse(s);
    }
    expect(sol.answer, total.toString(), reason: '$numbers');
    expect(sol.answerSteps.last.carry, 0, reason: '$numbers 의 마지막 올림');
    for (final c in sol.columns) {
      expect(c.running <= 10, isTrue, reason: '누계는 10을 넘지 않는다');
      expect(c.columnCheck % 9, c.tableCheck % 9, reason: '$numbers 의 열 검산');
    }
    expect(sol.answerCheck % 9, sol.columnsCheck % 9, reason: '$numbers 의 답 검산');
  }

  test('무작위 덧셈이 실제 합과 일치하고 검산도 통과한다', () {
    final random = Random(11);
    for (var t = 0; t < 20000; t++) {
      final count = 2 + random.nextInt(9);
      final numbers = <String>[
        for (var i = 0; i < count; i++) '${random.nextInt(10000000)}',
      ];
      check(numbers);
    }
    check(List<String>.filled(10, '9999999'));
    check(['0', '0']);
  });

  test('예제: 786 + 459 + 878 + 697 = 2820', () {
    final sol = solveAddition(['786', '459', '878', '697']);
    expect(sol.answer, '2820');
    expect(sol.lead, 1);
    // 열은 왼쪽부터: 빈 열, 백, 십, 일
    expect(sol.columns[1].running, 3);
    expect(sol.columns[1].ticks, 2);
    expect(sol.columns[2].running, 7);
    expect(sol.columns[2].ticks, 2);
    expect(sol.columns[3].running, 8);
    expect(sol.columns[3].ticks, 2);
    expect(sol.answerSteps[1].calc(),
        '누계 7 + 표시 2 + 이웃 표시 2 + 올림 1 = 12 → 2 적고 1 올림');
    expect(sol.columns[3].walk[1].text, '6 + 9 = 15 → 11을 빼서 4, 표시 하나');
  });

  test('한 자리로 줄이기', () {
    expect(reduceDigits(0), 0);
    expect(reduceDigits(29), 2);
    expect(reduceDigits(99), 9);
  });
}
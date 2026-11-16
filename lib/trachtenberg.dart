/// 구구단 없이 하는 기본 곱셈의 계산 로직.
///
/// 각 자리에서 자기 숫자(d), 오른쪽 이웃(n), 올림만 보고 값을 구한다.
/// 화면과 무관한 순수 Dart 코드라서 test/trachtenberg_test.dart 로 검증한다.
library;

class Rule {
  /// 자기 숫자에 곱하는 배수 (0, 1, 2)
  final int a;

  /// 9(첫 자리는 10)에서 빼는 규칙인지 여부
  final bool comp;

  /// 이웃 사용 방식: 0 안 씀, 1 전체, 2 절반
  final int nb;

  /// 자기 숫자가 홀수면 5를 더하는지 여부
  final bool odd5;

  /// 말로 풀어 쓴 규칙
  final String text;

  /// 공식 (줄 단위)
  final List<String> formula;

  const Rule({
    required this.a,
    required this.comp,
    required this.nb,
    required this.odd5,
    required this.text,
    required this.formula,
  });
}

/// 화면에 보여 주는 순서
const List<int> multipliers = [11, 12, 6, 7, 5, 9, 8, 4, 3, 2];

const Map<int, Rule> rules = {
  11: Rule(
    a: 1,
    comp: false,
    nb: 1,
    odd5: false,
    text: '자기 숫자에 이웃을 더합니다.',
    formula: ['d + n'],
  ),
  12: Rule(
    a: 2,
    comp: false,
    nb: 1,
    odd5: false,
    text: '자기 숫자를 두 배 하고 이웃을 더합니다.',
    formula: ['2d + n'],
  ),
  6: Rule(
    a: 1,
    comp: false,
    nb: 2,
    odd5: true,
    text: '자기 숫자에 이웃의 절반을 더합니다. 자기 숫자가 홀수면 5를 더 더합니다.',
    formula: ['d + n÷2  (d가 홀수면 +5)'],
  ),
  7: Rule(
    a: 2,
    comp: false,
    nb: 2,
    odd5: true,
    text: '자기 숫자를 두 배 하고 이웃의 절반을 더합니다. 자기 숫자가 홀수면 5를 더 더합니다.',
    formula: ['2d + n÷2  (d가 홀수면 +5)'],
  ),
  5: Rule(
    a: 0,
    comp: false,
    nb: 2,
    odd5: true,
    text: '이웃의 절반을 씁니다. 자기 숫자가 홀수면 5를 더합니다.',
    formula: ['n÷2  (d가 홀수면 +5)'],
  ),
  9: Rule(
    a: 1,
    comp: true,
    nb: 1,
    odd5: false,
    text: '첫 자리는 10에서 뺍니다. 가운데 자리는 9에서 빼고 이웃을 더합니다. '
        '맨 앞 0 자리에는 이웃에서 1을 뺀 수를 적습니다.',
    formula: ['첫 자리  10 − d', '가운데  (9 − d) + n', '맨 앞  n − 1'],
  ),
  8: Rule(
    a: 2,
    comp: true,
    nb: 1,
    odd5: false,
    text: '첫 자리는 10에서 빼서 두 배 합니다. 가운데 자리는 9에서 빼서 두 배 하고 이웃을 더합니다. '
        '맨 앞 0 자리에는 이웃에서 2를 뺀 수를 적습니다.',
    formula: ['첫 자리  2(10 − d)', '가운데  2(9 − d) + n', '맨 앞  n − 2'],
  ),
  4: Rule(
    a: 1,
    comp: true,
    nb: 2,
    odd5: true,
    text: '첫 자리는 10에서 뺍니다. 가운데 자리는 9에서 빼고 이웃의 절반을 더합니다. '
        '두 경우 모두 자기 숫자가 홀수면 5를 더합니다. '
        '맨 앞 0 자리에는 이웃의 절반에서 1을 뺀 수를 적습니다.',
    formula: [
      '첫 자리  10 − d',
      '가운데  (9 − d) + n÷2',
      '맨 앞  n÷2 − 1',
      '(d가 홀수면 +5)',
    ],
  ),
  3: Rule(
    a: 2,
    comp: true,
    nb: 2,
    odd5: true,
    text: '첫 자리는 10에서 빼서 두 배 합니다. 가운데 자리는 9에서 빼서 두 배 하고 이웃의 절반을 더합니다. '
        '두 경우 모두 자기 숫자가 홀수면 5를 더합니다. '
        '맨 앞 0 자리에는 이웃의 절반에서 2를 뺀 수를 적습니다.',
    formula: [
      '첫 자리  2(10 − d)',
      '가운데  2(9 − d) + n÷2',
      '맨 앞  n÷2 − 2',
      '(d가 홀수면 +5)',
    ],
  ),
  2: Rule(
    a: 2,
    comp: false,
    nb: 0,
    odd5: false,
    text: '각 숫자를 두 배 합니다. 이웃은 쓰지 않습니다.',
    formula: ['2d'],
  ),
};

/// 답의 한 자리를 구하는 계산 한 단계.
class CalcStep {
  /// 맨 앞에 붙인 0 자리인지 여부
  final bool lead;

  /// 자기 숫자
  final int d;

  /// 이웃 (없으면 0)
  final int n;

  /// 이웃이 있는 자리인지 여부 (맨 오른쪽 자리는 없음)
  final bool hasNb;

  /// 더하는 항목들의 설명
  final List<String> terms;

  /// 항목을 모두 더한 값
  final int value;

  const CalcStep({
    required this.lead,
    required this.d,
    required this.n,
    required this.hasNb,
    required this.terms,
    required this.value,
  });

  /// 답에 적는 숫자
  int get write => value % 10;

  /// 왼쪽 자리로 넘기는 올림
  int get carry => value ~/ 10;

  /// "자기 숫자 6, 이웃 8" 형태의 설명
  String get where {
    final buf = StringBuffer('자기 숫자 $d');
    if (lead) buf.write(' (맨 앞에 붙인 0)');
    buf.write(hasNb ? ', 이웃 $n' : ', 이웃 없음');
    return buf.toString();
  }

  /// 계산식. [reveal]이 false면 결과를 "?"로 가린다.
  String calc({bool reveal = true}) {
    final left = terms.join(' + ');
    if (!reveal) return '$left = ?';
    final tail = carry > 0 ? '$write 적고 $carry 올림' : '$write 적음';
    return '$left = $value → $tail';
  }
}

class Solution {
  final String number;
  final int m;

  /// 앞에 0을 붙인 곱해지는 수의 숫자들 (왼쪽부터)
  final List<int> digits;

  /// 계산 단계 (오른쪽 자리부터)
  final List<CalcStep> steps;

  const Solution({
    required this.number,
    required this.m,
    required this.digits,
    required this.steps,
  });

  /// 앞에 붙인 0의 개수 (보통 1, 11·12에서 올림이 남으면 2)
  int get leadCount => digits.length - number.length;

  /// 완성된 답 (앞의 0 제거)
  String get answer {
    final buf = StringBuffer();
    for (var k = steps.length - 1; k >= 0; k--) {
      buf.write(steps[k].write);
    }
    final s = buf.toString().replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return s;
  }
}

/// [number](숫자로만 된 문자열)에 [m]을 곱하는 과정을 단계별로 만든다.
Solution solve(String number, int m) {
  final r = rules[m]!;
  final digits = <int>[0, ...number.split('').map(int.parse)];
  final last = digits.length - 1;
  var carry = 0;
  final steps = <CalcStep>[];

  for (var i = last; i >= 0; i--) {
    final d = digits[i];
    final hasNb = i < last;
    final n = hasNb ? digits[i + 1] : 0;
    final half = n ~/ 2;
    final terms = <String>[];
    var v = 0;

    if (r.comp && i == 0) {
      // 맨 앞 0 자리: 이웃(또는 이웃의 절반)에서 a를 뺀다.
      if (r.nb == 1) {
        terms.add('(이웃 $n − ${r.a})');
        v += n - r.a;
      } else {
        terms.add('(이웃 절반 $half − ${r.a})');
        v += half - r.a;
      }
    } else {
      if (r.comp) {
        final from = i == last ? 10 : 9;
        terms.add('($from − $d)${r.a == 2 ? ' × 2' : ''}');
        v += r.a * (from - d);
      } else if (r.a == 1) {
        terms.add('$d');
        v += d;
      } else if (r.a == 2) {
        terms.add('$d × 2');
        v += 2 * d;
      }
      if (hasNb && r.nb == 1) {
        terms.add('이웃 $n');
        v += n;
      }
      if (hasNb && r.nb == 2) {
        terms.add('이웃 절반 $half');
        v += half;
      }
      if (r.odd5 && d.isOdd) {
        terms.add('홀수 5');
        v += 5;
      }
    }
    if (carry > 0) {
      terms.add('올림 $carry');
      v += carry;
    }
    if (terms.isEmpty) terms.add('0');

    final step = CalcStep(
      lead: i == 0,
      d: d,
      n: n,
      hasNb: hasNb,
      terms: terms,
      value: v,
    );
    steps.add(step);
    carry = step.carry;
  }

  // 11, 12를 곱할 때 맨 앞에서 올림이 남으면 0을 하나 더 붙여 받아 적는다.
  if (carry > 0) {
    digits.insert(0, 0);
    steps.add(CalcStep(
      lead: true,
      d: 0,
      n: 0,
      hasNb: true,
      terms: ['올림 $carry'],
      value: carry,
    ));
  }

  return Solution(number: number, m: m, digits: digits, steps: steps);
}

/// 1234567 → "1,234,567"
String withCommas(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

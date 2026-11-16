/// 직접 곱셈법(바깥쌍·안쪽쌍)의 계산 로직.
///
/// 곱해지는 수의 숫자를 a, 곱하는 수의 숫자를 b라 하고 오른쪽 끝을 0번으로 세면
/// 답의 p번째 자리 값 = a[p]·b[0] + a[p-1]·b[1] + … + 올림 이다.
library;

/// 짝 하나: 곱해지는 수의 숫자 하나와 곱하는 수의 숫자 하나.
class PairTerm {
  /// 몇 번째 짝인지 (0 = 바깥쌍, 1부터 안쪽쌍)
  final int t;

  /// 곱해지는 수(앞에 0을 붙인 것)에서의 위치, 왼쪽부터
  final int ai;

  /// 곱하는 수에서의 위치, 왼쪽부터
  final int bi;

  final int x;
  final int y;

  const PairTerm({
    required this.t,
    required this.ai,
    required this.bi,
    required this.x,
    required this.y,
  });

  int get product => x * y;
}

/// 답의 한 자리를 구하는 단계.
class DirectStep {
  final List<PairTerm> pairs;

  /// 오른쪽 자리에서 넘어온 올림
  final int carryIn;

  /// 짝 곱의 합 + 올림
  final int value;

  const DirectStep({
    required this.pairs,
    required this.carryIn,
    required this.value,
  });

  int get write => value % 10;
  int get carry => value ~/ 10;

  /// 색 없는 계산식 (테스트·접근성용)
  String calc({bool reveal = true}) {
    final parts = <String>[for (final p in pairs) '${p.x}×${p.y}'];
    if (carryIn > 0) parts.add('올림 $carryIn');
    final left = parts.join(' + ');
    if (!reveal) return '$left = ?';
    final tail = carry > 0 ? '$write 적고 $carry 올림' : '$write 적음';
    return '$left = $value → $tail';
  }
}

class DirectSolution {
  final String a;
  final String b;

  /// 앞에 0을 붙인 곱해지는 수의 숫자들 (왼쪽부터)
  final List<int> digits;

  /// 곱하는 수의 숫자들 (왼쪽부터)
  final List<int> multiplierDigits;

  /// 계산 단계 (오른쪽 자리부터)
  final List<DirectStep> steps;

  const DirectSolution({
    required this.a,
    required this.b,
    required this.digits,
    required this.multiplierDigits,
    required this.steps,
  });

  /// 곱하는 수의 자리 수 = 앞에 붙인 0의 개수
  int get k => multiplierDigits.length;

  String get answer {
    final buf = StringBuffer();
    for (var q = steps.length - 1; q >= 0; q--) {
      buf.write(steps[q].write);
    }
    return buf.toString().replaceFirst(RegExp(r'^0+(?=\d)'), '');
  }
}

/// [a] × [b]를 직접 곱셈법으로 푸는 과정을 만든다. 둘 다 숫자로만 된 문자열.
DirectSolution solveDirect(String a, String b) {
  final bd = b.split('').map(int.parse).toList();
  final k = bd.length;
  final digits = <int>[
    for (var z = 0; z < k; z++) 0,
    ...a.split('').map(int.parse),
  ];
  final n = digits.length;
  var carry = 0;
  final steps = <DirectStep>[];

  for (var i = n - 1; i >= 0; i--) {
    final pairs = <PairTerm>[];
    var v = 0;
    for (var t = 0; t < k; t++) {
      final ai = i + t; // 지금 자리에서 t칸 오른쪽
      final bi = k - 1 - t; // 곱하는 수의 오른쪽 끝에서 t칸 왼쪽
      if (ai > n - 1) break;
      final pair = PairTerm(t: t, ai: ai, bi: bi, x: digits[ai], y: bd[bi]);
      pairs.add(pair);
      v += pair.product;
    }
    final carryIn = carry;
    v += carryIn;
    final step = DirectStep(pairs: pairs, carryIn: carryIn, value: v);
    steps.add(step);
    carry = step.carry;
  }

  return DirectSolution(
    a: a,
    b: b,
    digits: digits,
    multiplierDigits: bd,
    steps: steps,
  );
}

/// 자릿수 합: 각 자리 숫자를 더해 한 자리가 될 때까지 줄인다.
int digitSum(String s) {
  var t = s;
  while (t.length > 1) {
    var sum = 0;
    for (var q = 0; q < t.length; q++) {
      sum += int.parse(t[q]);
    }
    t = '$sum';
  }
  return int.parse(t);
}

/// 0 → "일의 자리", 1 → "십의 자리" …
String placeName(int q) {
  const names = ['일', '십', '백', '천', '만', '십만', '백만', '천만', '억', '십억'];
  if (q >= 0 && q < names.length) return '${names[q]}의 자리';
  return '${q + 1}번째 자리';
}
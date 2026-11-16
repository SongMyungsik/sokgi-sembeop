/// 11을 넘겨 세지 않는 세로 덧셈과 그 검산의 계산 로직.
///
/// 열마다 위에서 아래로 더하다가 합이 11 이상이 되면 11을 빼고 표시(′)를 하나 한다.
/// 열이 끝나면 남은 수(누계)와 표시 수를 적는다.
/// 답의 각 자리 = 누계 + 그 열의 표시 수 + 오른쪽 이웃 열의 표시 수 + 올림.
library;

/// 한 자리가 될 때까지 각 자리 숫자를 더한다.
int reduceDigits(int value) {
  var v = value;
  while (v >= 10) {
    var sum = 0;
    var rest = v;
    while (rest > 0) {
      sum += rest % 10;
      rest ~/= 10;
    }
    v = sum;
  }
  return v;
}

/// 열을 내려가며 숫자 하나를 더하는 한 걸음.
class WalkStep {
  /// 몇 번째 줄의 숫자인지
  final int row;
  final int digit;

  /// 더하기 전의 누계
  final int before;

  const WalkStep({
    required this.row,
    required this.digit,
    required this.before,
  });

  int get sum => before + digit;

  /// 11 이상이 되어 표시를 하는지 여부
  bool get tick => sum >= 11;

  /// 더한 뒤의 누계
  int get after => tick ? sum - 11 : sum;

  String get text {
    if (tick) return '$before + $digit = $sum → 11을 빼서 $after, 표시 하나';
    return '$before + $digit = $sum';
  }
}

/// 열 하나의 결과.
class ColumnResult {
  final List<WalkStep> walk;

  /// 마지막에 남은 수
  final int running;

  /// 표시의 개수
  final int ticks;

  /// 열에 있는 숫자를 그냥 다 더한 값
  final int digitTotal;

  const ColumnResult({
    required this.walk,
    required this.running,
    required this.ticks,
    required this.digitTotal,
  });

  /// 검산 1단계: 열 숫자들의 자릿수 합
  int get columnCheck => reduceDigits(digitTotal);

  /// 검산 2단계: 누계 + 표시 수 + 표시 수
  int get tableCheck => reduceDigits(running + 2 * ticks);

  /// 열을 내려가는 과정을 한 줄로 적은 것
  String get walkText {
    if (walk.isEmpty) return '숫자가 없는 열입니다.';
    final buf = StringBuffer('${walk.first.digit}');
    for (var i = 1; i < walk.length; i++) {
      final w = walk[i];
      buf.write(', +${w.digit} → ${w.sum}');
      if (w.tick) buf.write(' (11 빼서 ${w.after}, 표시)');
    }
    buf.write('  ⇒ 누계 $running, 표시 $ticks');
    return buf.toString();
  }
}

/// 답의 한 자리를 구하는 단계.
class AnswerStep {
  final int running;
  final int ticks;
  final int neighborTicks;

  /// 오른쪽에 이웃 열이 있는지 여부 (맨 오른쪽 열은 없음)
  final bool hasNeighbor;
  final int carryIn;

  const AnswerStep({
    required this.running,
    required this.ticks,
    required this.neighborTicks,
    required this.hasNeighbor,
    required this.carryIn,
  });

  int get value => running + ticks + neighborTicks + carryIn;
  int get write => value % 10;
  int get carry => value ~/ 10;

  String calc({bool reveal = true}) {
    final parts = <String>['누계 $running', '표시 $ticks'];
    if (hasNeighbor) parts.add('이웃 표시 $neighborTicks');
    if (carryIn > 0) parts.add('올림 $carryIn');
    final left = parts.join(' + ');
    if (!reveal) return '$left = ?';
    final tail = carry > 0 ? '$write 적고 $carry 올림' : '$write 적음';
    return '$left = $value → $tail';
  }
}

class AdditionSolution {
  final List<String> numbers;

  /// 답이 길어질 것에 대비해 왼쪽에 둔 빈 열의 수
  final int lead;

  /// 숫자판: 줄 × 열, 숫자가 없는 칸은 null
  final List<List<int?>> grid;

  /// 열별 결과 (왼쪽부터)
  final List<ColumnResult> columns;

  /// 답의 단계 (오른쪽 자리부터)
  final List<AnswerStep> answerSteps;

  const AdditionSolution({
    required this.numbers,
    required this.lead,
    required this.grid,
    required this.columns,
    required this.answerSteps,
  });

  int get cols => columns.length;

  String get answer {
    final buf = StringBuffer();
    for (var q = answerSteps.length - 1; q >= 0; q--) {
      buf.write(answerSteps[q].write);
    }
    return buf.toString().replaceFirst(RegExp(r'^0+(?=\d)'), '');
  }

  /// 검산 3단계: 답의 자릿수 합
  int get answerCheck {
    var sum = 0;
    for (final ch in answer.split('')) {
      sum += int.parse(ch);
    }
    return reduceDigits(sum);
  }

  /// 검산 3단계: 열 검산 숫자를 모두 더해 줄인 값
  int get columnsCheck {
    var sum = 0;
    for (final c in columns) {
      sum += c.columnCheck;
    }
    return reduceDigits(sum);
  }
}

/// [numbers](숫자로만 된 문자열들)를 더하는 과정을 만든다.
AdditionSolution solveAddition(List<String> numbers) {
  var width = 1;
  var total = BigInt.zero;
  for (final s in numbers) {
    if (s.length > width) width = s.length;
    total += BigInt.parse(s);
  }
  final extra = total.toString().length - width;
  final lead = extra > 1 ? extra : 1;
  final cols = lead + width;

  final grid = <List<int?>>[];
  for (final s in numbers) {
    final row = List<int?>.filled(cols, null);
    for (var i = 0; i < s.length; i++) {
      row[cols - s.length + i] = int.parse(s[i]);
    }
    grid.add(row);
  }

  final columns = <ColumnResult>[];
  for (var c = 0; c < cols; c++) {
    final walk = <WalkStep>[];
    var running = 0;
    var ticks = 0;
    var digitTotal = 0;
    for (var r = 0; r < grid.length; r++) {
      final d = grid[r][c];
      if (d == null) continue;
      final step = WalkStep(row: r, digit: d, before: running);
      walk.add(step);
      digitTotal += d;
      running = step.after;
      if (step.tick) ticks += 1;
    }
    columns.add(ColumnResult(
      walk: walk,
      running: running,
      ticks: ticks,
      digitTotal: digitTotal,
    ));
  }

  final answerSteps = <AnswerStep>[];
  var carry = 0;
  for (var c = cols - 1; c >= 0; c--) {
    final hasNeighbor = c < cols - 1;
    final step = AnswerStep(
      running: columns[c].running,
      ticks: columns[c].ticks,
      neighborTicks: hasNeighbor ? columns[c + 1].ticks : 0,
      hasNeighbor: hasNeighbor,
      carryIn: carry,
    );
    answerSteps.add(step);
    carry = step.carry;
  }

  return AdditionSolution(
    numbers: numbers,
    lead: lead,
    grid: grid,
    columns: columns,
    answerSteps: answerSteps,
  );
}
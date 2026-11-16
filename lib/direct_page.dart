import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'direct.dart';
import 'trachtenberg.dart' show withCommas;

/// 짝마다 쓰는 색 (바깥쌍부터 차례로)
List<Color> pairColors(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return [
      Colors.teal.shade200,
      Colors.orange.shade200,
      Colors.purple.shade200,
      Colors.blue.shade200,
    ];
  }
  return [
    Colors.teal.shade700,
    Colors.orange.shade800,
    Colors.purple.shade700,
    Colors.blue.shade700,
  ];
}

/// 짝 색을 입힌 계산식
TextSpan calcSpan(DirectStep step, List<Color> colors, {bool reveal = true}) {
  final children = <InlineSpan>[];
  for (var i = 0; i < step.pairs.length; i++) {
    final p = step.pairs[i];
    if (i > 0) children.add(const TextSpan(text: ' + '));
    children.add(TextSpan(
      text: '${p.x}×${p.y}',
      style: TextStyle(
        color: colors[p.t % colors.length],
        fontWeight: FontWeight.bold,
      ),
    ));
  }
  if (step.carryIn > 0) {
    children.add(TextSpan(text: ' + 올림 ${step.carryIn}'));
  }
  if (!reveal) {
    children.add(const TextSpan(text: ' = ?'));
  } else {
    final tail = step.carry > 0
        ? '${step.write} 적고 ${step.carry} 올림'
        : '${step.write} 적음';
    children.add(TextSpan(text: ' = ${step.value} → $tail'));
  }
  return TextSpan(
    style: const TextStyle(fontFamily: 'monospace'),
    children: children,
  );
}

class DirectPage extends StatefulWidget {
  const DirectPage({super.key});

  @override
  State<DirectPage> createState() => _DirectPageState();
}

class _DirectPageState extends State<DirectPage> {
  final Random _random = Random();
  final TextEditingController _aController =
      TextEditingController(text: '312');
  final TextEditingController _bController = TextEditingController(text: '24');

  // 풀이 보기
  late DirectSolution _solveSol;
  int _solveDone = 3;

  // 연습하기
  late DirectSolution _pracSol;
  int _pracDone = 0;
  int _pracMisses = 0;
  int? _pracWrong;
  bool _pracFinished = false;
  int _lenA = 2;
  int _lenB = 2;
  bool _small = true;
  bool _showAid = true;

  // 기록
  int _solved = 0;
  int _digitsTotal = 0;
  int _digitsFirst = 0;

  @override
  void initState() {
    super.initState();
    _solveSol = solveDirect('312', '24');
    _pracSol = _makeProblem();
    _loadStats();
  }

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _solved = prefs.getInt('direct_solved') ?? 0;
        _digitsTotal = prefs.getInt('direct_digitsTotal') ?? 0;
        _digitsFirst = prefs.getInt('direct_digitsFirst') ?? 0;
      });
    } catch (_) {
      // 기록을 읽지 못해도 앱은 그대로 쓴다.
    }
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('direct_solved', _solved);
      await prefs.setInt('direct_digitsTotal', _digitsTotal);
      await prefs.setInt('direct_digitsFirst', _digitsFirst);
    } catch (_) {
      // 저장 실패는 무시한다.
    }
  }

  String _randomNumber(int len, bool small) {
    final top = small ? 4 : 9;
    final buf = StringBuffer(1 + _random.nextInt(top));
    for (var i = 1; i < len; i++) {
      buf.write(_random.nextInt(top + 1));
    }
    return buf.toString();
  }

  DirectSolution _makeProblem() {
    return solveDirect(
      _randomNumber(_lenA, _small),
      _randomNumber(_lenB, _small),
    );
  }

  String _clean(String raw, int maxLen) {
    var s = raw.replaceAll(RegExp(r'\D'), '');
    s = s.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (s.length > maxLen) s = s.substring(0, maxLen);
    return s.isEmpty ? '0' : s;
  }

  void _setSolve(String a, String b) {
    setState(() {
      _solveSol = solveDirect(a, b);
      _solveDone = 0;
      _aController.text = a;
      _bController.text = b;
    });
  }

  void _applyInput() {
    FocusScope.of(context).unfocus();
    _setSolve(_clean(_aController.text, 6), _clean(_bController.text, 4));
  }

  void _newProblem() {
    setState(() {
      _pracSol = _makeProblem();
      _pracDone = 0;
      _pracMisses = 0;
      _pracWrong = null;
      _pracFinished = false;
    });
  }

  void _enterDigit(int d) {
    if (_pracFinished) return;
    final step = _pracSol.steps[_pracDone];
    if (d == step.write) {
      setState(() {
        _digitsTotal += 1;
        if (_pracMisses == 0) _digitsFirst += 1;
        _pracDone += 1;
        _pracMisses = 0;
        _pracWrong = null;
        if (_pracDone >= _pracSol.steps.length) {
          _pracFinished = true;
          _solved += 1;
        }
      });
      _saveStats();
    } else {
      setState(() {
        _pracMisses += 1;
        _pracWrong = d;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // 키보드가 올라와도 화면을 줄이지 않는다 (입력칸은 맨 위에 있다).
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text('직접 곱셈 (바깥쌍·안쪽쌍)')),
        body: SafeArea(
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: '규칙'),
                  Tab(text: '풀이 보기'),
                  Tab(text: '연습하기'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _page(_buildRule(theme)),
                    _buildSolve(theme),
                    _fitPage(_buildPractice(theme)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page(Widget child) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [child],
    );
  }

  /// 화면 높이에 꽉 차게 배치한다. 화면이 아주 작을 때만 스크롤된다.
  Widget _fitPage(Widget child) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - 24),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }

  /// 이전 / 다음 자리 / 끝까지 / 처음부터 버튼을 한 줄에 놓는다.
  Widget _stepButtons(int done, int total, ValueChanged<int> go) {
    final finished = done >= total;
    const pad = EdgeInsets.symmetric(horizontal: 4);
    Widget label(String s) => FittedBox(child: Text(s));
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: pad),
            onPressed: done == 0 ? null : () => go(done - 1),
            child: label('이전'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(padding: pad),
            onPressed: finished ? null : () => go(done + 1),
            child: label('다음 자리'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: pad),
            onPressed: finished ? null : () => go(total),
            child: label('끝까지'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: pad),
            onPressed: () => go(0),
            child: label('처음부터'),
          ),
        ),
      ],
    );
  }

  /// 0~9 숫자 버튼 (5개씩 두 줄)
  Widget _keypad() {
    Widget key(int d) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _pracFinished ? null : () => _enterDigit(d),
                child: Text(
                  '$d',
                  style: const TextStyle(fontSize: 22, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        );
    return Column(
      children: [
        Row(children: [for (var d = 0; d < 5; d++) key(d)]),
        Row(children: [for (var d = 5; d <= 9; d++) key(d)]),
      ],
    );
  }

  Widget _buildRule(ThemeData theme) {
    const lines = [
      '곱해지는 수 앞에, 곱하는 수의 자리 수만큼 0을 붙입니다.',
      '지금 자리의 숫자는 곱하는 수의 맨 오른쪽 숫자와 짝을 짓습니다. 이것이 바깥쌍입니다.',
      '한 칸 오른쪽 숫자는 곱하는 수의 한 칸 왼쪽 숫자와 짝을 짓습니다. 이렇게 안쪽으로 차례로 짝을 짓습니다.',
      '짝끼리 곱한 값을 모두 더하고 올림을 더합니다. 일의 자리만 적고 나머지는 왼쪽으로 올립니다.',
    ];
    final small = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('직접 곱셈 규칙', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '여러 자리 수끼리 곱할 때 중간 줄을 쓰지 않고, '
              '답을 오른쪽부터 한 자리씩 바로 적습니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${i + 1}.', style: theme.textTheme.bodyLarge),
                    ),
                    Expanded(
                      child: Text(lines[i], style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '답의 p번째 자리 =\n'
                'a[p]·b[0] + a[p−1]·b[1] + a[p−2]·b[2] + … + 올림',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'a는 곱해지는 수, b는 곱하는 수의 숫자이고, 번호는 오른쪽 끝을 0으로 해서 왼쪽으로 셉니다. '
              '1, 2, 3처럼 작은 숫자가 많은 수에 특히 편합니다.',
              style: small,
            ),
            const SizedBox(height: 12),
            Text('옆으로 밀면 풀이 보기와 연습하기로 넘어갑니다.', style: small),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    int maxLen,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLen),
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => _applyInput(),
    );
  }

  Widget _buildSolve(ThemeData theme) {
    final colors = pairColors(theme.brightness);
    final total = _solveSol.steps.length;
    final finished = _solveDone >= total;
    final answer = _solveSol.answer;

    Widget message;
    if (finished) {
      message = _InfoBox(
        color: theme.colorScheme.primary,
        title: '${withCommas(_solveSol.a)} × ${withCommas(_solveSol.b)} = '
            '${withCommas(answer)}',
      );
    } else {
      message = _InfoBox(
        color: theme.colorScheme.primary,
        title: '다음 자리: ${placeName(_solveDone)}',
        detail: calcSpan(_solveSol.steps[_solveDone], colors),
      );
    }

    final da = digitSum(_solveSol.a);
    final db = digitSum(_solveSol.b);
    final dp = digitSum('${da * db}');
    final dr = digitSum(answer);
    final checkOk = dp % 9 == dr % 9;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _numberField(_aController, '곱해지는 수 (6자리까지)', 6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _numberField(_bController, '곱하는 수 (4자리까지)', 4),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _applyInput,
                  child: const Text('이 수로 풀기'),
                ),
                TextButton(
                  onPressed: () => _setSolve(
                    _randomNumber(3, true),
                    _randomNumber(2, true),
                  ),
                  child: const Text('무작위 수'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DirectBoardView(solution: _solveSol, done: _solveDone, mark: true),
            const SizedBox(height: 8),
            Text(
              '같은 색 테두리끼리 곱해서 모두 더합니다. 위의 작은 빨간 숫자는 올림입니다.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            message,
            const SizedBox(height: 12),
            _stepButtons(
              _solveDone,
              total,
              (v) => setState(() => _solveDone = v),
            ),
            const SizedBox(height: 12),
            // 지나간 단계와 검산은 남은 공간 안에서만 보여 준다.
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (finished) ...[
                    Text('자릿수 합 검산', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${withCommas(_solveSol.a)} → $da,  '
                      '${withCommas(_solveSol.b)} → $db\n'
                      '$da × $db = ${da * db} → $dp\n'
                      '답 ${withCommas(answer)} → $dr : '
                      '${checkOk ? '같으므로 통과' : '다름'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (var q = 0; q < _solveDone; q++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${q + 1}. ${placeName(q)}\n    ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            calcSpan(_solveSol.steps[q], colors),
                          ],
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lengthDropdown(int value, int maxLen, ValueChanged<int> onChanged) {
    const names = {2: '두 자리', 3: '세 자리', 4: '네 자리', 5: '다섯 자리'};
    return DropdownButton<int>(
      isDense: true,
      value: value,
      items: [
        for (var len = 2; len <= maxLen; len++)
          DropdownMenuItem<int>(value: len, child: Text(names[len]!)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _buildPractice(ThemeData theme) {
    final colors = pairColors(theme.brightness);
    final rate = _digitsTotal == 0
        ? '–'
        : '${(_digitsFirst * 100 / _digitsTotal).round()}%';

    Widget message;
    if (_pracFinished) {
      message = _InfoBox(
        color: theme.colorScheme.primary,
        title: '정답입니다. ${withCommas(_pracSol.a)} × '
            '${withCommas(_pracSol.b)} = ${withCommas(_pracSol.answer)}',
        detail: const TextSpan(text: '새 문제를 누르면 다음 문제가 나옵니다.'),
      );
    } else if (_pracWrong != null) {
      message = _InfoBox(
        color: theme.colorScheme.error,
        title: '틀린 답 $_pracWrong. ${placeName(_pracDone)}',
        detail: calcSpan(
          _pracSol.steps[_pracDone],
          colors,
          reveal: _pracMisses >= 2,
        ),
      );
    } else {
      message = _InfoBox(
        color: theme.colorScheme.primary,
        title: placeName(_pracDone),
        detail: const TextSpan(text: '이 자리에 적을 숫자는 무엇일까요?'),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('곱해지는 수'),
                _lengthDropdown(_lenA, 5, (v) {
                  _lenA = v;
                  _newProblem();
                }),
                const Text('곱하는 수'),
                _lengthDropdown(_lenB, 4, (v) {
                  _lenB = v;
                  _newProblem();
                }),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Checkbox(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: _small,
                  onChanged: (v) {
                    _small = v ?? true;
                    _newProblem();
                  },
                ),
                const Flexible(child: Text('작은 숫자(0~4)만')),
                const SizedBox(width: 8),
                Checkbox(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: _showAid,
                  onChanged: (v) => setState(() => _showAid = v ?? true),
                ),
                const Flexible(child: Text('짝 표시')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${withCommas(_pracSol.a)} × '
                      '${withCommas(_pracSol.b)} = ?',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _newProblem,
                  child: const Text('새 문제'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DirectBoardView(
              solution: _pracSol,
              done: _pracDone,
              mark: _showAid,
            ),
            const SizedBox(height: 12),
            message,
            const SizedBox(height: 12),
            const Spacer(),
            _keypad(),
            const SizedBox(height: 8),
            Text(
              '푼 문제 $_solved    한 번에 맞힌 자리 $rate',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// 숫자판: 올림, 곱해지는 수 × 곱하는 수, 답을 세 줄로 보여 준다.
class DirectBoardView extends StatelessWidget {
  final DirectSolution solution;

  /// 이미 적은 답의 자리 수 (오른쪽부터)
  final int done;

  /// 짝을 색으로 표시할지 여부
  final bool mark;

  const DirectBoardView({
    super.key,
    required this.solution,
    required this.done,
    required this.mark,
  });

  static const double _w = 34;
  static const double _h = 44;
  static const double _gap = 3;

  Widget _digitCell(String text, Color? pairColor, Color? textColor) {
    return Container(
      width: _w,
      height: _h,
      margin: const EdgeInsets.only(right: _gap),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pairColor?.withAlpha(46),
        border: Border.all(
          color: pairColor ?? Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontFamily: 'monospace',
          fontWeight: pairColor != null ? FontWeight.bold : FontWeight.normal,
          color: pairColor != null ? null : textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = pairColors(theme.brightness);
    final n = solution.digits.length;
    final k = solution.k;

    // 지금 자리에서 쓰는 짝의 색
    final aColor = <int, Color>{};
    final bColor = <int, Color>{};
    if (mark && done < n) {
      for (final p in solution.steps[done].pairs) {
        final c = colors[p.t % colors.length];
        aColor[p.ai] = c;
        bColor[p.bi] = c;
      }
    }

    final carryRow = <Widget>[];
    final digitRow = <Widget>[];
    final answerRow = <Widget>[];

    for (var j = 0; j < n; j++) {
      final q = n - 1 - j; // 이 칸에 해당하는 단계 번호
      final from = q - 1; // 이 칸으로 올림을 넘겨 주는 단계

      var carryText = '';
      if (from >= 0 && from < done && solution.steps[from].carry > 0) {
        carryText = '+${solution.steps[from].carry}';
      }
      carryRow.add(Container(
        width: _w,
        height: 18,
        margin: const EdgeInsets.only(right: _gap),
        alignment: Alignment.bottomCenter,
        child: Text(
          carryText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: scheme.error,
          ),
        ),
      ));

      digitRow.add(_digitCell(
        '${solution.digits[j]}',
        aColor[j],
        j < k ? scheme.onSurfaceVariant : null,
      ));

      final isSlot = q == done;
      answerRow.add(Container(
        width: _w,
        height: _h,
        margin: const EdgeInsets.only(right: _gap),
        alignment: Alignment.center,
        decoration: isSlot
            ? BoxDecoration(
                border: Border.all(color: scheme.primary, width: 2),
                borderRadius: BorderRadius.circular(6),
              )
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant, width: 2),
                ),
              ),
        child: Text(
          q < done ? '${solution.steps[q].write}' : '',
          style: const TextStyle(
            fontSize: 24,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    }

    digitRow.add(Padding(
      padding: const EdgeInsets.only(left: 2, right: 5),
      child: Text(
        '×',
        style: TextStyle(fontSize: 20, color: scheme.onSurfaceVariant),
      ),
    ));
    for (var m = 0; m < k; m++) {
      digitRow.add(_digitCell(
        '${solution.multiplierDigits[m]}',
        bColor[m],
        null,
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: carryRow),
          const SizedBox(height: _gap),
          Row(children: digitRow),
          const SizedBox(height: _gap),
          Row(children: answerRow),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color;
  final String title;
  final InlineSpan? detail;

  const _InfoBox({required this.color, required this.title, this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: theme.colorScheme.outlineVariant),
          right: BorderSide(color: theme.colorScheme.outlineVariant),
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text.rich(detail!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'addition.dart';
import 'trachtenberg.dart' show withCommas;

/// 풀이 보기에서 열을 내려가는 한 걸음의 위치
class _WalkRef {
  final int col;
  final int index;
  const _WalkRef(this.col, this.index);
}

/// 연습하기에서 입력받는 칸 하나. kind: 'R' 누계, 'T' 표시 수, 'A' 답
class _Stage {
  final String kind;
  final int col;
  const _Stage(this.kind, this.col);
  String get key => '$kind:$col';
}

List<_WalkRef> _walkOrder(AdditionSolution s) {
  final order = <_WalkRef>[];
  for (var c = s.cols - 1; c >= 0; c--) {
    for (var i = 0; i < s.columns[c].walk.length; i++) {
      order.add(_WalkRef(c, i));
    }
  }
  return order;
}

List<_Stage> _stages(AdditionSolution s) {
  final list = <_Stage>[];
  for (var c = s.cols - 1; c >= s.lead; c--) {
    list.add(_Stage('R', c));
    list.add(_Stage('T', c));
  }
  for (var c = s.cols - 1; c >= 0; c--) {
    list.add(_Stage('A', c));
  }
  return list;
}

/// 오른쪽 끝에서 몇 번째 열인지로 자리 이름을 만든다.
String _columnName(AdditionSolution s, int col) {
  const names = ['일', '십', '백', '천', '만', '십만', '백만', '천만', '억'];
  final q = s.cols - 1 - col;
  if (q >= 0 && q < names.length) return '${names[q]}의 자리 열';
  return '${q + 1}번째 열';
}

class AdditionPage extends StatefulWidget {
  const AdditionPage({super.key});

  @override
  State<AdditionPage> createState() => _AdditionPageState();
}

class _AdditionPageState extends State<AdditionPage> {
  final Random _random = Random();
  final TextEditingController _inputController =
      TextEditingController(text: '786 459 878 697');
  String? _inputError;

  // 풀이 보기
  late AdditionSolution _sol;
  late List<_WalkRef> _order;
  int _done = 5;

  // 연습하기
  late AdditionSolution _pSol;
  late List<_Stage> _pStages;
  int _pDone = 0;
  int _pMisses = 0;
  int? _pWrong;
  bool _pFinished = false;
  int _count = 4;
  int _digits = 3;
  bool _showAid = true;

  // 기록
  int _solved = 0;
  int _entriesTotal = 0;
  int _entriesFirst = 0;

  @override
  void initState() {
    super.initState();
    _sol = solveAddition(const ['786', '459', '878', '697']);
    _order = _walkOrder(_sol);
    _pSol = solveAddition(_randomNumbers(_count, _digits));
    _pStages = _stages(_pSol);
    _loadStats();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _solved = prefs.getInt('add_solved') ?? 0;
        _entriesTotal = prefs.getInt('add_entriesTotal') ?? 0;
        _entriesFirst = prefs.getInt('add_entriesFirst') ?? 0;
      });
    } catch (_) {
      // 기록을 읽지 못해도 앱은 그대로 쓴다.
    }
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('add_solved', _solved);
      await prefs.setInt('add_entriesTotal', _entriesTotal);
      await prefs.setInt('add_entriesFirst', _entriesFirst);
    } catch (_) {
      // 저장 실패는 무시한다.
    }
  }

  List<String> _randomNumbers(int count, int digits) {
    final list = <String>[];
    for (var n = 0; n < count; n++) {
      final buf = StringBuffer(1 + _random.nextInt(9));
      for (var i = 1; i < digits; i++) {
        buf.write(_random.nextInt(10));
      }
      list.add(buf.toString());
    }
    return list;
  }

  void _setSolve(List<String> numbers) {
    setState(() {
      _sol = solveAddition(numbers);
      _order = _walkOrder(_sol);
      _done = 0;
      _inputError = null;
      _inputController.text = numbers.join(' ');
    });
  }

  void _applyInput() {
    FocusScope.of(context).unfocus();
    final numbers = <String>[];
    for (final part in _inputController.text.split(RegExp(r'[^0-9]+'))) {
      if (part.isEmpty) continue;
      var s = part.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      if (s.length > 7) s = s.substring(0, 7);
      numbers.add(s);
      if (numbers.length == 10) break;
    }
    if (numbers.length < 2) {
      setState(() => _inputError = '수를 두 개 이상 넣어 주세요.');
      return;
    }
    _setSolve(numbers);
  }

  void _newProblem() {
    setState(() {
      _pSol = solveAddition(_randomNumbers(_count, _digits));
      _pStages = _stages(_pSol);
      _pDone = 0;
      _pMisses = 0;
      _pWrong = null;
      _pFinished = false;
    });
  }

  int _expected(_Stage st) {
    if (st.kind == 'R') return _pSol.columns[st.col].running;
    if (st.kind == 'T') return _pSol.columns[st.col].ticks;
    return _pSol.answerSteps[_pSol.cols - 1 - st.col].write;
  }

  void _enter(int value) {
    if (_pFinished) return;
    final st = _pStages[_pDone];
    if (value == _expected(st)) {
      setState(() {
        _entriesTotal += 1;
        if (_pMisses == 0) _entriesFirst += 1;
        _pDone += 1;
        _pMisses = 0;
        _pWrong = null;
        if (_pDone >= _pStages.length) {
          _pFinished = true;
          _solved += 1;
        }
      });
      _saveStats();
    } else {
      setState(() {
        _pMisses += 1;
        _pWrong = value;
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
        appBar: AppBar(title: const Text('덧셈 (11을 넘겨 세지 않기)')),
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
                    _buildPractice(theme),
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

  /// 버튼들을 한 줄에 같은 너비로 놓는다. filled 번째 버튼만 채운 버튼.
  Widget _buttonRow(List<(String, VoidCallback?)> items, {int filled = -1}) {
    const pad = EdgeInsets.symmetric(horizontal: 4);
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final (text, onTap) = items[i];
      final label = FittedBox(child: Text(text));
      if (i > 0) children.add(const SizedBox(width: 6));
      children.add(Expanded(
        child: i == filled
            ? FilledButton(
                style: FilledButton.styleFrom(padding: pad),
                onPressed: onTap,
                child: label,
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(padding: pad),
                onPressed: onTap,
                child: label,
              ),
      ));
    }
    return Row(children: children);
  }

  /// 숫자판을 남은 공간에 맞게 줄여서 보여 준다 (스크롤 없음).
  Widget _fitBoard(Widget board) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: board,
      ),
    );
  }

  /// 0~10 숫자 버튼 (6개, 5개 두 줄)
  Widget _keypad() {
    Widget key(int d) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: SizedBox(
              height: 36,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _pFinished ? null : () => _enter(d),
                child: Text(
                  '$d',
                  style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        );
    return Column(
      children: [
        Row(children: [for (var d = 0; d <= 5; d++) key(d)]),
        Row(children: [
          for (var d = 6; d <= 10; d++) key(d),
          const Spacer(),
        ]),
      ],
    );
  }

  Widget _numbered(ThemeData theme, List<String> lines) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildRule(ThemeData theme) {
    final small = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget formula(String text) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('덧셈 규칙', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '긴 세로 덧셈을 큰 수를 머리에 담지 않고 합니다. '
              '세는 수가 11을 넘지 않게 하는 것이 핵심입니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _numbered(theme, const [
              '열 하나를 위에서 아래로 더해 갑니다. 어느 열부터 해도 됩니다.',
              '합이 11 이상이 되면 11을 빼고, 그 숫자 옆에 표시(′)를 하나 합니다.',
              '열이 끝나면 남은 수(누계)와 표시의 개수를 열 아래에 적습니다.',
              '답은 오른쪽부터, 누계에 그 열의 표시 수와 오른쪽 이웃 열의 표시 수를 더해 적습니다. '
                  '10 이상이면 일의 자리만 적고 나머지는 왼쪽으로 올립니다.',
            ]),
            formula('답의 한 자리 =\n누계 + 표시 수 + 이웃 열 표시 수 + 올림'),
            const SizedBox(height: 16),
            Text('검산', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _numbered(theme, const [
              '열마다 숫자를 그냥 더해 한 자리로 줄입니다. 9는 빼고 더해도 됩니다.',
              '열마다 누계 + 표시 수 + 표시 수를 한 자리로 줄입니다. '
                  '1번과 같아야 하며, 다른 열이 있으면 그 열만 다시 봅니다.',
              '답의 자릿수 합이, 열 검산 숫자를 모두 더해 줄인 값과 같은지 봅니다.',
            ]),
            Text(
              '9와 0은 같은 것으로 봅니다. 같은 계산을 한 번 더 하는 것보다 '
              '이렇게 다른 길로 확인하는 편이 실수를 잘 잡아냅니다.',
              style: small,
            ),
            const SizedBox(height: 12),
            Text('옆으로 밀면 풀이 보기와 연습하기로 넘어갑니다.', style: small),
          ],
        ),
      ),
    );
  }

  Widget _buildSolve(ThemeData theme) {
    final s = _sol;
    final walkTotal = _order.length;
    final total = walkTotal + s.cols;
    final finished = _done >= total;
    final walkDone = min(_done, walkTotal);
    final answerDone = _done > walkTotal ? _done - walkTotal : 0;

    // 지금까지 찍힌 표시와, 끝까지 내려간 열
    final tickCells = <String>{};
    final stepsDoneInCol = List<int>.filled(s.cols, 0);
    for (var k = 0; k < walkDone; k++) {
      final ref = _order[k];
      final w = s.columns[ref.col].walk[ref.index];
      stepsDoneInCol[ref.col] += 1;
      if (w.tick) tickCells.add('${w.row}:${ref.col}');
    }
    final shownCols = <int>{};
    for (var c = 0; c < s.cols; c++) {
      final len = s.columns[c].walk.length;
      if (len == 0 ? walkDone >= walkTotal : stepsDoneInCol[c] >= len) {
        shownCols.add(c);
      }
    }

    String? currentCell;
    String? slot;
    final highlights = <String>{};
    Widget message;
    if (finished) {
      message = _AddInfoBox(
        color: theme.colorScheme.primary,
        title: '합계 ${withCommas(s.answer)}',
      );
    } else if (_done < walkTotal) {
      final ref = _order[_done];
      final w = s.columns[ref.col].walk[ref.index];
      currentCell = '${w.row}:${ref.col}';
      message = _AddInfoBox(
        color: theme.colorScheme.primary,
        title: '${_columnName(s, ref.col)}: ${w.digit} 더하기',
        detail: w.text,
      );
    } else {
      final q = _done - walkTotal;
      final c = s.cols - 1 - q;
      slot = 'A:$c';
      highlights.addAll(['R:$c', 'T:$c', 'T:${c + 1}']);
      message = _AddInfoBox(
        color: theme.colorScheme.primary,
        title: '답: ${_columnName(s, c)}',
        detail: s.answerSteps[q].calc(),
      );
    }

    void columnEnd() {
      if (_done >= walkTotal) return;
      final col = _order[_done].col;
      var next = _done;
      while (next < walkTotal && _order[next].col == col) {
        next += 1;
      }
      setState(() => _done = next);
    }

    final okCols = <String>[];
    final columnChecks = <String>[];
    final tableChecks = <String>[];
    for (var c = s.lead; c < s.cols; c++) {
      columnChecks.add('${s.columns[c].columnCheck}');
      tableChecks.add('${s.columns[c].tableCheck}');
      okCols.add(
        s.columns[c].columnCheck % 9 == s.columns[c].tableCheck % 9 ? '○' : '×',
      );
    }
    final finalOk = s.answerCheck % 9 == s.columnsCheck % 9;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      labelText: '더할 수 (띄어쓰기로 구분, 10개까지)',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      errorText: _inputError,
                    ),
                    onSubmitted: (_) => _applyInput(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _applyInput,
                  child: const Text('풀기'),
                ),
                TextButton(
                  onPressed: () => _setSolve(_randomNumbers(5, 4)),
                  child: const Text('무작위'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _fitBoard(AdditionBoardView(
              solution: s,
              tickCells: tickCells,
              runningCols: shownCols,
              tickCountCols: shownCols,
              answerDone: answerDone,
              currentCell: currentCell,
              highlights: highlights,
              slot: slot,
              scroll: false,
            )),
            const SizedBox(height: 8),
            message,
            const SizedBox(height: 8),
            _buttonRow(
              [
                ('이전', _done == 0 ? null : () => setState(() => _done -= 1)),
                ('다음', finished ? null : () => setState(() => _done += 1)),
                ('이 열 끝까지', _done >= walkTotal ? null : columnEnd),
                ('끝까지', finished ? null : () => setState(() => _done = total)),
                ('처음부터', () => setState(() => _done = 0)),
              ],
              filled: 1,
            ),
            if (finished) ...[
              const SizedBox(height: 8),
              Text('검산', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                '열 숫자 합      : ${columnChecks.join('  ')}\n'
                '누계+표시+표시  : ${tableChecks.join('  ')}\n'
                '열별 일치       : ${okCols.join('  ')}\n'
                '답 ${withCommas(s.answer)} → ${s.answerCheck},  '
                '열 검산 합 → ${s.columnsCheck} : '
                '${finalOk ? '같으므로 통과' : '다름'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPractice(ThemeData theme) {
    final s = _pSol;
    final rate = _entriesTotal == 0
        ? '–'
        : '${(_entriesFirst * 100 / _entriesTotal).round()}%';

    // 이미 맞힌 칸들
    final runningCols = <int>{for (var c = 0; c < s.lead; c++) c};
    final tickCountCols = <int>{for (var c = 0; c < s.lead; c++) c};
    final tickCells = <String>{};
    var answerDone = 0;
    for (var k = 0; k < _pDone; k++) {
      final st = _pStages[k];
      if (st.kind == 'R') {
        runningCols.add(st.col);
      } else if (st.kind == 'T') {
        tickCountCols.add(st.col);
        for (final w in s.columns[st.col].walk) {
          if (w.tick) tickCells.add('${w.row}:${st.col}');
        }
      } else {
        answerDone += 1;
      }
    }

    String? slot;
    int? activeCol;
    final highlights = <String>{};
    Widget message;
    if (_pFinished) {
      message = _AddInfoBox(
        color: theme.colorScheme.primary,
        title: '정답입니다. 합계 ${withCommas(s.answer)}',
        detail: '새 문제를 누르면 다음 문제가 나옵니다.',
      );
    } else {
      final st = _pStages[_pDone];
      slot = st.key;
      final name = _columnName(s, st.col);
      String title;
      String ask;
      String hint;
      if (st.kind == 'A') {
        final step = s.answerSteps[s.cols - 1 - st.col];
        if (_showAid) {
          highlights.addAll(['R:${st.col}', 'T:${st.col}', 'T:${st.col + 1}']);
        }
        title = '답: $name';
        ask = '이 자리에 적을 숫자는 무엇일까요?';
        hint = step.calc(reveal: _pMisses >= 2);
      } else {
        if (_showAid) activeCol = st.col;
        title = st.kind == 'R' ? '$name의 누계' : '$name의 표시 수';
        ask = st.kind == 'R' ? '위에서 아래로 더하고 남은 수는 얼마일까요?' : '11을 뺀 횟수는 몇 번일까요?';
        hint = _pMisses >= 2
            ? s.columns[st.col].walkText
            : '위에서부터 다시 더해 보세요. 11 이상이 되면 11을 빼고 표시를 하나 합니다.';
      }
      if (_pWrong != null) {
        message = _AddInfoBox(
          color: theme.colorScheme.error,
          title: '틀린 답 $_pWrong. $title',
          detail: hint,
        );
      } else {
        message = _AddInfoBox(
          color: theme.colorScheme.primary,
          title: title,
          detail: ask,
        );
      }
    }

    // 시스템 글자 크기를 크게 해 둔 폰에서는 안내문·버튼이 커지면서
    // 숫자판이 줄어든다. 연습 화면에서는 글자 배율을 1배로 고정한다.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 설정과 새 문제, 오른쪽: 숫자판 (세로 공간을 숫자판에 몰아 준다)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 104,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton(
                              onPressed: _newProblem,
                              child: const Text('새 문제'),
                            ),
                            const SizedBox(height: 12),
                            DropdownButton<int>(
                              isDense: true,
                              value: _count,
                              items: const [
                                DropdownMenuItem<int>(
                                    value: 3, child: Text('수 3개')),
                                DropdownMenuItem<int>(
                                    value: 4, child: Text('수 4개')),
                                DropdownMenuItem<int>(
                                    value: 6, child: Text('수 6개')),
                                DropdownMenuItem<int>(
                                    value: 8, child: Text('수 8개')),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                _count = v;
                                _newProblem();
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButton<int>(
                              isDense: true,
                              value: _digits,
                              items: const [
                                DropdownMenuItem<int>(
                                    value: 2, child: Text('두 자리')),
                                DropdownMenuItem<int>(
                                    value: 3, child: Text('세 자리')),
                                DropdownMenuItem<int>(
                                    value: 4, child: Text('네 자리')),
                                DropdownMenuItem<int>(
                                    value: 5, child: Text('다섯 자리')),
                                DropdownMenuItem<int>(
                                    value: 6, child: Text('여섯 자리')),
                                DropdownMenuItem<int>(
                                    value: 7, child: Text('일곱 자리')),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                _digits = v;
                                _newProblem();
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: _showAid,
                                  onChanged: (v) =>
                                      setState(() => _showAid = v ?? true),
                                ),
                                const Flexible(child: Text('열·칸 표시')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topRight,
                        child: AdditionBoardView(
                          solution: s,
                          tickCells: tickCells,
                          runningCols: runningCols,
                          tickCountCols: tickCountCols,
                          answerDone: answerDone,
                          highlights: highlights,
                          slot: slot,
                          activeCol: activeCol,
                          scroll: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              message,
              const SizedBox(height: 8),
              _keypad(),
              const SizedBox(height: 4),
              Text(
                '푼 문제 $_solved    한 번에 맞힌 칸 $rate',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 덧셈 숫자판: 더할 수들, 누계 줄, 표시 줄, 답 줄.
class AdditionBoardView extends StatelessWidget {
  final AdditionSolution solution;

  /// 표시(′)를 보여 줄 칸들. '줄:열' 형태
  final Set<String> tickCells;

  /// 누계를 보여 줄 열
  final Set<int> runningCols;

  /// 표시 수를 보여 줄 열
  final Set<int> tickCountCols;

  /// 이미 적은 답의 자리 수 (오른쪽부터)
  final int answerDone;

  /// 지금 더하는 숫자 칸. '줄:열' 형태
  final String? currentCell;

  /// 강조할 누계·표시 칸. 'R:열', 'T:열' 형태
  final Set<String> highlights;

  /// 지금 채울 빈칸. 'R:열', 'T:열', 'A:열' 형태
  final String? slot;

  /// 연습에서 지금 더하고 있는 열
  final int? activeCol;

  /// 넓을 때 옆으로 스크롤할지 여부 (false면 바깥에서 크기를 맞춘다)
  final bool scroll;

  const AdditionBoardView({
    super.key,
    required this.solution,
    required this.tickCells,
    required this.runningCols,
    required this.tickCountCols,
    required this.answerDone,
    this.currentCell,
    this.highlights = const <String>{},
    this.slot,
    this.activeCol,
    this.scroll = true,
  });

  static const double _w = 38;
  static const double _h = 40;
  static const double _gap = 3;
  static const double _labelW = 40;

  Widget _box({
    required Widget child,
    Color? fill,
    Color? border,
    bool underline = false,
    Color? underlineColor,
  }) {
    return Container(
      width: _w,
      height: _h,
      margin: const EdgeInsets.only(right: _gap),
      alignment: Alignment.center,
      decoration: underline
          ? BoxDecoration(
              color: fill,
              border: Border(
                bottom: BorderSide(
                  color: underlineColor ?? Colors.transparent,
                  width: 2,
                ),
              ),
            )
          : BoxDecoration(
              color: fill,
              border: Border.all(
                color: border ?? Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
      child: child,
    );
  }

  Widget _label(String text, Color color) {
    return SizedBox(
      width: _labelW,
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = solution;
    const digitStyle = TextStyle(fontSize: 22, fontFamily: 'monospace');
    const boldStyle = TextStyle(
      fontSize: 22,
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
    );

    final rows = <Widget>[];

    // 더할 수들
    for (var r = 0; r < s.grid.length; r++) {
      final cells = <Widget>[_label('', scheme.onSurfaceVariant)];
      for (var c = 0; c < s.cols; c++) {
        final d = s.grid[r][c];
        final key = '$r:$c';
        final isCurrent = key == currentCell;
        final inActive = activeCol == c && d != null;
        cells.add(_box(
          fill: isCurrent
              ? scheme.primaryContainer
              : (inActive ? scheme.secondaryContainer : null),
          border: isCurrent ? scheme.primary : null,
          child: d == null
              ? const SizedBox.shrink()
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$d'),
                      if (tickCells.contains(key))
                        TextSpan(
                          text: '′',
                          style: TextStyle(
                            color: scheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  style: isCurrent ? boldStyle : digitStyle,
                ),
        ));
      }
      rows.add(Row(children: cells));
      rows.add(const SizedBox(height: _gap));
    }

    rows.add(Container(
      width: _labelW + s.cols * (_w + _gap),
      height: 2,
      color: scheme.outline,
    ));
    rows.add(const SizedBox(height: _gap));

    // 누계 줄과 표시 줄
    Widget tableRow(String label, String kind, Set<int> shown) {
      final cells = <Widget>[_label(label, scheme.onSurfaceVariant)];
      for (var c = 0; c < s.cols; c++) {
        final key = '$kind:$c';
        final isSlot = key == slot;
        final isHi = highlights.contains(key);
        final value = kind == 'R' ? s.columns[c].running : s.columns[c].ticks;
        cells.add(_box(
          fill: isHi ? scheme.tertiaryContainer : null,
          border: isSlot ? scheme.primary : (isHi ? scheme.tertiary : null),
          child: Text(
            shown.contains(c) && !isSlot ? '$value' : '',
            style: digitStyle,
          ),
        ));
      }
      return Row(children: cells);
    }

    rows.add(tableRow('누계', 'R', runningCols));
    rows.add(const SizedBox(height: _gap));
    rows.add(tableRow('표시', 'T', tickCountCols));
    rows.add(const SizedBox(height: _gap));
    rows.add(Container(
      width: _labelW + s.cols * (_w + _gap),
      height: 2,
      color: scheme.outline,
    ));
    rows.add(const SizedBox(height: _gap));

    // 답 줄
    final answerCells = <Widget>[_label('답', scheme.onSurfaceVariant)];
    for (var c = 0; c < s.cols; c++) {
      final q = s.cols - 1 - c;
      final isSlot = slot == 'A:$c';
      answerCells.add(_box(
        border: isSlot ? scheme.primary : null,
        underline: !isSlot,
        underlineColor: scheme.outlineVariant,
        child: Text(
          q < answerDone ? '${s.answerSteps[q].write}' : '',
          style: boldStyle,
        ),
      ));
    }
    rows.add(Row(children: answerCells));

    final board = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
    if (!scroll) return board;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: board,
    );
  }
}

class _AddInfoBox extends StatelessWidget {
  final Color color;
  final String title;
  final String? detail;

  const _AddInfoBox({required this.color, required this.title, this.detail});

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
            Text(detail!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

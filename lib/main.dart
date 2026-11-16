import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'addition_page.dart';
import 'direct_page.dart';
import 'trachtenberg.dart';

void main() {
  runApp(const NeighborMultiplyApp());
}

class NeighborMultiplyApp extends StatelessWidget {
  const NeighborMultiplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F6B5C);
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

const String appName = '속기 셈법';

/// 첫 화면: 앱 이름과 '시작하기' 버튼
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    '×+',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  appName,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '구구단 없이 빠르게 계산하는 방법',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  '기본 곱셈 · 직접 곱셈 · 덧셈',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const Spacer(flex: 4),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const RootPage(),
                      ),
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 아래쪽 메뉴로 기본 곱셈(1장), 직접 곱셈(2장), 덧셈(4장)을 오간다.
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomePage(),
          DirectPage(),
          AdditionPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.looks_one_outlined),
            selectedIcon: Icon(Icons.looks_one),
            label: '기본 곱셈',
          ),
          NavigationDestination(
            icon: Icon(Icons.looks_two_outlined),
            selectedIcon: Icon(Icons.looks_two),
            label: '직접 곱셈',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: '덧셈',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Random _random = Random();
  final TextEditingController _numController =
      TextEditingController(text: '2684');

  int _m = 6;

  // 풀이 보기
  late Solution _solveSol;
  int _solveDone = 3;

  // 연습하기
  late Solution _pracSol;
  int _pracDone = 0;
  int _pracMisses = 0;
  int? _pracWrong;
  bool _pracFinished = false;
  int _pracLen = 4;
  bool _showAid = true;

  // 기록
  int _solved = 0;
  int _digitsTotal = 0;
  int _digitsFirst = 0;

  @override
  void initState() {
    super.initState();
    _solveSol = solve('2684', _m);
    _pracSol = solve(_randomNumber(_pracLen), _m);
    _loadStats();
  }

  @override
  void dispose() {
    _numController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _solved = prefs.getInt('solved') ?? 0;
        _digitsTotal = prefs.getInt('digitsTotal') ?? 0;
        _digitsFirst = prefs.getInt('digitsFirst') ?? 0;
      });
    } catch (_) {
      // 기록을 읽지 못해도 앱은 그대로 쓴다.
    }
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('solved', _solved);
      await prefs.setInt('digitsTotal', _digitsTotal);
      await prefs.setInt('digitsFirst', _digitsFirst);
    } catch (_) {
      // 저장 실패는 무시한다.
    }
  }

  String _randomNumber(int len) {
    final buf = StringBuffer(1 + _random.nextInt(9));
    for (var i = 1; i < len; i++) {
      buf.write(_random.nextInt(10));
    }
    return buf.toString();
  }

  void _setSolve(String number, int done) {
    setState(() {
      _solveSol = solve(number, _m);
      _solveDone = min(done, _solveSol.steps.length);
      _numController.text = number;
    });
  }

  void _applyInput() {
    var raw = _numController.text.replaceAll(RegExp(r'\D'), '');
    raw = raw.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (raw.length > 9) raw = raw.substring(0, 9);
    if (raw.isEmpty) raw = '0';
    FocusScope.of(context).unfocus();
    _setSolve(raw, 0);
  }

  void _newProblem() {
    setState(() {
      _pracSol = solve(_randomNumber(_pracLen), _m);
      _pracDone = 0;
      _pracMisses = 0;
      _pracWrong = null;
      _pracFinished = false;
    });
  }

  void _selectMultiplier(int m) {
    setState(() {
      _m = m;
      _solveSol = solve(_solveSol.number, _m);
      _solveDone = 0;
      _pracSol = solve(_randomNumber(_pracLen), _m);
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
        appBar: AppBar(title: const Text('기본 곱셈 (구구단 없이)')),
        body: SafeArea(
          child: Column(
            children: [
              // 곱하는 수: 항상 위에 고정
              _buildChips(theme),
              const TabBar(
                tabs: [
                  Tab(text: '규칙'),
                  Tab(text: '풀이 보기'),
                  Tab(text: '연습하기'),
                ],
              ),
              // 아래 세 화면은 좌우로 밀어서 넘긴다.
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

  Widget _buildChips(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: multipliers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = multipliers[index];
          return ChoiceChip(
            label: Text('× $m'),
            selected: m == _m,
            onSelected: (_) => _selectMultiplier(m),
          );
        },
      ),
    );
  }

  Widget _buildRule(ThemeData theme) {
    final rule = rules[_m]!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('× $_m 규칙', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(rule.text, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in rule.formula)
                    Text(
                      line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'd는 자기 숫자, n은 이웃(바로 오른쪽 숫자)입니다. '
              '절반은 소수점 아래를 버립니다. '
              '값이 10 이상이면 일의 자리만 적고 나머지는 왼쪽으로 올립니다.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              '답은 오른쪽부터 한 자리씩 적습니다. '
              '옆으로 밀면 풀이 보기와 연습하기로 넘어갑니다.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolve(ThemeData theme) {
    final total = _solveSol.steps.length;
    final finished = _solveDone >= total;
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
                  child: TextField(
                    controller: _numController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(
                      labelText: '곱해지는 수 (9자리까지)',
                      isDense: true,
                      border: OutlineInputBorder(),
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
                  onPressed: () => _setSolve(_randomNumber(4), 0),
                  child: const Text('무작위'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BoardView(solution: _solveSol, done: _solveDone, mark: true),
            const SizedBox(height: 8),
            const _Legend(),
            const SizedBox(height: 12),
            if (finished)
              _MessageBox(
                color: theme.colorScheme.primary,
                title: '${withCommas(_solveSol.number)} × $_m = '
                    '${withCommas(_solveSol.answer)}',
              )
            else
              _MessageBox(
                color: theme.colorScheme.primary,
                title: '다음 자리: ${_solveSol.steps[_solveDone].where}',
                calc: _solveSol.steps[_solveDone].calc(),
              ),
            const SizedBox(height: 12),
            _stepButtons(
              _solveDone,
              total,
              (v) => setState(() => _solveDone = v),
            ),
            const SizedBox(height: 12),
            // 지나간 단계는 남은 공간 안에서만 보여 준다.
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var k = 0; k < _solveDone; k++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${k + 1}. ${_solveSol.steps[k].where}\n',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextSpan(
                              text: '    ${_solveSol.steps[k].calc()}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
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

  Widget _buildPractice(ThemeData theme) {
    final rate = _digitsTotal == 0
        ? '–'
        : '${(_digitsFirst * 100 / _digitsTotal).round()}%';

    Widget message;
    if (_pracFinished) {
      message = _MessageBox(
        color: theme.colorScheme.primary,
        title: '정답입니다. ${withCommas(_pracSol.number)} × $_m = '
            '${withCommas(_pracSol.answer)}',
        calc: '새 문제를 누르면 다음 문제가 나옵니다.',
      );
    } else {
      final step = _pracSol.steps[_pracDone];
      if (_pracWrong != null) {
        message = _MessageBox(
          color: theme.colorScheme.error,
          title: '틀린 답 $_pracWrong. ${step.where}',
          calc: step.calc(reveal: _pracMisses >= 2),
        );
      } else {
        message = _MessageBox(
          color: theme.colorScheme.primary,
          title: step.where,
          calc: '이 자리에 적을 숫자는 무엇일까요?',
        );
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<int>(
                  isDense: true,
                  value: _pracLen,
                  items: const [
                    DropdownMenuItem<int>(value: 2, child: Text('두 자리')),
                    DropdownMenuItem<int>(value: 3, child: Text('세 자리')),
                    DropdownMenuItem<int>(value: 4, child: Text('네 자리')),
                    DropdownMenuItem<int>(value: 5, child: Text('다섯 자리')),
                    DropdownMenuItem<int>(value: 6, child: Text('여섯 자리')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    _pracLen = v;
                    _newProblem();
                  },
                ),
                const Spacer(),
                Checkbox(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: _showAid,
                  onChanged: (v) => setState(() => _showAid = v ?? true),
                ),
                const Flexible(child: Text('자기 숫자와 이웃 표시')),
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
                      '${withCommas(_pracSol.number)} × $_m = ?',
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
            BoardView(solution: _pracSol, done: _pracDone, mark: _showAid),
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

/// 숫자판: 올림 점, 곱해지는 수, 답을 세 줄로 보여 준다.
class BoardView extends StatelessWidget {
  final Solution solution;

  /// 이미 적은 답의 자리 수 (오른쪽부터)
  final int done;

  /// 자기 숫자와 이웃을 강조할지 여부
  final bool mark;

  const BoardView({
    super.key,
    required this.solution,
    required this.done,
    required this.mark,
  });

  static const double _w = 40;
  static const double _h = 48;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = solution.digits.length;
    final usesNb = rules[solution.m]!.nb != 0;

    final carryRow = <Widget>[];
    final digitRow = <Widget>[];
    final answerRow = <Widget>[];

    for (var j = 0; j < n; j++) {
      final k = n - 1 - j; // 이 칸에 해당하는 단계 번호
      final from = k - 1; // 이 칸으로 올림을 넘겨 주는 단계

      // 올림 점
      var dots = '';
      if (from >= 0 && from < done) {
        dots = '·' * solution.steps[from].carry;
      }
      carryRow.add(Container(
        width: _w,
        height: 18,
        margin: const EdgeInsets.only(right: _gap),
        alignment: Alignment.bottomCenter,
        child: Text(
          dots,
          style: TextStyle(
            fontSize: 22,
            height: 0.8,
            fontWeight: FontWeight.bold,
            color: scheme.error,
          ),
        ),
      ));

      // 곱해지는 수의 숫자
      final isCur = mark && done < n && k == done;
      final isNb = mark && done < n && usesNb && k == done - 1;
      Color? fill;
      Color border = Colors.transparent;
      if (isCur) {
        fill = scheme.primaryContainer;
        border = scheme.primary;
      } else if (isNb) {
        fill = scheme.tertiaryContainer;
        border = scheme.tertiary;
      }
      digitRow.add(Container(
        width: _w,
        height: _h,
        margin: const EdgeInsets.only(right: _gap),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${solution.digits[j]}',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'monospace',
            fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
            color: j < solution.leadCount && !isCur && !isNb
                ? scheme.onSurfaceVariant
                : null,
          ),
        ),
      ));

      // 답
      final isSlot = k == done;
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
          k < done ? '${solution.steps[k].write}' : '',
          style: const TextStyle(
            fontSize: 26,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    }

    digitRow.add(Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        '× ${solution.m}',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'monospace',
          color: scheme.onSurfaceVariant,
        ),
      ),
    ));

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

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget swatch(Color fill, Color border) => Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          swatch(scheme.primaryContainer, scheme.primary),
          const SizedBox(width: 6),
          Text('자기 숫자', style: style),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          swatch(scheme.tertiaryContainer, scheme.tertiary),
          const SizedBox(width: 6),
          Text('이웃', style: style),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            '·',
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              height: 0.9,
            ),
          ),
          const SizedBox(width: 6),
          Text('올림', style: style),
        ]),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  final Color color;
  final String title;
  final String? calc;

  const _MessageBox({required this.color, required this.title, this.calc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          if (calc != null) ...[
            const SizedBox(height: 4),
            Text(
              calc!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
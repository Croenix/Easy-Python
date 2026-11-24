import 'dart:async';
import 'package:flutter/material.dart';

import 'design_system.dart';
import 'pyodide_runner.dart';
import 'supernova_ai.dart';

class PythonIdeScreen extends StatefulWidget {
  const PythonIdeScreen({
    super.key,
    required this.learnerName,
    this.initialCode,
  });

  final String learnerName;
  final String? initialCode;

  @override
  State<PythonIdeScreen> createState() => _PythonIdeScreenState();
}

class _PythonIdeScreenState extends State<PythonIdeScreen> {
  final GlobalKey<PyodideRunnerState> runnerKey = GlobalKey<PyodideRunnerState>();
  final SupernovaEngine supernova = const SupernovaEngine();

  late final Map<String, String> _files;
  late String _activeFile;
  late TextEditingController _codeController;
  late ScrollController _editorScrollController;
  late ScrollController _lineScrollController;

  bool _isRunnerReady = false;
  bool _isRunning = false;
  String? _stdout;
  String? _stderr;
  int? _executionTimeMs;
  int _lineCount = 1;
  bool _showConsole = true;

  @override
  void initState() {
    super.initState();
    _files = {
      'main.py': widget.initialCode ??
          '# Supernova Python IDE\n'
          'def greet(name):\n'
          '    return f"Hello {name}, welcome to Python!"\n\n'
          'user = "${widget.learnerName.trim().isEmpty ? 'Coder' : widget.learnerName.trim()}"\n'
          'print(greet(user))\n',
      'scratch.py': '# Scratchpad for experiments\nnumbers = [1, 2, 3, 4, 5]\nsquares = [x ** 2 for x in numbers]\nprint(f"Squares: {squares}")\n',
    };
    _activeFile = 'main.py';
    _codeController = TextEditingController(text: _files[_activeFile]);
    _editorScrollController = ScrollController();
    _lineScrollController = ScrollController();

    _updateLineCount();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _editorScrollController.dispose();
    _lineScrollController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    _files[_activeFile] = _codeController.text;
    _updateLineCount();
  }

  void _updateLineCount() {
    final lines = _codeController.text.split('\n').length;
    if (lines != _lineCount) {
      setState(() => _lineCount = lines < 1 ? 1 : lines);
    }
  }

  void _switchFile(String fileName) {
    if (_activeFile == fileName) return;
    setState(() {
      _files[_activeFile] = _codeController.text;
      _activeFile = fileName;
      _codeController.text = _files[fileName] ?? '';
      _updateLineCount();
    });
  }

  void _addNewFile() async {
    final controller = TextEditingController(text: 'module_${_files.length}.py');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Python File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'e.g. math_utils.py',
            suffixText: '.py',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              var val = controller.text.trim();
              if (val.isEmpty) return;
              if (!val.endsWith('.py')) val = '$val.py';
              Navigator.pop(ctx, val);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _files[name] = '# $name\n';
        _switchFile(name);
      });
    }
  }

  void _deleteCurrentFile() {
    if (_files.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only file in the project.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $_activeFile?'),
        content: const Text('This will delete this script from memory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _files.remove(_activeFile);
                _activeFile = _files.keys.first;
                _codeController.text = _files[_activeFile] ?? '';
                _updateLineCount();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _insertSymbol(String symbol, {int cursorOffset = 0}) {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, symbol);
    final newCursor = start + symbol.length + cursorOffset;

    _codeController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor.clamp(0, newText.length)),
    );
  }

  Future<void> _runCode() async {
    if (!_isRunnerReady || _isRunning) return;
    setState(() {
      _isRunning = true;
      _showConsole = true;
      _stdout = null;
      _stderr = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final result = await runnerKey.currentState!.run(_codeController.text);
      stopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stdout = result.stdout;
        _stderr = result.stderr.isNotEmpty
            ? result.stderr
            : (result.executionError ?? '');
        _executionTimeMs = stopwatch.elapsedMilliseconds;
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _stderr = e.toString();
        _executionTimeMs = stopwatch.elapsedMilliseconds;
      });
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  void _askSupernova() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.isDarkMode ? const Color(0xFF1E2138) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SupernovaAiSheet(
        learnerName: widget.learnerName,
        code: _codeController.text,
        error: _stderr,
        stdout: _stdout,
        onApplyFix: (fixedCode) {
          Navigator.pop(ctx);
          setState(() {
            _codeController.text = fixedCode;
            _updateLineCount();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✨ Fix applied by Supernova AI!')),
          );
        },
      ),
    );
  }

  void _openTemplates() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Code Templates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
              ),
              _templateItem(
                title: 'Data Structures (Lists, Dicts, Sets)',
                subtitle: 'Collections and manipulations in Python',
                code: '# Data Structures Example\n'
                    'fruits = ["apple", "banana", "cherry"]\n'
                    'fruits.append("orange")\n'
                    'prices = {"apple": 1.2, "banana": 0.8, "orange": 1.5}\n'
                    'for f in fruits:\n'
                    '    print(f"{f}: \${prices.get(f, 0.0)}")\n',
              ),
              _templateItem(
                title: 'Functions & Recursion (Factorial)',
                subtitle: 'Clean modular functions with docstrings',
                code: 'def factorial(n):\n'
                    '    """Calculate factorial of n."""\n'
                    '    if n <= 1:\n'
                    '        return 1\n'
                    '    return n * factorial(n - 1)\n\n'
                    'for num in [3, 5, 7]:\n'
                    '    print(f"factorial({num}) = {factorial(num)}")\n',
              ),
              _templateItem(
                title: 'Class & Object-Oriented Programming',
                subtitle: 'Classes, methods, and encapsulation',
                code: 'class BankAccount:\n'
                    '    def __init__(self, owner, balance=0):\n'
                    '        self.owner = owner\n'
                    '        self.balance = balance\n\n'
                    '    def deposit(self, amount):\n'
                    '        self.balance += amount\n'
                    '        return f"Deposited \${amount}. New balance: \${self.balance}"\n\n'
                    'account = BankAccount("${widget.learnerName.trim().isEmpty ? 'Achu' : widget.learnerName.trim()}", 100)\n'
                    'print(account.deposit(50))\n',
              ),
              _templateItem(
                title: 'Algorithms: Binary Search',
                subtitle: 'O(log n) search algorithm in pure Python',
                code: 'def binary_search(arr, target):\n'
                    '    low, high = 0, len(arr) - 1\n'
                    '    while low <= high:\n'
                    '        mid = (low + high) // 2\n'
                    '        if arr[mid] == target:\n'
                    '            return mid\n'
                    '        elif arr[mid] < target:\n'
                    '            low = mid + 1\n'
                    '        else:\n'
                    '            high = mid - 1\n'
                    '    return -1\n\n'
                    'nums = [10, 23, 45, 70, 88, 92]\n'
                    'print("Index of 70:", binary_search(nums, 70))\n',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateItem({
    required String title,
    required String subtitle,
    required String code,
  }) => ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: TextStyle(color: context.appMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.pop(context);
          setState(() {
            _codeController.text = code;
            _updateLineCount();
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final editorBg = dark ? const Color(0xFF0F1221) : const Color(0xFFF7F8FC);
    final gutterBg = dark ? const Color(0xFF16192E) : const Color(0xFFEBEFF8);
    final gutterText = dark ? const Color(0xFF6B7294) : const Color(0xFF9098B2);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue, AppColors.violet],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.code_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Python IDE',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(Icons.snippet_folder_outlined),
            onPressed: _openTemplates,
          ),
          IconButton(
            tooltip: 'Supernova AI Debug',
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.orange),
            onPressed: _askSupernova,
          ),
          IconButton(
            tooltip: 'Delete File',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteCurrentFile,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // 1. Multi-file Tab Bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  border: Border(bottom: BorderSide(color: context.appBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final file in _files.keys)
                            Padding(
                              padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.description_outlined, size: 14),
                                    const SizedBox(width: 4),
                                    Text(file),
                                  ],
                                ),
                                selected: _activeFile == file,
                                onSelected: (_) => _switchFile(file),
                                selectedColor: AppColors.blue.withValues(alpha: 0.18),
                                side: BorderSide(
                                  color: _activeFile == file ? AppColors.blue : context.appBorder,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 20),
                      tooltip: 'New file',
                      onPressed: _addNewFile,
                    ),
                  ],
                ),
              ),

              // 2. Code Editor with Line Numbers Gutter
              Expanded(
                child: Container(
                  color: editorBg,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Gutter
                      Container(
                        width: 44,
                        color: gutterBg,
                        child: ListView.builder(
                          controller: _lineScrollController,
                          itemCount: _lineCount,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          itemBuilder: (context, index) => Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 8),
                            height: 22,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: gutterText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Text Editor Field
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          scrollController: _editorScrollController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          expands: true,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.57,
                            color: dark ? const Color(0xFFF3F5FA) : const Color(0xFF1E243A),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.fromLTRB(10, 14, 10, 14),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Mobile Code Accessory Bar (Symbols & Keywords)
              _symbolAccessoryBar(),

              // 4. Console Section (Collapsible)
              if (_showConsole) _consolePanel(),
            ],
          ),

          // Hidden Pyodide Runner Loopback instance
          Positioned(
            left: 0,
            bottom: 0,
            child: IgnorePointer(
              child: PyodideRunner(
                key: runnerKey,
                onReady: (ready) {
                  if (mounted && _isRunnerReady != ready) {
                    setState(() => _isRunnerReady = ready);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRunnerReady && !_isRunning ? _runCode : null,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: _isRunning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.play_arrow_rounded, size: 24),
        label: Text(
          _isRunning
              ? 'Executing…'
              : (_isRunnerReady ? 'Run Script' : 'Starting Engine…'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _symbolAccessoryBar() {
    final symbols = [
      ('Tab', '    ', 0),
      (':', ':', 0),
      ('(', '()', -1),
      (')', ')', 0),
      ('[', '[]', -1),
      (']', ']', 0),
      ('{', '{}', -1),
      ('}', '}', 0),
      ('"', '""', -1),
      ("'", "''", -1),
      ('=', '=', 0),
      ('==', '==', 0),
      ('!=', '!=', 0),
      ('+', '+', 0),
      ('-', '-', 0),
      ('*', '*', 0),
      ('/', '/', 0),
      ('print()', 'print()', -1),
      ('def', 'def ', 0),
      ('return', 'return ', 0),
      ('if', 'if ', 0),
      ('elif', 'elif ', 0),
      ('else', 'else:\n    ', 0),
      ('for', 'for ', 0),
      ('in', 'in ', 0),
      ('while', 'while ', 0),
      ('import', 'import ', 0),
    ];

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(
          top: BorderSide(color: context.appBorder),
          bottom: BorderSide(color: context.appBorder),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        itemCount: symbols.length,
        itemBuilder: (context, index) {
          final item = symbols[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: context.isDarkMode ? const Color(0xFF262A48) : const Color(0xFFE9ECF8),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _insertSymbol(item.$2, cursorOffset: item.$3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Center(
                    child: Text(
                      item.$1,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.appText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _consolePanel() {
    final dark = context.isDarkMode;
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF090C17) : const Color(0xFF141828),
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: dark ? const Color(0xFF12162A) : const Color(0xFF1E243A),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, size: 16, color: AppColors.blue),
                const SizedBox(width: 8),
                const Text(
                  'TERMINAL OUTPUT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_executionTimeMs != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    '${_executionTimeMs}ms',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear_all_rounded, size: 18, color: Colors.white70),
                  tooltip: 'Clear Output',
                  onPressed: () => setState(() {
                    _stdout = null;
                    _stderr = null;
                    _executionTimeMs = null;
                  }),
                ),
                IconButton(
                  icon: Icon(
                    _showConsole ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: Colors.white70,
                  ),
                  tooltip: 'Toggle Console',
                  onPressed: () => setState(() => _showConsole = !_showConsole),
                ),
              ],
            ),
          ),
          // Output Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_stdout != null && _stdout!.isNotEmpty)
                    SelectableText(
                      _stdout!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFFE2E8F0),
                        height: 1.45,
                      ),
                    ),
                  if (_stderr != null && _stderr!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SelectableText(
                        _stderr!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFFFF6B6B),
                          height: 1.45,
                        ),
                      ),
                    ),
                  if ((_stdout == null || _stdout!.isEmpty) &&
                      (_stderr == null || _stderr!.isEmpty))
                    Text(
                      _isRunnerReady
                          ? 'Python ready. Tap "Run Script" to execute.'
                          : 'Initializing offline Python runtime…',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupernovaAiSheet extends StatelessWidget {
  const _SupernovaAiSheet({
    required this.learnerName,
    required this.code,
    this.error,
    this.stdout,
    required this.onApplyFix,
  });

  final String learnerName;
  final String code;
  final String? error;
  final String? stdout;
  final ValueChanged<String> onApplyFix;

  @override
  Widget build(BuildContext context) {
    const supernova = SupernovaEngine();
    final analysis = supernova.generateResponse(
      prompt: error != null && error!.isNotEmpty
          ? 'Debug this error: $error'
          : 'Analyze and optimize this code: $code',
      userName: learnerName,
      editorCode: code,
      terminalOutput: error ?? stdout,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.violet],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Supernova AI Copilot',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        'Live Code Diagnostics & Optimization',
                        style: TextStyle(color: context.appMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: SingleChildScrollView(
                child: Text(
                  analysis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: context.appText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Got it, thanks Supernova!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

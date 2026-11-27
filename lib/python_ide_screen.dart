import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design_system.dart';
import 'on_device_tutor.dart';
import 'pyodide_runner.dart';

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
  final GlobalKey<PyodideRunnerState> runnerKey =
      GlobalKey<PyodideRunnerState>();

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
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _files = {
      'main.py':
          widget.initialCode ??
          '# Python IDE practice project\n'
              'def greet(name):\n'
              '    return f"Hello {name}, welcome to Python!"\n\n'
              'user = "${widget.learnerName.trim().isEmpty ? 'Coder' : widget.learnerName.trim()}"\n'
              'print(greet(user))\n',
      'scratch.py':
          '# Scratchpad for experiments\nnumbers = [1, 2, 3, 4, 5]\nsquares = [x ** 2 for x in numbers]\nprint(f"Squares: {squares}")\n',
      'test_main.py':
          '# Run this file with the Run Tests button.\n'
          'from main import greet\n\n'
          'assert greet("Python") == "Hello Python, welcome to Python!"\n'
          'print("All tests passed.")\n',
    };
    _activeFile = 'main.py';
    _codeController = TextEditingController(text: _files[_activeFile]);
    _editorScrollController = ScrollController();
    _lineScrollController = ScrollController();
    _editorScrollController.addListener(_syncLineNumbers);

    _updateLineCount();
    _codeController.addListener(_onCodeChanged);
    _restoreProject();
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _editorScrollController.removeListener(_syncLineNumbers);
    _codeController.dispose();
    _editorScrollController.dispose();
    _lineScrollController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  void _syncLineNumbers() {
    if (!_lineScrollController.hasClients ||
        !_editorScrollController.hasClients) {
      return;
    }
    final target = _editorScrollController.offset.clamp(
      _lineScrollController.position.minScrollExtent,
      _lineScrollController.position.maxScrollExtent,
    );
    if ((_lineScrollController.offset - target).abs() > 1) {
      _lineScrollController.jumpTo(target);
    }
  }

  void _onCodeChanged() {
    _files[_activeFile] = _codeController.text;
    _updateLineCount();
    _scheduleSave();
  }

  String get _projectStorageKey =>
      'python_ide_project_${widget.learnerName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

  Future<void> _restoreProject() async {
    if (widget.initialCode != null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_projectStorageKey);
    if (raw == null || !mounted) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final restored = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      if (restored.isEmpty ||
          !restored.keys.every((name) => name.endsWith('.py'))) {
        return;
      }
      setState(() {
        _files
          ..clear()
          ..addAll(restored);
        _activeFile = restored.containsKey('main.py')
            ? 'main.py'
            : restored.keys.first;
        _codeController.text = _files[_activeFile] ?? '';
        _updateLineCount();
      });
    } catch (_) {
      // Ignore an invalid saved project and keep the starter files.
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_projectStorageKey, jsonEncode(_files));
    });
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
      _scheduleSave();
    });
  }

  void _addNewFile() async {
    final controller = TextEditingController(
      text: 'module_${_files.length}.py',
    );
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              var val = controller.text.trim();
              if (val.isEmpty) return;
              if (!val.endsWith('.py')) val = '$val.py';
              if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*\.py$').hasMatch(val)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Use a Python filename with letters, numbers, and underscores.',
                    ),
                  ),
                );
                return;
              }
              if (_files.containsKey(val)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('That project file already exists.'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx, val);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _files[_activeFile] = _codeController.text;
        _files[name] = '# $name\n';
        _activeFile = name;
        _codeController.text = _files[name]!;
        _updateLineCount();
        _scheduleSave();
      });
    }
  }

  void _deleteCurrentFile() {
    if (_files.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the only file in the project.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $_activeFile?'),
        content: const Text(
          'This will remove this script from the saved project.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _files.remove(_activeFile);
                _activeFile = _files.keys.first;
                _codeController.text = _files[_activeFile] ?? '';
                _updateLineCount();
                _scheduleSave();
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
      selection: TextSelection.collapsed(
        offset: newCursor.clamp(0, newText.length),
      ),
    );
  }

  Future<void> _runCode() async {
    if (!_isRunnerReady || _isRunning) return;
    final inputCount = RegExp(
      r'\binput\s*\(',
    ).allMatches(_files.values.join('\n')).length;
    final inputs = await _collectProgramInputs(inputCount);
    if (inputs == null || !mounted) return;
    setState(() {
      _isRunning = true;
      _showConsole = true;
      _stdout = null;
      _stderr = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final result = await runnerKey.currentState!.run(
        _codeController.text,
        inputs: inputs,
        projectFiles: Map<String, String>.of(_files),
        timeout: const Duration(seconds: 15),
      );
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

  Future<List<String>?> _collectProgramInputs(int inputCount) async {
    if (inputCount == 0) return const [];
    final controller = TextEditingController();
    final values = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Program input'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This project calls input() $inputCount time(s). Enter one value per line.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Enter each value on a new line',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Run'),
          ),
        ],
      ),
    );
    controller.dispose();
    return values?.split('\n');
  }

  Future<void> _runTests() async {
    final testFiles = _files.keys
        .where((name) => name.startsWith('test_') && name.endsWith('.py'))
        .toList(growable: false);
    if (testFiles.isEmpty) {
      const fileName = 'test_main.py';
      setState(() {
        _files[fileName] =
            '# Tests for main.py\n'
            'from main import greet\n\n'
            'assert greet("Python") == "Hello Python, welcome to Python!"\n'
            'print("All tests passed.")\n';
        _activeFile = fileName;
        _codeController.text = _files[fileName]!;
        _updateLineCount();
        _scheduleSave();
      });
    } else {
      _switchFile(testFiles.first);
    }
    await _runCode();
  }

  void _openAiTutor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.isDarkMode
          ? const Color(0xFF1E2138)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PythonAiSheet(
        learnerName: widget.learnerName,
        code: _codeController.text,
        error: _stderr,
        stdout: _stdout,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
                code:
                    '# Data Structures Example\n'
                    'fruits = ["apple", "banana", "cherry"]\n'
                    'fruits.append("orange")\n'
                    'prices = {"apple": 1.2, "banana": 0.8, "orange": 1.5}\n'
                    'for f in fruits:\n'
                    '    print(f"{f}: \${prices.get(f, 0.0)}")\n',
              ),
              _templateItem(
                title: 'Functions & Recursion (Factorial)',
                subtitle: 'Clean modular functions with docstrings',
                code:
                    'def factorial(n):\n'
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
                code:
                    'class BankAccount:\n'
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
                code:
                    'def binary_search(arr, target):\n'
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
    subtitle: Text(
      subtitle,
      style: TextStyle(color: context.appMuted, fontSize: 12),
    ),
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
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue, AppColors.violet],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.code_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Python IDE',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Run project tests',
            icon: const Icon(Icons.science_outlined, color: AppColors.green),
            onPressed: _isRunnerReady && !_isRunning ? _runTests : null,
          ),
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(Icons.snippet_folder_outlined),
            onPressed: _openTemplates,
          ),
          IconButton(
            tooltip: 'Ask AI Python tutor',
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.orange,
            ),
            onPressed: _openAiTutor,
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'delete') _deleteCurrentFile();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Delete file'),
                  ],
                ),
              ),
            ],
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
                              padding: const EdgeInsets.only(
                                right: 6,
                                top: 4,
                                bottom: 4,
                              ),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(file),
                                  ],
                                ),
                                selected: _activeFile == file,
                                onSelected: (_) => _switchFile(file),
                                selectedColor: AppColors.blue.withValues(
                                  alpha: 0.18,
                                ),
                                side: BorderSide(
                                  color: _activeFile == file
                                      ? AppColors.blue
                                      : context.appBorder,
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
                            color: dark
                                ? const Color(0xFFF3F5FA)
                                : const Color(0xFF1E243A),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
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
              color: context.isDarkMode
                  ? const Color(0xFF262A48)
                  : const Color(0xFFE9ECF8),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _insertSymbol(item.$2, cursorOffset: item.$3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                const Icon(
                  Icons.terminal_rounded,
                  size: 16,
                  color: AppColors.blue,
                ),
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
                  icon: const Icon(
                    Icons.clear_all_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                  tooltip: 'Clear Output',
                  onPressed: () => setState(() {
                    _stdout = null;
                    _stderr = null;
                    _executionTimeMs = null;
                  }),
                ),
                IconButton(
                  icon: Icon(
                    _showConsole
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
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

class _PythonAiSheet extends StatefulWidget {
  const _PythonAiSheet({
    required this.learnerName,
    required this.code,
    this.error,
    this.stdout,
  });

  final String learnerName;
  final String code;
  final String? error;
  final String? stdout;

  @override
  State<_PythonAiSheet> createState() => _PythonAiSheetState();
}

class _PythonAiSheetState extends State<_PythonAiSheet> {
  final OnDeviceTutor _tutor = OnDeviceTutor();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_IdeTutorMessage> _messages = [];
  bool _preparing = false;
  bool _sending = false;
  double _downloadProgress = 0;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _tutor.close();
    super.dispose();
  }

  Future<void> _prepareModel() async {
    setState(() {
      _preparing = true;
      _downloadProgress = 0;
    });
    try {
      await _tutor.prepare(
        customInstructions:
            'Teach Python step by step. Explain code clearly, help debug errors, and write focused tests when asked.',
        onProgress: (value) {
          if (mounted) setState(() => _downloadProgress = value);
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'On-device language model ready (${_tutor.selectedModel?.sizeLabel ?? 'downloaded'}).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Model setup failed: $error')));
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _send([String? preset]) async {
    final question = (preset ?? _input.text).trim();
    if (question.isEmpty || _sending) return;
    _input.clear();
    final userPrompt =
        '''$question

Current editor file:
```python
${widget.code}
```
${widget.error?.trim().isNotEmpty == true ? 'Latest Python error:\n${widget.error}' : ''}
${widget.stdout?.trim().isNotEmpty == true ? 'Latest program output:\n${widget.stdout}' : ''}''';
    final history = _messages
        .map(
          (message) =>
              '${message.isUser ? 'Learner' : 'Tutor'}: ${message.text}',
        )
        .toList(growable: false);
    setState(() {
      _sending = true;
      _messages.add(_IdeTutorMessage(true, question));
      _messages.add(_IdeTutorMessage(false, '', loading: true));
    });
    _scrollToBottom();
    final response = StringBuffer();
    try {
      await for (final token in _tutor.ask(
        question: userPrompt,
        level: 1,
        module: 'Python IDE',
        unlockedConcepts: const [
          'Python syntax',
          'functions',
          'lists',
          'debugging',
        ],
        customInstructions:
            'Teach like a patient Python instructor. Explain reasoning, point out risks, and give runnable examples. When asked for tests, provide unittest or pytest-style test code.',
        recentConversation: history,
        learnerName: widget.learnerName,
        buddyName: 'Python Coach',
      )) {
        response.write(token);
        if (!mounted) return;
        setState(() {
          _messages.last.text = response.toString();
          _messages.last.loading = false;
        });
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _messages.last.text = 'I could not complete that request: $error';
          _messages.last.loading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + bottomInset),
        child: SizedBox(
          height: (MediaQuery.sizeOf(context).height - bottomInset - 24)
              .clamp(280.0, 680.0)
              .toDouble(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.violet,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Python Tutor',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!_tutor.isReady)
                    TextButton.icon(
                      onPressed: _preparing ? null : _prepareModel,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        _preparing
                            ? '${(_downloadProgress * 100).round()}%'
                            : 'Get model',
                      ),
                    )
                  else
                    const Chip(label: Text('On-device model')),
                ],
              ),
              Text(
                _tutor.isReady
                    ? 'Q&A, code explanations, debugging, and test ideas powered by the local language model.'
                    : 'Ask a question now. Download the optional local model for open-ended AI answers.',
                style: TextStyle(color: context.appMuted, fontSize: 12),
              ),
              if (_preparing) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  _TutorActionChip(
                    'Explain code',
                    onTap: () => _send('Explain this code line by line.'),
                  ),
                  _TutorActionChip(
                    'Find bugs',
                    onTap: () => _send(
                      'Review this code for bugs and explain how to fix them.',
                    ),
                  ),
                  _TutorActionChip(
                    'Write tests',
                    onTap: () => _send(
                      'Write a small set of Python unit tests for this code.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Ask about Python, this file, the last run, or how to test your code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.appMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Align(
                            alignment: message.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(11),
                              constraints: const BoxConstraints(maxWidth: 360),
                              decoration: BoxDecoration(
                                color: message.isUser
                                    ? AppColors.blue.withValues(alpha: .14)
                                    : context.appSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.appBorder),
                              ),
                              child: message.loading && message.text.isEmpty
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : SelectableText(
                                      message.text,
                                      style: TextStyle(
                                        color: context.appText,
                                        height: 1.4,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask a Python question…',
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeTutorMessage {
  _IdeTutorMessage(this.isUser, this.text, {this.loading = false});

  final bool isUser;
  String text;
  bool loading;
}

class _TutorActionChip extends StatelessWidget {
  const _TutorActionChip(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      ActionChip(label: Text(label), onPressed: onTap);
}

import 'dart:async';
import 'content_pack.dart';
import 'answer_evaluator.dart';

/// Detailed result of Supernova AI analyzing a learner's code or question.
class SupernovaAnalysis {
  const SupernovaAnalysis({
    required this.isCorrect,
    required this.headline,
    required this.explanation,
    this.suggestedCode,
    this.cosmicTip,
    this.detectedError,
  });

  final bool isCorrect;
  final String headline;
  final String explanation;
  final String? suggestedCode;
  final String? cosmicTip;
  final String? detectedError;
}

/// The core Supernova AI engine for Python analysis, debugging, and tutoring.
class SupernovaEngine {
  const SupernovaEngine();

  /// Analyzes a practical answer or code submission with detailed diagnostics.
  SupernovaAnalysis analyzeSubmission({
    required PracticalItem question,
    required String userResponse,
    required String userName,
    CodeRunResult? runResult,
  }) {
    final cleanName = userName.trim().isEmpty ? 'friend' : userName.trim();
    final trimmed = userResponse.trim();

    // 1. Check Multiple Choice or Yes/No
    if (question.type == 'yesNo' || question.type == 'multipleChoice') {
      final expected = (question.answer ?? '').trim().toLowerCase();
      final actual = trimmed.toLowerCase();
      final correct = expected == actual;

      if (correct) {
        return SupernovaAnalysis(
          isCorrect: true,
          headline: 'Spot on, $cleanName! 🌟',
          explanation: question.aiExplanation ??
              'Great work! You correctly identified the right concept for this scenario.',
          cosmicTip: 'Building rock-solid fundamentals makes advanced Python intuitive.',
        );
      } else {
        return SupernovaAnalysis(
          isCorrect: false,
          headline: 'Not quite, $cleanName — let’s break it down! 💡',
          explanation: question.aiExplanation ??
              'Review the question carefully. Think about how Python evaluates this condition or data structure.',
          cosmicTip: 'Remember: Python syntax prioritizes readability and clear intent.',
        );
      }
    }

    // 2. Short Answer analysis
    if (question.type == 'shortAnswer') {
      final expected = (question.answer ?? '').trim().toLowerCase();
      final actual = trimmed.toLowerCase();
      final keywords = question.requiredKeywords
          .map((k) => k.toLowerCase())
          .toList();

      final hasKeywords = keywords.isEmpty ||
          keywords.every((kw) => actual.contains(kw));
      final wordsExpected = expected.split(RegExp(r'\s+')).toSet();
      final wordsActual = actual.split(RegExp(r'\s+')).toSet();
      final overlap = wordsExpected.intersection(wordsActual).length;
      final similarity = wordsExpected.isEmpty
          ? 1.0
          : overlap / wordsExpected.length;

      final isCorrect = (similarity >= 0.5 || actual == expected) && hasKeywords;

      if (isCorrect) {
        return SupernovaAnalysis(
          isCorrect: true,
          headline: 'Excellent answer, $cleanName! 🚀',
          explanation: question.aiExplanation ??
              'You captured the core Python concept accurately.',
          cosmicTip: 'Being able to explain code in plain English is the hallmark of a true Pythonista.',
        );
      } else {
        final missing = keywords.where((kw) => !actual.contains(kw)).toList();
        final hint = missing.isNotEmpty
            ? 'Make sure to mention "${missing.join('", "')}".'
            : 'Try focusing on the main purpose explained in the lesson.';
        return SupernovaAnalysis(
          isCorrect: false,
          headline: 'Almost there, $cleanName! 🔍',
          explanation: 'Your explanation is missing a key detail. $hint',
          cosmicTip: question.aiExplanation ?? 'Precision in terminology helps when reading official Python docs.',
        );
      }
    }

    // 3. Code & Fix-The-Bug Analysis
    if (question.type == 'code' || question.type == 'fixTheBug') {
      if (runResult == null) {
        return SupernovaAnalysis(
          isCorrect: false,
          headline: 'Awaiting execution, $cleanName! ⏳',
          explanation: 'Tap "Run and check" to execute your Python code in our offline engine.',
        );
      }

      // Check for syntax or runtime errors
      if (runResult.timedOut) {
        return SupernovaAnalysis(
          isCorrect: false,
          headline: 'Execution Timed Out! ⏱️',
          explanation: 'Your code took too long to run. Check for infinite loops (like `while True:` without a break condition).',
          cosmicTip: 'Ensure every loop has a clear progression towards its exit condition.',
        );
      }

      final stderr = runResult.stderr.trim();
      final executionError = runResult.executionError ?? '';
      final fullError = '$stderr\n$executionError'.trim();

      if (fullError.isNotEmpty) {
        return _diagnosePythonError(
          code: trimmed,
          error: fullError,
          userName: cleanName,
          question: question,
        );
      }

      // Compare output with expected test cases
      final test = question.tests.isNotEmpty ? question.tests.first : null;
      final expectedStdout = (test?['stdout']?.toString() ?? '').trim();
      final actualStdout = runResult.stdout.trim();

      if (_normalizeOutput(expectedStdout) == _normalizeOutput(actualStdout)) {
        return SupernovaAnalysis(
          isCorrect: true,
          headline: 'Brilliant work, $cleanName! Code executed flawlessly! 🎉',
          explanation: 'Your code produced the exact expected output:\n```\n$actualStdout\n```',
          cosmicTip: 'Writing clean code that passes tests on the first try is fantastic discipline.',
        );
      } else {
        return _diagnoseMismatch(
          code: trimmed,
          actual: actualStdout,
          expected: expectedStdout,
          userName: cleanName,
          question: question,
        );
      }
    }

    return SupernovaAnalysis(
      isCorrect: false,
      headline: 'Review needed, $cleanName',
      explanation: 'Please check your submission and try again.',
    );
  }

  /// Diagnoses Python syntax and runtime errors with helpful Supernova advice.
  SupernovaAnalysis _diagnosePythonError({
    required String code,
    required String error,
    required String userName,
    PracticalItem? question,
  }) {
    String headline = 'Let’s fix this error, $userName! 🛠️';
    String explanation = '';
    String? tip;
    String? suggestedCode;

    if (error.contains('SyntaxError')) {
      headline = 'Syntax Alert, $userName! ⚠️';
      if (code.contains('def ') && !code.contains(':')) {
        explanation = 'You declared a function with `def`, but forgot the trailing colon `:` at the end of the line.';
        tip = 'In Python, header statements (`def`, `if`, `for`, `while`, `class`) always end with a colon `:`.';
      } else if (code.contains('if ') && !code.contains(':')) {
        explanation = 'Your `if` statement is missing a colon `:` at the end of the condition.';
        tip = 'Conditionals in Python must end with `:`.';
      } else if (code.contains('for ') && !code.contains(':')) {
        explanation = 'Your `for` loop statement needs a colon `:` before the indented block.';
      } else if (code.contains('=') && !code.contains('==') && (code.contains('if ') || code.contains('elif '))) {
        explanation = 'You used a single `=` inside a condition. In Python, `=` assigns a variable, while `==` checks for equality.';
        tip = 'Use `x == y` to compare values in `if` checks.';
      } else {
        explanation = 'Python encountered a SyntaxError. Check for missing parentheses, quotes, or colons on lines leading up to the error.';
      }
    } else if (error.contains('IndentationError')) {
      headline = 'Indentation Needs Attention, $userName! 📐';
      explanation = 'Python relies strictly on indentation to structure code blocks. Make sure statements inside functions, loops, or `if` blocks are indented with 4 spaces.';
      tip = 'Avoid mixing tabs and spaces; standard PEP 8 uses 4 spaces per indent level.';
    } else if (error.contains('NameError')) {
      final match = RegExp(r"name '(\w+)' is not defined").firstMatch(error);
      final varName = match != null ? match.group(1) : 'a variable';
      headline = 'Undefined Name: $varName 🔍';
      explanation = 'Python cannot find `$varName`. Make sure it was created before this line, and check for typos or capitalization (Python is case-sensitive: `age` is different from `Age`).';
    } else if (error.contains('TypeError')) {
      if (error.contains('can only concatenate str') || error.contains('unsupported operand type')) {
        headline = 'Type Mismatch, $userName! 🧩';
        explanation = 'You tried to combine different data types (like adding a string and an integer directly). Convert numbers using `str()` or use an f-string: `f"Result: {val}"`.';
        tip = 'Python does not automatically coerce integers to strings in concatenation.';
      } else {
        headline = 'TypeError Detected! 🧩';
        explanation = 'A function or operator was called with an unexpected data type. Review the values being passed.';
      }
    } else if (error.contains('IndexError')) {
      headline = 'Index Out of Range! 📏';
      explanation = 'You tried to access an element past the end of a list or string. Remember that Python uses 0-based indexing: a list with 3 items has indices 0, 1, and 2.';
      tip = 'Use `len(my_list)` to verify how many elements exist before indexing.';
    } else if (error.contains('ZeroDivisionError')) {
      headline = 'Division by Zero! ⚡';
      explanation = 'You divided a number by zero. Ensure your divisor variable is checked before performing division.';
    } else {
      explanation = 'Python reported the following issue during execution:\n`$error`\nReview the line indicated in the traceback.';
    }

    return SupernovaAnalysis(
      isCorrect: false,
      headline: headline,
      explanation: explanation,
      suggestedCode: suggestedCode,
      cosmicTip: tip ?? 'Supernova AI Pro-Tip: Read Python tracebacks from bottom to top to identify the root cause.',
      detectedError: error,
    );
  }

  /// Diagnoses output mismatches when code runs without crashing but output differs.
  SupernovaAnalysis _diagnoseMismatch({
    required String code,
    required String actual,
    required String expected,
    required String userName,
    PracticalItem? question,
  }) {
    String headline = 'Close, $userName! Check the output 🎯';
    String explanation = 'Your code ran cleanly, but the output did not match what the challenge expects.\n\n'
        '• **Your Output:** `${actual.isEmpty ? "(empty / no output)" : actual}`\n'
        '• **Expected:** `$expected`';

    String tip = 'Check whether extra spaces, uppercase letters, or formatting differed.';

    // Common scenario: user created a tuple instead of list
    if (code.contains('(') && code.contains(')') && !code.contains('[') && (question?.prompt.toLowerCase().contains('list') ?? false)) {
      explanation += '\n\n💡 *Notice:* Parentheses `()` create an immutable **Tuple**, whereas square brackets `[]` create a **List**.';
      tip = 'Use square brackets `[item1, item2, ...]` to define a Python list.';
    }

    // Common scenario: missing print statement
    if (actual.isEmpty && !code.contains('print(')) {
      explanation += '\n\n💡 *Notice:* You calculated or defined the result, but didn\'t print it. Call `print(...)` to display the output.';
      tip = 'In Python scripts, use `print(variable)` to output results to the console.';
    }

    return SupernovaAnalysis(
      isCorrect: false,
      headline: headline,
      explanation: explanation,
      cosmicTip: tip,
    );
  }

  /// Normalizes whitespace and line breaks for comparing stdout.
  String _normalizeOutput(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .toLowerCase();
  }

  /// Real-time streaming response generator for conversational Supernova AI chat.
  Stream<String> streamChat({
    required String prompt,
    required String userName,
    String? currentTopic,
    String? editorCode,
    String? terminalOutput,
    List<String> conversationHistory = const [],
  }) async* {
    final response = generateResponse(
      prompt: prompt,
      userName: userName,
      currentTopic: currentTopic,
      editorCode: editorCode,
      terminalOutput: terminalOutput,
      conversationHistory: conversationHistory,
    );

    // Stream out words with realistic, responsive pace
    final words = response.split(' ');
    for (var i = 0; i < words.length; i++) {
      final chunk = i == words.length - 1 ? words[i] : '${words[i]} ';
      yield chunk;
      // Yield tiny pause every 3-4 words for smooth reading feel
      if (i % 4 == 0) {
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }
  }

  /// Generates comprehensive, high-quality Supernova AI response.
  String generateResponse({
    required String prompt,
    required String userName,
    String? currentTopic,
    String? editorCode,
    String? terminalOutput,
    List<String> conversationHistory = const [],
  }) {
    final name = userName.trim().isEmpty ? 'friend' : userName.trim();
    final pLower = prompt.toLowerCase();

    // Check if debugging IDE code
    if ((editorCode != null && editorCode.trim().isNotEmpty) &&
        (pLower.contains('debug') || pLower.contains('fix') || pLower.contains('error') || pLower.contains('check my code') || (terminalOutput != null && terminalOutput.contains('Error')))) {
      return _generateCodeDebugResponse(
        userName: name,
        code: editorCode,
        error: terminalOutput,
        userQuery: prompt,
      );
    }

    // Check for specific topics & concepts
    if (pLower.contains('list') && pLower.contains('tuple')) {
      return 'Hey $name! Here is the cosmic distinction between **Lists** and **Tuples**:\n\n'
          '1. **Lists `[ ]` (Mutable):**\n'
          '   - You can add, remove, and change items after creation.\n'
          '   - Syntax: `fruits = ["apple", "banana"]`\n'
          '   - Add item: `fruits.append("cherry")`\n\n'
          '2. **Tuples `( )` (Immutable):**\n'
          '   - Locked upon creation; cannot be modified or resized.\n'
          '   - Syntax: `coordinates = (10, 20)`\n'
          '   - Great for fixed data, dictionary keys, and memory efficiency.\n\n'
          '💡 **Supernova Mental Model:** Use lists for collections of things that change; use tuples for records whose shape never changes!';
    }

    if (pLower.contains('decorator') || pLower.contains('@')) {
      return 'Hey $name! A **Decorator** in Python is simply a function that takes another function as an argument, extends or wraps its behavior, and returns a new function — without permanently modifying the original function.\n\n'
          '```python\n'
          'def my_decorator(func):\n'
          '    def wrapper():\n'
          '        print("🌟 Before function runs")\n'
          '        func()\n'
          '        print("🚀 After function runs")\n'
          '    return wrapper\n\n'
          '@my_decorator\n'
          'def greet():\n'
          '    print("Hello from $name!")\n\n'
          'greet()\n'
          '```\n'
          'The `@my_decorator` syntax is elegant syntactic sugar for `greet = my_decorator(greet)`. Common uses include logging, authentication, and execution timing!';
    }

    if (pLower.contains('dictionary') || pLower.contains('dict')) {
      return 'Hey $name! In Python, a **Dictionary (`dict`)** stores data in key-value pairs, like a real dictionary where words map to definitions:\n\n'
          '```python\n'
          'user = {\n'
          '    "name": "$name",\n'
          '    "level": "Intermediate",\n'
          '    "xp": 120\n'
          '}\n\n'
          '# Accessing values safely\n'
          'print(user["name"])           # Prints $name\n'
          'print(user.get("role", "dev")) # Default value if key is missing\n'
          '```\n'
          '⚡ Keys must be immutable (like strings, numbers, or tuples), and lookup is lightning-fast O(1) time thanks to hash tables!';
    }

    if (pLower.contains('comprehension')) {
      return 'Hey $name! **List Comprehensions** provide a clean, readable one-liner to create lists from existing iterables:\n\n'
          '```python\n'
          '# Traditional way:\n'
          'squares = []\n'
          'for x in range(5):\n'
          '    squares.append(x ** 2)\n\n'
          '# Supernova List Comprehension way:\n'
          'squares = [x ** 2 for x in range(5)]\n'
          '# Output: [0, 1, 4, 9, 16]\n'
          '```\n'
          'You can even add conditions: `[x for x in numbers if x % 2 == 0]` filters for even numbers!';
    }

    if (pLower.contains('hint') || pLower.contains('give me a hint')) {
      final topic = currentTopic ?? 'the current Python concept';
      return 'Hey $name! Here is your Supernova hint for **$topic**:\n\n'
          '• Break the problem down into 3 simple steps: **Input**, **Process**, and **Output**.\n'
          '• Write out the logic in plain comments first using `#`.\n'
          '• Test with one simple value before writing loops or complex conditions.\n\n'
          'What line of code are you currently stuck on? Share it with me and we will solve it together!';
    }

    if (pLower.contains('practice idea') || pLower.contains('challenge')) {
      return 'Hey $name! Ready for a fast Supernova Micro-Challenge? 🚀\n\n'
          '**Mission:** Write a 4-line script that:\n'
          '1. Asks the user for their favorite Python feature.\n'
          '2. Stores it in a variable.\n'
          '3. Prints out: `"Awesome, {feature} is super powerful!"` using an f-string.\n\n'
          'Switch over to the **IDE tab** to write it and run it right now!';
    }

    if (pLower.contains('explain') || pLower.contains('simply') || pLower.contains('what is')) {
      final topic = currentTopic ?? 'Python';
      return 'Hey $name! Let’s break down **$topic** with the Supernova simplicity principle:\n\n'
          'Every Python program is built on instructions that direct how data flows:\n'
          '1. **Store data:** Variables (`x = 10`, `name = "$name"`)\n'
          '2. **Make decisions:** Conditions (`if`, `elif`, `else`)\n'
          '3. **Repeat tasks:** Loops (`for`, `while`)\n'
          '4. **Package reusable logic:** Functions (`def my_func():`)\n\n'
          'Which of these would you like to explore deeper? You can ask me anything!';
    }

    // Default friendly and knowledgeable response
    final topicContext = currentTopic != null ? ' in relation to **$currentTopic**' : '';
    return 'Hey $name! I’m **Supernova AI**, your personal Python mentor. 🌟\n\n'
        'Regarding your question$topicContext:\n\n'
        'Python is designed around clarity and readability. When working through this:\n'
        '• Check your variable types with `type(var)`.\n'
        '• Inspect outputs using `print(f"Debug: {var}")`.\n'
        '• If you have specific code you are working on, paste it right here or open the **IDE tab**, and I will analyze each line with you!\n\n'
        'What specific part should we inspect together?';
  }

  /// Analyzes arbitrary code and returns a debug breakdown with suggested fix.
  String _generateCodeDebugResponse({
    required String userName,
    required String code,
    String? error,
    required String userQuery,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Hey $userName! I analyzed your Python code and execution output:\n');

    final lines = code.split('\n');
    var foundIssue = false;

    // Check missing colons
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if ((line.startsWith('def ') || line.startsWith('if ') || line.startsWith('elif ') || line.startsWith('else') || line.startsWith('for ') || line.startsWith('while ') || line.startsWith('class ')) && !line.endsWith(':')) {
        buffer.writeln('🔍 **Line ${i + 1} Issue:** Missing colon `:` at end of statement:');
        buffer.writeln('```python\n${lines[i]} : # <-- Missing colon here\n```\n');
        foundIssue = true;
      }
    }

    // Check single '=' in if statement
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if ((line.startsWith('if ') || line.startsWith('elif ')) && line.contains('=') && !line.contains('==') && !line.contains('!=') && !line.contains('<=') && !line.contains('>=')) {
        buffer.writeln('🔍 **Line ${i + 1} Issue:** Assignment operator `=` used instead of equality check `==`:');
        buffer.writeln('Change `=` to `==` for comparison in conditionals.\n');
        foundIssue = true;
      }
    }

    if (error != null && error.trim().isNotEmpty) {
      buffer.writeln('⚠️ **Runtime Diagnostics:**');
      buffer.writeln('```\n${error.trim()}\n```\n');
      buffer.writeln('💡 **Root Cause Analysis:** Python stopped execution because of this error. ');
    } else if (!foundIssue) {
      buffer.writeln('✨ **Code Structure:** Your syntax appears valid! If your program isn\'t behaving as expected, check your logic flow, print intermediate variables with `print(f"{var=}")`, or verify loop boundary conditions.');
    }

    buffer.writeln('\n🚀 **Supernova Tip:** Keep your functions small and focused on a single responsibility. Try testing in the IDE with sample inputs!');
    return buffer.toString();
  }
}

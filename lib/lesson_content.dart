class LessonGuide {
  const LessonGuide({
    required this.plainLanguage,
    required this.whyItMatters,
    required this.walkThrough,
    required this.watchOut,
    required this.topicTakeaway,
    required this.friendProblem,
  });

  final String plainLanguage;
  final String whyItMatters;
  final String walkThrough;
  final String watchOut;
  final String topicTakeaway;
  final String friendProblem;
}

final lessonGuides = <String, LessonGuide>{
  'L1-01': LessonGuide(
    plainLanguage:
        'Python is a way to write instructions a computer can follow. A program is simply those instructions written in an order.',
    whyItMatters:
        'Once you can give clear instructions, you can make the computer show messages and help with small everyday tasks.',
    walkThrough:
        'In print("Hello, Python!"), print tells Python to show something. The words inside the quotation marks are the message.',
    watchOut:
        'Python follows instructions exactly. Keep the opening and closing quotation marks and parentheses paired.',
    topicTakeaway:
        'A program is a set of ordered instructions, and print(...) displays a message.',
    friendProblem:
        'Hey {name}, I want my computer to welcome a friend with a short message. What instruction should I start with?',
  ),
  'L1-02': LessonGuide(
    plainLanguage:
        'A program can have several instructions. Python starts at the first line and works downward, one line at a time.',
    whyItMatters:
        'Putting instructions in order helps you control what the computer does and when it does it.',
    walkThrough:
        'The example has one print instruction. Add another print line underneath it and Python will show both messages in order.',
    watchOut:
        'Each instruction needs its own line. A missing quote or parenthesis can stop the program.',
    topicTakeaway:
        'Python runs your program from the first line to the last, in order.',
    friendProblem:
        'Hey {name}, I need to show a welcome message and then a reminder underneath it. How can I make Python show them in that order?',
  ),
  'L1-03': LessonGuide(
    plainLanguage:
        'A comment is a note for people reading your program. Start the note with # and Python skips it when the program runs.',
    whyItMatters:
        'Short notes explain why a line is there, which makes a program easier to understand later.',
    walkThrough:
        'In the example, the line beginning with # describes the welcome message. The print line below it still runs normally.',
    watchOut:
        'The # must come before the note. It does not turn the following program line into a comment when it is on a separate line.',
    topicTakeaway:
        'Use # to leave a note that Python skips while running the program.',
    friendProblem:
        'Hey {name}, my welcome message works, but I want to leave a note for the next person who reads my code. Where should I put it?',
  ),
  'L1-04': LessonGuide(
    plainLanguage:
        'A variable is a name that remembers a value. Think of it as a labeled box: the label is the variable name and the value is what it holds.',
    whyItMatters:
        'You can give information a clear name and use that information again without typing it from scratch.',
    walkThrough:
        'name = "Asha" stores the text Asha under the name name. print(name) asks Python to show the saved value.',
    watchOut:
        'A single = saves a value into a variable. Choose a name that describes the information.',
    topicTakeaway:
        'A variable gives a saved value a useful name so you can use it again.',
    friendProblem:
        'Hey {name}, I want to remember my favorite fruit so I can use its name again later. How could I save that text in a variable?',
  ),
  'L1-05': LessonGuide(
    plainLanguage:
        'Python can do familiar arithmetic with numbers: add with +, subtract with -, multiply with *, and divide with /.',
    whyItMatters:
        'Small calculations help a program keep totals, count items, and work out amounts.',
    walkThrough:
        'The example saves 25 as minutes. minutes + 5 adds five to that value, and print shows the result.',
    watchOut:
        'Use a number without quotation marks when you want Python to calculate it. Quoted digits are text.',
    topicTakeaway:
        'Python can calculate with number values using arithmetic symbols.',
    friendProblem:
        'Hey {name}, I have 3 apples and then buy 2 more. How can I get Python to work out how many apples I have altogether?',
  ),
  'L1-06': LessonGuide(
    plainLanguage:
        'An f-string combines a sentence with saved values. Put f before the opening quote, then put a variable name inside braces where its value should appear.',
    whyItMatters:
        'It is an easy way to make a message that changes to match a person or a value.',
    walkThrough:
        'The example has a name variable. The braces in the f-string are replaced with the value stored in name.',
    watchOut:
        'Remember both parts: the f before the quote and braces around the variable name.',
    topicTakeaway: 'An f-string inserts saved values into a message.',
    friendProblem:
        'Hey {name}, I want my program to say “Welcome” and then include the visitor’s name. How can I put that saved name in the sentence?',
  ),
  'L1-07': LessonGuide(
    plainLanguage:
        'A data type tells Python what kind of value it is working with. Text is called str, whole numbers are int, decimal numbers are float, and yes-or-no values are bool.',
    whyItMatters:
        'Knowing the kind of value helps you understand what operations make sense for it.',
    walkThrough:
        'The example stores 21 in age. type(age) asks Python what kind of value is saved there, and __name__ shows the type’s short name.',
    watchOut:
        'Quotation marks make a value text. For example, 21 is a number but "21" is text.',
    topicTakeaway:
        'Values have types, and the type affects how Python can use them.',
    friendProblem:
        'Hey {name}, I saved someone’s age and want to know if Python sees it as a number or text. How can I check its type?',
  ),
  'L1-08': LessonGuide(
    plainLanguage:
        'A comparison asks Python whether two values have a relationship, such as whether one is smaller or whether both are equal. The result is True or False.',
    whyItMatters:
        'Programs use these true-or-false results to decide what should happen next.',
    walkThrough:
        'The example checks whether temperature is less than 20. Python compares the two numbers and prints True or False.',
    watchOut:
        'Use == to ask whether two values are equal. A single = assigns a value to a variable.',
    topicTakeaway:
        'Comparisons produce True or False, which a program can use to make decisions.',
    friendProblem:
        'Hey {name}, I want to check whether today’s temperature is below 20 before I choose a jacket. How could Python compare those numbers?',
  ),
  'L1-09': LessonGuide(
    plainLanguage:
        'An if statement lets a program choose. Python checks a condition and runs the indented lines only when the condition is True.',
    whyItMatters:
        'This lets a program react differently to different situations.',
    walkThrough:
        'The example saves True in rainy. The if line checks rainy, and the indented print line runs because the condition is true.',
    watchOut:
        'Put a colon at the end of the if line and indent the instructions that belong inside it.',
    topicTakeaway:
        'An if statement runs its indented instructions only when its condition is True.',
    friendProblem:
        'Hey {name}, I only want to take an umbrella when it is raining. How can an if statement help my program make that choice?',
  ),
  'L1-10': LessonGuide(
    plainLanguage:
        'Use elif to check another condition when the first one is false. Use else for the remaining case when none of the earlier conditions matched.',
    whyItMatters:
        'Several choices let a program respond to more than one outcome while keeping the rules together.',
    walkThrough:
        'Python checks the conditions from top to bottom. It runs the first matching branch and skips the rest.',
    watchOut:
        'Keep each branch aligned with if. Indent the instruction under each branch.',
    topicTakeaway:
        'if, elif, and else let Python choose between several outcomes.',
    friendProblem:
        'Hey {name}, I need to show “great work” for a high score and a different message otherwise. How could I give Python those choices?',
  ),
  'L1-11': LessonGuide(
    plainLanguage:
        'and combines two checks and is True only when both are true. or is True when at least one check is true. not flips True to False, or False to True.',
    whyItMatters:
        'Combining checks lets a program make decisions using more than one piece of information.',
    walkThrough:
        'The example checks both that age is at least 18 and that has_ticket is True. The whole result is True only if both checks pass.',
    watchOut:
        'Read each condition separately first, then consider how and or or combines the results.',
    topicTakeaway:
        'and, or, and not combine or change the results of simple comparisons.',
    friendProblem:
        'Hey {name}, entry needs both an adult age and a ticket. How can I ask Python to check both things together?',
  ),
  'L1-12': LessonGuide(
    plainLanguage:
        'A for loop repeats instructions for each item in a group. A list is one way to keep several values together, written between square brackets and separated by commas.',
    whyItMatters:
        'You can work through a group of items without writing the same instruction over and over.',
    walkThrough:
        'In the example, Python takes each day from the list, puts it in day, and prints it. When there are no more days, the loop ends.',
    watchOut:
        'The colon starts the loop body. Indent the repeated instruction so Python knows it belongs to the loop.',
    topicTakeaway:
        'A list stores several values together, and a for loop can handle each value in turn.',
    friendProblem:
        'Hey {name}, I’m in a bit of a jam 😅 I have apples, mangoes, and oranges. How do I put them all in one Python list and show them one at a time?',
  ),
  'L1-13': LessonGuide(
    plainLanguage:
        'range makes a sequence of counting numbers for a for loop. With a start and stop, it begins at start and ends just before stop.',
    whyItMatters:
        'Counting with range is useful when you want to repeat something a set number of times.',
    walkThrough:
        'range(1, 4) produces 1, 2, and 3. The loop uses each number in turn and prints it.',
    watchOut:
        'The stop number is not included. This is why range(1, 4) stops at 3.',
    topicTakeaway:
        'range(start, stop) counts from start up to, but not including, stop.',
    friendProblem:
        'Hey {name}, I need to print ticket numbers 1, 2, and 3. How can I use range so Python counts those for me?',
  ),
  'L1-14': LessonGuide(
    plainLanguage:
        'A while loop keeps repeating while its condition is True. It checks the condition again after each repetition.',
    whyItMatters:
        'It is handy when something should continue until a condition changes.',
    walkThrough:
        'The example starts tries at 0. Each turn prints a message and adds 1. When tries is no longer less than 3, the loop ends.',
    watchOut:
        'Make sure something inside the loop changes the condition. Otherwise, it may repeat forever.',
    topicTakeaway:
        'A while loop repeats as long as its condition stays True, so make sure it can eventually stop.',
    friendProblem:
        'Hey {name}, I want to remind someone to try again three times. How can a while loop count each attempt and then stop?',
  ),
  'L1-15': LessonGuide(
    plainLanguage:
        'break stops a loop early. continue skips the rest of the current turn and moves to the next item.',
    whyItMatters:
        'These tools help a loop stop or skip work when a particular situation occurs.',
    walkThrough:
        'The example checks each number. When number is 4, break ends the loop, so Python does not print 4 or later numbers.',
    watchOut:
        'Use break only when you want the whole loop to stop. continue does not end the loop.',
    topicTakeaway:
        'break ends a loop early; continue skips the rest of one turn.',
    friendProblem:
        'Hey {name}, I’m checking numbers one by one but want to stop as soon as I reach 4. Which loop instruction could help?',
  ),
  'L1-16': LessonGuide(
    plainLanguage:
        'A small project combines ideas you already know. A guessing game can compare a guess with a secret number and repeat until the player gets it right.',
    whyItMatters:
        'Projects help you see how separate Python ideas work together to solve one problem.',
    walkThrough:
        'The example compares guess with secret. If guess is smaller, the if block prints a hint. You can plan the other outcomes with the same ideas from earlier lessons.',
    watchOut:
        'Build one small part at a time: set up the values, compare them, then decide what to do next.',
    topicTakeaway:
        'A small program becomes easier to build when you combine familiar ideas one step at a time.',
    friendProblem:
        'Hey {name}, I’m making a number guessing game. How can I compare a guess with the secret number and give a helpful hint?',
  ),
};

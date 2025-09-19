class Question {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String explanation;
  final String tag; // Maps to exam_name in database
  final int correctAnswer; // 0 for A, 1 for B, 2 for C, 3 for D

  Question({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.explanation,
    required this.tag,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    print('Parsing question JSON: $json');

    // Handle correct_answer - find the index of the correct answer text
    int correctAnswer = 0; // Default to option A

    if (json['correct_answer'] != null) {
      final correctAnswerText = json['correct_answer'].toString();

      // Check which option matches the correct answer text
      if (json['option_1'] == correctAnswerText) {
        correctAnswer = 0; // Option A
      } else if (json['option_2'] == correctAnswerText) {
        correctAnswer = 1; // Option B
      } else if (json['option_3'] == correctAnswerText) {
        correctAnswer = 2; // Option C
      } else if (json['option_4'] == correctAnswerText) {
        correctAnswer = 3; // Option D
      } else {
        print(
            'Warning: Could not find correct answer "$correctAnswerText" in options');
        correctAnswer = 0; // Default to option A
      }
    }

    final question = Question(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      optionA: json['option_1'] ?? '', // Changed from option_A to option_1
      optionB: json['option_2'] ?? '', // Changed from option_B to option_2
      optionC: json['option_3'] ?? '', // Changed from option_C to option_3
      optionD: json['option_4'] ?? '', // Changed from option_D to option_4
      explanation: json['explanation'] ?? '',
      tag: json['exam_name'] ?? '', // Changed from tag to exam_name
      correctAnswer: correctAnswer,
    );

    print(
        'Parsed question: ${question.question} with exam_name: ${question.tag}, correct answer index: $correctAnswer (${question.options[correctAnswer]})');
    return question;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'option_1': optionA, // Changed from option_A to option_1
      'option_2': optionB, // Changed from option_B to option_2
      'option_3': optionC, // Changed from option_C to option_3
      'option_4': optionD, // Changed from option_D to option_4
      'explanation': explanation,
      'exam_name': tag, // Changed from tag to exam_name
      'correct_answer': correctAnswer,
    };
  }

  List<String> get options => [optionA, optionB, optionC, optionD];

  String get correctOption {
    switch (correctAnswer) {
      case 0:
        return optionA;
      case 1:
        return optionB;
      case 2:
        return optionC;
      case 3:
        return optionD;
      default:
        return optionA;
    }
  }
}

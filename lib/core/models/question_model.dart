class Question {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String explanation;
  final String tag;
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
      if (json['option_A'] == correctAnswerText) {
        correctAnswer = 0; // Option A
      } else if (json['option_B'] == correctAnswerText) {
        correctAnswer = 1; // Option B
      } else if (json['option_C'] == correctAnswerText) {
        correctAnswer = 2; // Option C
      } else if (json['option_D'] == correctAnswerText) {
        correctAnswer = 3; // Option D
      } else {
        print('Warning: Could not find correct answer "$correctAnswerText" in options');
        correctAnswer = 0; // Default to option A
      }
    }
    
    final question = Question(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      optionA: json['option_A'] ?? '', // Changed from option_a to option_A
      optionB: json['option_B'] ?? '', // Changed from option_b to option_B
      optionC: json['option_C'] ?? '', // Changed from option_c to option_C
      optionD: json['option_D'] ?? '', // Changed from option_d to option_D
      explanation: json['explanation'] ?? '',
      tag: json['tag'] ?? '',
      correctAnswer: correctAnswer,
    );
    
    print('Parsed question: ${question.question} with tag: ${question.tag}, correct answer index: $correctAnswer (${question.options[correctAnswer]})');
    return question;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'option_A': optionA, // Changed from option_a to option_A
      'option_B': optionB, // Changed from option_b to option_B
      'option_C': optionC, // Changed from option_c to option_C
      'option_D': optionD, // Changed from option_d to option_D
      'explanation': explanation,
      'tag': tag,
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

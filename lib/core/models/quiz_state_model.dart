import 'question_model.dart';

class QuestionState {
  final int? selectedOptionIndex;
  final bool hasSubmittedAnswer;
  final bool showExplanation;

  const QuestionState({
    this.selectedOptionIndex,
    this.hasSubmittedAnswer = false,
    this.showExplanation = false,
  });

  QuestionState copyWith({
    int? selectedOptionIndex,
    bool? hasSubmittedAnswer,
    bool? showExplanation,
  }) {
    return QuestionState(
      selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
      hasSubmittedAnswer: hasSubmittedAnswer ?? this.hasSubmittedAnswer,
      showExplanation: showExplanation ?? this.showExplanation,
    );
  }

  bool get hasSelection => selectedOptionIndex != null;
  bool get isCompleted => hasSubmittedAnswer;
}

class QuizStateManager {
  final Map<int, QuestionState> _questionStates = {};

  QuestionState getQuestionState(int questionIndex) {
    return _questionStates[questionIndex] ?? const QuestionState();
  }

  void updateQuestionState(int questionIndex, QuestionState state) {
    _questionStates[questionIndex] = state;
  }

  void setSelectedOption(int questionIndex, int optionIndex) {
    final currentState = getQuestionState(questionIndex);
    updateQuestionState(
      questionIndex,
      currentState.copyWith(selectedOptionIndex: optionIndex),
    );
  }

  void selectAndSubmitOption(int questionIndex, int optionIndex) {
    updateQuestionState(
      questionIndex,
      QuestionState(
        selectedOptionIndex: optionIndex,
        hasSubmittedAnswer: true,
        showExplanation: true,
      ),
    );
  }

  bool canNavigateToPrevious(int currentIndex) {
    return currentIndex > 0;
  }

  bool canNavigateToNext(int currentIndex, int totalQuestions) {
    return currentIndex < totalQuestions - 1;
  }

  List<int> getAnsweredQuestions() {
    return _questionStates.entries
        .where((entry) => entry.value.hasSubmittedAnswer)
        .map((entry) => entry.key)
        .toList()
      ..sort();
  }

  void reset() {
    _questionStates.clear();
  }

  // Get total answered questions count
  int getTotalAnsweredCount() {
    return _questionStates.values
        .where((state) => state.hasSubmittedAnswer)
        .length;
  }

  // Get progress percentage
  double getProgressPercentage(int totalQuestions) {
    if (totalQuestions == 0) return 0.0;
    return getTotalAnsweredCount() / totalQuestions;
  }

  // Check if specific question is answered
  bool isQuestionAnswered(int questionIndex) {
    return getQuestionState(questionIndex).hasSubmittedAnswer;
  }

  // Check if specific question was answered correctly
  bool isQuestionCorrect(int questionIndex, List<Question> questions) {
    if (questionIndex >= questions.length) return false;
    final state = getQuestionState(questionIndex);
    if (!state.hasSubmittedAnswer || state.selectedOptionIndex == null) {
      return false;
    }
    return state.selectedOptionIndex == questions[questionIndex].correctAnswer;
  }

  // Quiz result calculation methods
  Map<String, int> getQuizSummary(List<Question> questions) {
    int correctAnswers = 0;
    int totalAnswered = 0;
    int totalQuestions = questions.length;

    for (int i = 0; i < totalQuestions; i++) {
      final state = getQuestionState(i);
      if (state.hasSubmittedAnswer && state.selectedOptionIndex != null) {
        totalAnswered++;
        if (state.selectedOptionIndex == questions[i].correctAnswer) {
          correctAnswers++;
        }
      }
    }

    return {
      'total': totalQuestions,
      'attempted': totalAnswered,
      'correct': correctAnswers,
      'wrong': totalAnswered - correctAnswers,
      'unattempted': totalQuestions - totalAnswered,
    };
  }
}

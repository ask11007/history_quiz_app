class QuestionReport {
  final int? id;
  final int questionId;
  final String reportType;
  final String? description;
  final String? userEmail;
  final DateTime? reportedAt;

  const QuestionReport({
    this.id,
    required this.questionId,
    required this.reportType,
    this.description,
    this.userEmail,
    this.reportedAt,
  });

  factory QuestionReport.fromJson(Map<String, dynamic> json) {
    return QuestionReport(
      id: json['id'],
      questionId: json['question_id'],
      reportType: json['report_type'],
      description: json['description'],
      userEmail: json['user_email'],
      reportedAt: json['reported_at'] != null
          ? DateTime.parse(json['reported_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'question_id': questionId,
      'report_type': reportType,
      if (description != null) 'description': description,
      if (userEmail != null) 'user_email': userEmail,
      if (reportedAt != null) 'reported_at': reportedAt!.toIso8601String(),
    };
  }

  QuestionReport copyWith({
    int? id,
    int? questionId,
    String? reportType,
    String? description,
    String? userEmail,
    DateTime? reportedAt,
  }) {
    return QuestionReport(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      reportType: reportType ?? this.reportType,
      description: description ?? this.description,
      userEmail: userEmail ?? this.userEmail,
      reportedAt: reportedAt ?? this.reportedAt,
    );
  }
}

// Available report types
class ReportTypes {
  static const String incorrectAnswer = 'Incorrect Answer';
  static const String wrongOptions = 'Wrong Options';
  static const String unclearQuestion = 'Unclear Question';
  static const String typographicalError = 'Typographical Error';
  static const String other = 'Other';

  static List<String> get all => [
        incorrectAnswer,
        wrongOptions,
        unclearQuestion,
        typographicalError,
        other,
      ];
}

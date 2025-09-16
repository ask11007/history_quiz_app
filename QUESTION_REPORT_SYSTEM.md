# Question Report System Documentation

## Overview
A comprehensive question reporting system that allows users to report issues with quiz questions directly to a Supabase database. The system includes a user-friendly interface for categorizing and describing issues.

## Database Table Structure
```sql
CREATE TABLE question_reports (
  id SERIAL PRIMARY KEY,
  question_id INTEGER NOT NULL REFERENCES questions(id),
  report_type TEXT NOT NULL,
  description TEXT,
  user_email TEXT,
  reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Features
- **Multiple Report Types**: Users can select from predefined categories
- **Detailed Descriptions**: Optional text field for additional context (500 character limit)
- **User Tracking**: Reports include user email for follow-up if needed
- **Real-time Feedback**: Character counter and validation
- **Professional UI**: Consistent with app's design system

## Report Types Available
1. **Incorrect Answer** - The marked correct answer is wrong
2. **Wrong Options** - One or more answer options are incorrect
3. **Poor Explanation** - The explanation is unclear or inadequate
4. **Unclear Question** - The question is confusing or ambiguous
5. **Typographical Error** - Spelling or grammar mistakes
6. **Other** - Issues not covered by other categories

## How It Works

### User Flow
1. User clicks the circular report button (⚠️) in the quiz header
2. Question Report Dialog opens showing:
   - Current question preview
   - Report type selection (radio buttons)
   - Optional description field
   - Submit/Cancel buttons
3. User selects issue type and optionally adds description
4. Report is submitted to Supabase database
5. Success message confirms submission

### Backend Process
1. Report data is validated on client side
2. QuestionReport model is created with:
   - Question ID
   - Report type
   - Description (if provided)
   - User email
   - Timestamp
3. Data is inserted into `question_reports` table via SupabaseService
4. Success/error feedback provided to user

## Files Structure
```
lib/
├── core/
│   ├── models/
│   │   └── question_report_model.dart     # Data model and types
│   └── services/
│       └── supabase_service.dart          # Database operations (enhanced)
└── presentation/
    └── quiz_screen/
        ├── quiz_screen.dart               # Integration point
        └── widgets/
            └── question_report_widget.dart # UI component
```

## Key Components

### QuestionReport Model
- Immutable data model with JSON serialization
- Includes validation and type safety
- Supports copyWith for easy modifications

### ReportTypes Class
- Static list of available report categories
- Ensures consistency across the app
- Easy to extend with new types

### QuestionReportWidget
- Full-screen dialog with professional design
- Real-time character counting and validation
- Proper error handling and user feedback
- Integrates with UserProvider for user identification

### SupabaseService Extensions
- `submitQuestionReport()` - Submit new reports
- `getQuestionReports()` - Get reports for specific question
- `getAllReports()` - Admin function to get all reports
- `deleteReport()` - Admin function to delete reports

## Usage Example

### Triggering the Report Dialog
```dart
onReportPressed: () {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return QuestionReportWidget(
        question: currentQuestion,
        onReportSubmitted: () {
          // Optional callback after successful submission
          print('Question ${currentQuestion.id} reported successfully');
        },
      );
    },
  );
}
```

### Database Query Examples
```dart
// Submit a report
final report = QuestionReport(
  questionId: 123,
  reportType: ReportTypes.incorrectAnswer,
  description: 'Option B should be the correct answer',
  userEmail: 'user@example.com',
);
await SupabaseService.submitQuestionReport(report);

// Get all reports for a question
final reports = await SupabaseService.getQuestionReports(123);
```

## Admin Usage
Reports can be viewed and managed through Supabase dashboard:
1. Go to Supabase Dashboard → Table Editor
2. Select `question_reports` table
3. View all submitted reports with details
4. Filter by question_id, report_type, or date
5. Contact users via email if needed
6. Delete resolved reports

## Error Handling
- Client-side validation for required fields
- Network error handling with user feedback
- Graceful fallback for offline scenarios
- Proper error messages for debugging

## Future Enhancements
- Admin panel for report management
- Email notifications for new reports
- Report status tracking (pending/resolved)
- Bulk report management
- Report analytics and trends
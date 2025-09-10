# Supabase Integration Setup Guide

## Overview
This app now integrates with Supabase to fetch quiz questions dynamically from your database instead of using static/hardcoded questions.

## Database Schema
Your Supabase database should have a table named `questions` with the following columns:

```sql
CREATE TABLE questions (
  id SERIAL PRIMARY KEY,
  question TEXT NOT NULL,
  option_A TEXT NOT NULL,
  option_B TEXT NOT NULL,
  option_C TEXT NOT NULL,
  option_D TEXT NOT NULL,
  explanation TEXT NOT NULL,
  tag TEXT NOT NULL,
  correct_answer TEXT NOT NULL
);
```

**Column Details:**
- `question`: The quiz question text
- `option_A`, `option_B`, `option_C`, `option_D`: The four answer options
- `explanation`: Explanation of the correct answer
- `tag`: Subject category (e.g., "GK", "Math", "Reasoning")
- `correct_answer`: Correct answer as text (will be converted to 0-3 index)

## Setup Steps

### 1. Get Your Supabase Credentials
1. Go to [Supabase](https://supabase.com) and sign in
2. Select your project (or create a new one)
3. Go to Settings → API
4. Copy your Project URL and anon/public key

### 2. Update Configuration
1. Open `lib/core/config/supabase_config.dart`
2. Replace the placeholder values:
   ```dart
   static const String url = 'https://your-project.supabase.co';
   static const String anonKey = 'your-actual-anon-key';
   ```

### 3. Add Sample Questions
Insert some sample questions into your database:

```sql
INSERT INTO questions (question, option_A, option_B, option_C, option_D, explanation, tag, correct_answer) VALUES
('What is the value of π (pi) rounded to two decimal places?', '3.12', '3.14', '3.16', '3.18', 'π (pi) is approximately 3.14159, which rounds to 3.14 when rounded to two decimal places.', 'Math', '1'),
('If 2x + 5 = 15, what is the value of x?', '5', '10', '7', '3', 'To solve 2x + 5 = 15, subtract 5 from both sides: 2x = 10. Then divide both sides by 2: x = 5.', 'Math', '0'),
('What is the capital of France?', 'London', 'Berlin', 'Paris', 'Madrid', 'Paris is the capital and largest city of France.', 'GK', '2'),
('Which planet is known as the Red Planet?', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'Mars is called the Red Planet due to its reddish appearance.', 'GK', '1');
```

## How It Works

### 1. Question Loading
- When a user selects a subject, the app fetches questions from Supabase using the `tag` column
- Questions are automatically categorized by subject based on their tags
- If no internet connection is available, the app shows a "No Internet Connection" message

### 2. Subject Categories
The app automatically creates subject categories based on the unique values in the `tag` column. Make sure your tags match the subject names in your app:
- "GK" → "General Knowledge"
- "Math" → "Mathematics" 
- "Reasoning" → "Reasoning"

### 3. Connectivity Handling
The app now properly handles offline scenarios:
- Shows "No Internet Connection" message when offline
- Provides retry functionality when connection is restored
- No hardcoded fallback data is displayed to users

## Testing

1. Run the app
2. Navigate to a subject (e.g., Mathematics)
3. The app should fetch questions from your Supabase database
4. Check the console for "Supabase initialized successfully" message

## Troubleshooting

### Common Issues:
1. **"Failed to initialize Supabase"**: Check your URL and anon key
2. **No questions loading**: Verify your database has questions with matching tags
3. **Network errors**: Check your internet connection and Supabase project status

### Debug Steps:
1. Check console logs for error messages
2. Verify Supabase credentials in `supabase_config.dart`
3. Test your database connection in Supabase dashboard
4. Ensure your questions table has the correct schema

### Database Permissions:
1. **Enable Row Level Security (RLS)**: Go to Authentication → Policies in Supabase
2. **Create Policy**: Add a policy to allow anonymous users to read from the questions table:
   ```sql
   CREATE POLICY "Allow anonymous read access" ON questions
   FOR SELECT USING (true);
   ```
3. **Check Table Permissions**: Ensure the `questions` table allows SELECT operations for anonymous users

## Security Notes
- The anon key is safe to use in client apps
- Row Level Security (RLS) is recommended for production
- Consider implementing user authentication for personalized features

## Next Steps
- Add user authentication
- Implement question difficulty levels
- Add question categories and subcategories
- Create admin panel for managing questions

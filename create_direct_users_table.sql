-- Create a simple users table for direct storage (no Supabase Auth dependency)
-- This approach stores Google user data directly without requiring OAuth setup

-- Drop existing table if it exists
DROP TABLE IF EXISTS public.user_profiles;

-- Create the user_profiles table for direct storage
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS user_profiles_email_idx ON public.user_profiles (email);
CREATE INDEX IF NOT EXISTS user_profiles_created_at_idx ON public.user_profiles (created_at);
CREATE INDEX IF NOT EXISTS user_profiles_name_idx ON public.user_profiles (name);

-- Enable Row Level Security (optional - can be disabled for simpler setup)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create a simple policy that allows anonymous access for reading and writing
-- This is required if RLS is enabled
CREATE POLICY "Allow anonymous access" ON public.user_profiles
    FOR ALL USING (true);

-- Alternatively, if you want to disable RLS completely for easier setup:
-- ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- Grant necessary permissions for anonymous access
GRANT ALL ON public.user_profiles TO anon;
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO service_role;

-- Insert some test data (optional)
INSERT INTO public.user_profiles (name, email) VALUES 
('Test User 1', 'test1@example.com'),
('Test User 2', 'test2@example.com')
ON CONFLICT (email) DO NOTHING;

-- Display success message
SELECT 'Direct user storage table created successfully!' as status;

-- Show table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;
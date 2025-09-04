-- Create user_profiles table with proper structure and relationships
-- This script recreates the user_profiles table to ensure it works with authentication

-- First, drop the existing table if it exists
DROP TABLE IF EXISTS public.user_profiles;

-- Create the user_profiles table
CREATE TABLE public.user_profiles (
    id UUID NOT NULL,
    name TEXT NOT NULL,
    avatar_url TEXT,
    total_quiz_time INTERVAL,
    achievement_badges INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Set primary key
    CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
    
    -- Foreign key to auth.users
    CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) 
        REFERENCES auth.users (id) 
        ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS user_profiles_name_idx ON public.user_profiles (name);
CREATE INDEX IF NOT EXISTS user_profiles_created_at_idx ON public.user_profiles (created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies

-- Policy: Users can view their own profile
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Policy: Users can delete their own profile
CREATE POLICY "Users can delete their own profile" ON public.user_profiles
    FOR DELETE USING (auth.uid() = id);

-- Create trigger for updating updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to user_profiles table
CREATE TRIGGER handle_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Grant necessary permissions
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO service_role;

-- Insert a sample user profile for testing (optional - remove in production)
-- INSERT INTO public.user_profiles (id, name, avatar_url, achievement_badges)
-- VALUES (
--     '00000000-0000-0000-0000-000000000000',  -- Replace with actual user ID
--     'Test User',
--     'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
--     0
-- );

-- Display success message
SELECT 'User profiles table created successfully with RLS policies!' as status;
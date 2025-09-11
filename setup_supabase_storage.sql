-- Supabase Storage Setup for Profile Pictures
-- Run this in your Supabase SQL Editor

-- Create storage bucket for avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- Set up RLS policies for the avatars bucket
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "Users can update their own avatar" ON storage.objects
FOR UPDATE USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "Users can delete their own avatar" ON storage.objects
FOR DELETE USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;
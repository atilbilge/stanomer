-- Add inviter_name column to the invitations table
-- This allows storing the inviter's name directly with the invite
-- Run this in the Supabase SQL Editor

ALTER TABLE invitations ADD COLUMN IF NOT EXISTS inviter_name TEXT;

-- Optional: Update existing invites from profiles table (if possible)
-- UPDATE invitations i SET inviter_name = p.full_name FROM profiles p WHERE i.inviter_id = p.id;

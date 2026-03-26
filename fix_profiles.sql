-- This script safely copies usernames from the auth.users metadata 
-- into the public.profiles table so all old threads display correctly.

INSERT INTO public.profiles (user_id, username)
SELECT 
    id AS user_id, 
    COALESCE(
        raw_user_meta_data->>'username', 
        SPLIT_PART(email, '@', 1), 
        'Guest'
    ) AS username
FROM auth.users
ON CONFLICT (user_id) DO UPDATE 
SET username = EXCLUDED.username;

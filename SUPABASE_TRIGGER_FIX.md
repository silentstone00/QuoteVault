# Fix Supabase Profile Creation Trigger

## Problem
The app shows "Database error saving new user" because the profile isn't being created automatically when a user signs up.

## Root Cause
The database trigger that should automatically create a profile when a user signs up is either:
1. Not installed in your Supabase database
2. Not working correctly
3. Missing permissions

---

## Solution: Verify and Fix in Supabase Dashboard

### Step 1: Check if Trigger Exists

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard
2. **Select your project**: `kghefskpruzugcggthua`
3. **Go to SQL Editor** (left sidebar)
4. **Run this query** to check if the trigger exists:

```sql
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

**Expected Result:** Should show 1 row with the trigger details
**If empty:** The trigger is not installed - proceed to Step 2

---

### Step 2: Install the Trigger (If Missing)

Copy and paste this **ENTIRE SQL** into the SQL Editor and click "Run":

```sql
-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, preferences)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        '{
            "color_scheme": null,
            "accent_color": "blue",
            "font_size": "medium",
            "notification_enabled": false,
            "notification_time": null
        }'::jsonb
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists (to avoid errors)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to run on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();
```

**Click "Run"** - You should see "Success. No rows returned"

---

### Step 3: Verify Profiles Table Exists

Run this query to check if the profiles table exists:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public';
```

**Expected Result:** Should show columns: id, display_name, avatar_url, preferences, created_at, updated_at

**If empty:** The profiles table doesn't exist - run the schema migration from `supabase/migrations/001_create_schema.sql`

---

### Step 4: Check Row Level Security (RLS)

The profiles table needs proper RLS policies. Run this:

```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles' 
AND schemaname = 'public';
```

**Expected:** `rowsecurity` should be `true`

**If false, enable RLS:**

```sql
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
```

---

### Step 5: Add RLS Policies (If Missing)

Run this to add the necessary policies:

```sql
-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.profiles;

-- Allow users to view their own profile
CREATE POLICY "Users can view own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- Allow authenticated users to insert their profile
CREATE POLICY "Enable insert for authenticated users only"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);
```

---

### Step 6: Test the Trigger Manually

Let's test if the trigger works by creating a test user:

1. **Go to Authentication** → **Users** in Supabase Dashboard
2. **Click "Add user"** → **Create new user**
3. Enter a test email (e.g., `test@example.com`) and password
4. Click "Create user"

5. **Check if profile was created:**

```sql
SELECT * FROM public.profiles 
WHERE display_name LIKE 'test%' 
ORDER BY created_at DESC 
LIMIT 1;
```

**Expected:** Should show the profile for the test user

**If no profile:** The trigger is not working - check the function permissions

---

### Step 7: Fix Function Permissions (If Trigger Still Not Working)

The function needs proper permissions to insert into the profiles table:

```sql
-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION handle_new_user() TO service_role;

-- Ensure the function runs with proper security
ALTER FUNCTION handle_new_user() SECURITY DEFINER;
```

---

### Step 8: Alternative - Disable Email Confirmation (Optional)

If you have email confirmation enabled, the trigger might not fire until the user confirms their email.

1. **Go to Authentication** → **Settings** → **Auth Providers**
2. **Scroll to "Email"**
3. **Uncheck "Enable email confirmations"** (for testing)
4. **Click "Save"**

---

## Quick Fix: Manual Profile Creation

If the trigger still doesn't work, the app will now create profiles manually. But let's verify the app can insert:

1. **Go to SQL Editor**
2. **Run this to check insert permissions:**

```sql
-- Check if authenticated users can insert
SELECT * FROM information_schema.role_table_grants 
WHERE table_name = 'profiles' 
AND privilege_type = 'INSERT';
```

---

## After Fixing Supabase

1. **Delete any test users** you created
2. **Try signing up in the app again**
3. **Check Xcode console** for any error messages
4. **If still failing**, check the Supabase logs:
   - Go to **Logs** → **Postgres Logs** in Supabase Dashboard
   - Look for errors related to `profiles` table or `handle_new_user` function

---

## Common Issues

### Issue 1: "permission denied for table profiles"
**Fix:** Run the RLS policies from Step 5

### Issue 2: "function handle_new_user() does not exist"
**Fix:** Run the function creation from Step 2

### Issue 3: "duplicate key value violates unique constraint"
**Fix:** A profile already exists for that user. Delete it:
```sql
DELETE FROM public.profiles WHERE id = 'USER_ID_HERE';
```

### Issue 4: Trigger exists but doesn't fire
**Fix:** 
1. Check if email confirmation is required
2. Verify the function has SECURITY DEFINER
3. Check Postgres logs for errors

---

## Verification Checklist

After completing the steps above, verify:

- [ ] Trigger `on_auth_user_created` exists
- [ ] Function `handle_new_user()` exists
- [ ] Profiles table exists with correct columns
- [ ] RLS is enabled on profiles table
- [ ] RLS policies exist for SELECT, UPDATE, INSERT
- [ ] Test user creation creates a profile
- [ ] App signup works without errors

---

## Still Not Working?

If you've done all the above and it still doesn't work:

1. **Check Xcode Console** - Look for the actual error message
2. **Check Supabase Logs** - Go to Logs → Postgres Logs
3. **Share the error** - Let me know the exact error message from Xcode console

The app now has fallback logic to create profiles manually, so even if the trigger doesn't work, signup should succeed!

# QuoteVault Supabase Database Setup

## Overview

This directory contains SQL migration files for setting up the QuoteVault database schema in Supabase.

## Database Schema

The database consists of the following tables:

1. **profiles** - User profile information (extends auth.users)
2. **quotes** - All quotes in the system
3. **user_favorites** - User's favorited quotes
4. **collections** - User-created quote collections
5. **collection_quotes** - Many-to-many relationship between collections and quotes
6. **quote_of_day** - Tracks the quote of the day for each date

## Migrations

### 001_create_schema.sql
- Creates all core tables
- Sets up foreign key relationships
- Creates indexes for performance
- Adds triggers for automatic profile creation
- Adds updated_at trigger for profiles

### 002_row_level_security.sql
- Enables Row Level Security (RLS) on all tables
- Configures policies for data access control
- Ensures users can only access their own data
- Allows public read access to quotes

### 003_quote_of_day_functions.sql
- `get_quote_of_day(date)` - Deterministic QOTD selection
- `get_collections_with_count(user_id)` - Collections with quote counts
- `search_quotes(query, category, page, size)` - Full-text search

## Setup Instructions

### Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Run each migration file in order:
   - Copy the contents of `001_create_schema.sql`
   - Paste into SQL Editor and run
   - Repeat for `002_row_level_security.sql`
   - Repeat for `003_quote_of_day_functions.sql`

### Option 2: Using Supabase CLI

If you have the Supabase CLI installed:

```bash
# Initialize Supabase in your project (if not already done)
supabase init

# Link to your remote project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

### Option 3: Manual SQL Execution

Connect to your Supabase database using psql or any PostgreSQL client and execute the migration files in order.

## Verification

After running the migrations, verify the setup:

```sql
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Test QOTD function
SELECT * FROM get_quote_of_day(CURRENT_DATE);
```

## Row Level Security Policies

### Profiles
- Users can view and update their own profile only

### Quotes
- Public read access (authenticated and anonymous)
- Only service role can insert (for seeding)

### User Favorites
- Users can view, insert, and delete their own favorites only

### Collections
- Users have full CRUD access to their own collections only

### Collection Quotes
- Users can manage quotes in their own collections only

### Quote of the Day
- Public read access
- Only service role can manage

## Functions

### get_quote_of_day(target_date)
Returns the quote of the day for a specific date. Uses deterministic selection based on date hash to ensure consistency across devices.

**Usage:**
```sql
SELECT * FROM get_quote_of_day(CURRENT_DATE);
SELECT * FROM get_quote_of_day('2026-01-15');
```

### get_collections_with_count(user_uuid)
Returns all collections for a user with quote counts.

**Usage:**
```sql
SELECT * FROM get_collections_with_count(auth.uid());
```

### search_quotes(search_query, search_category, page_num, page_size)
Searches quotes by text or author with optional category filter and pagination.

**Usage:**
```sql
-- Search all quotes
SELECT * FROM search_quotes('motivation', NULL, 0, 20);

-- Search in specific category
SELECT * FROM search_quotes('success', 'motivation', 0, 20);

-- Search by author
SELECT * FROM search_quotes('Einstein', NULL, 0, 20);
```

## Next Steps

After setting up the schema:
1. Run the seed script to populate quotes (see `004_seed_quotes.sql`)
2. Test the API endpoints from your Swift app
3. Verify RLS policies are working correctly

-- QuoteVault Row Level Security Policies
-- Migration 002: Configure RLS for all tables

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_of_day ENABLE ROW LEVEL SECURITY;

-- Profiles policies
-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Quotes policies
-- Anyone (authenticated or not) can read quotes
CREATE POLICY "Anyone can read quotes"
    ON quotes FOR SELECT
    TO authenticated, anon
    USING (true);

-- Only admins can insert quotes (for seeding)
-- Note: In production, you'd create an admin role
CREATE POLICY "Service role can insert quotes"
    ON quotes FOR INSERT
    WITH CHECK (auth.jwt()->>'role' = 'service_role');

-- User favorites policies
-- Users can view their own favorites
CREATE POLICY "Users can view own favorites"
    ON user_favorites FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own favorites
CREATE POLICY "Users can insert own favorites"
    ON user_favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own favorites
CREATE POLICY "Users can delete own favorites"
    ON user_favorites FOR DELETE
    USING (auth.uid() = user_id);

-- Collections policies
-- Users can view their own collections
CREATE POLICY "Users can view own collections"
    ON collections FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own collections
CREATE POLICY "Users can insert own collections"
    ON collections FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own collections
CREATE POLICY "Users can update own collections"
    ON collections FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own collections
CREATE POLICY "Users can delete own collections"
    ON collections FOR DELETE
    USING (auth.uid() = user_id);

-- Collection quotes policies
-- Users can view quotes in their own collections
CREATE POLICY "Users can view own collection quotes"
    ON collection_quotes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes.collection_id
            AND collections.user_id = auth.uid()
        )
    );

-- Users can add quotes to their own collections
CREATE POLICY "Users can insert into own collections"
    ON collection_quotes FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes.collection_id
            AND collections.user_id = auth.uid()
        )
    );

-- Users can remove quotes from their own collections
CREATE POLICY "Users can delete from own collections"
    ON collection_quotes FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes.collection_id
            AND collections.user_id = auth.uid()
        )
    );

-- Quote of the day policies
-- Anyone can read quote of the day
CREATE POLICY "Anyone can read quote of the day"
    ON quote_of_day FOR SELECT
    TO authenticated, anon
    USING (true);

-- Only service role can manage quote of the day
CREATE POLICY "Service role can manage quote of the day"
    ON quote_of_day FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

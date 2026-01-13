-- QuoteVault Database Schema
-- Migration 001: Create core tables and relationships

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    display_name TEXT,
    avatar_url TEXT,
    preferences JSONB DEFAULT '{
        "color_scheme": null,
        "accent_color": "blue",
        "font_size": "medium",
        "notification_enabled": false,
        "notification_time": null
    }'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Quotes table
CREATE TABLE quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text TEXT NOT NULL CHECK (length(trim(text)) > 0),
    author TEXT NOT NULL CHECK (length(trim(author)) > 0),
    category TEXT NOT NULL CHECK (category IN ('motivation', 'love', 'success', 'wisdom', 'humor')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User favorites
CREATE TABLE user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, quote_id)
);

-- Collections
CREATE TABLE collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Collection quotes (many-to-many)
CREATE TABLE collection_quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID REFERENCES collections(id) ON DELETE CASCADE NOT NULL,
    quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE NOT NULL,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(collection_id, quote_id)
);

-- Quote of the day (server-managed)
CREATE TABLE quote_of_day (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE NOT NULL,
    date DATE UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_quotes_category ON quotes(category);
CREATE INDEX idx_quotes_author ON quotes(author);
CREATE INDEX idx_quotes_text ON quotes USING gin(to_tsvector('english', text));
CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_quote ON user_favorites(quote_id);
CREATE INDEX idx_collections_user ON collections(user_id);
CREATE INDEX idx_collection_quotes_collection ON collection_quotes(collection_id);
CREATE INDEX idx_collection_quotes_quote ON collection_quotes(quote_id);
CREATE INDEX idx_quote_of_day_date ON quote_of_day(date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to profiles table
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, display_name, preferences)
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

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

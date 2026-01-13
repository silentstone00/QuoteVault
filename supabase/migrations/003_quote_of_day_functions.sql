-- QuoteVault Quote of the Day Functions
-- Migration 003: Functions for deterministic QOTD selection

-- Function to get or create Quote of the Day for a specific date
CREATE OR REPLACE FUNCTION get_quote_of_day(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    id UUID,
    text TEXT,
    author TEXT,
    category TEXT,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    qotd_id UUID;
    quote_record RECORD;
BEGIN
    -- Check if QOTD already exists for this date
    SELECT quote_id INTO qotd_id
    FROM quote_of_day
    WHERE date = target_date;
    
    -- If not found, select a deterministic quote based on date
    IF qotd_id IS NULL THEN
        -- Use date as seed for deterministic selection
        -- This ensures the same quote is selected for the same date
        SELECT q.id INTO qotd_id
        FROM quotes q
        ORDER BY md5(q.id::text || target_date::text)
        LIMIT 1;
        
        -- Store the selection
        IF qotd_id IS NOT NULL THEN
            INSERT INTO quote_of_day (quote_id, date)
            VALUES (qotd_id, target_date)
            ON CONFLICT (date) DO NOTHING;
        END IF;
    END IF;
    
    -- Return the quote details
    RETURN QUERY
    SELECT q.id, q.text, q.author, q.category, q.created_at
    FROM quotes q
    WHERE q.id = qotd_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get collection with quote count
CREATE OR REPLACE FUNCTION get_collections_with_count(user_uuid UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    user_id UUID,
    created_at TIMESTAMPTZ,
    quote_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.user_id,
        c.created_at,
        COUNT(cq.quote_id) as quote_count
    FROM collections c
    LEFT JOIN collection_quotes cq ON c.id = cq.collection_id
    WHERE c.user_id = user_uuid
    GROUP BY c.id, c.name, c.user_id, c.created_at
    ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search quotes by text or author
CREATE OR REPLACE FUNCTION search_quotes(
    search_query TEXT,
    search_category TEXT DEFAULT NULL,
    page_num INT DEFAULT 0,
    page_size INT DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    text TEXT,
    author TEXT,
    category TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT q.id, q.text, q.author, q.category, q.created_at
    FROM quotes q
    WHERE 
        (search_category IS NULL OR q.category = search_category)
        AND (
            search_query IS NULL 
            OR search_query = ''
            OR q.text ILIKE '%' || search_query || '%'
            OR q.author ILIKE '%' || search_query || '%'
        )
    ORDER BY q.created_at DESC
    LIMIT page_size
    OFFSET page_num * page_size;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_quote_of_day(DATE) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_collections_with_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION search_quotes(TEXT, TEXT, INT, INT) TO authenticated, anon;

-- Additional performance configurations
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_duration = on;
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries taking more than 1 second

-- Create a function for full-text search (useful for document content searching)
CREATE OR REPLACE FUNCTION create_search_indexes()
RETURNS void AS $$
BEGIN
    -- This will be called after tables are created
    -- Add indexes for commonly searched fields
    PERFORM 1;
END;
$$ LANGUAGE plpgsql;

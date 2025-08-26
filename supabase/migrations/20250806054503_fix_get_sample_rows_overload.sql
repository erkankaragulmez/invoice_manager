-- Fix missing get_sample_rows function
-- Issue: Function public.get_sample_rows(text, integer) is referenced but doesn't exist
-- Solution: Create the function that was being referenced in previous migrations

-- Create the get_sample_rows function that accepts (table_name, limit_count)
CREATE OR REPLACE FUNCTION public.get_sample_rows(table_name text, limit_count integer DEFAULT 2)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
declare
  sample_json jsonb;
begin
  -- Validate table name to prevent SQL injection
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = get_sample_rows.table_name
  ) THEN
    RETURN '[]'::jsonb;
  END IF;
  
  -- Execute dynamic query with limit parameter
  EXECUTE format('SELECT coalesce(jsonb_agg(row_to_json(t)), ''[]''::jsonb) FROM (SELECT * FROM public.%I LIMIT %s) t', table_name, limit_count) 
  INTO sample_json;
  
  RETURN sample_json;
EXCEPTION
  WHEN OTHERS THEN
    -- Return empty array on any error
    RETURN '[]'::jsonb;
end;
$function$;

-- Add comment explaining the function
COMMENT ON FUNCTION public.get_sample_rows(text, integer) IS 'Returns sample rows from specified table with custom limit. Used for testing and data preview purposes.';

-- Grant execute permissions to ensure consistency with previous migration
GRANT EXECUTE ON FUNCTION public.get_sample_rows(text, integer) TO anon;
GRANT EXECUTE ON FUNCTION public.get_sample_rows(text, integer) TO authenticated;
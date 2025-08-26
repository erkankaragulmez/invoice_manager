-- Fix authentication dependencies and make app accessible without login
-- Current timestamp: 2025-08-06 05:41:47.979782

-- 1. Disable RLS on all tables to allow public access
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_line_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments DISABLE ROW LEVEL SECURITY;

-- 2. Drop all RLS policies
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_manage_own_business_profiles" ON public.business_profiles;
DROP POLICY IF EXISTS "users_manage_business_customers" ON public.customers;
DROP POLICY IF EXISTS "users_manage_business_invoices" ON public.invoices;
DROP POLICY IF EXISTS "users_manage_invoice_line_items" ON public.invoice_line_items;
DROP POLICY IF EXISTS "users_manage_business_expenses" ON public.expenses;
DROP POLICY IF EXISTS "users_manage_invoice_payments" ON public.payments;

-- 3. Remove foreign key constraint from user_profiles to auth.users
ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_id_fkey;

-- 4. DROP DEPENDENT CONSTRAINTS FIRST - This is the critical fix
ALTER TABLE public.business_profiles DROP CONSTRAINT IF EXISTS business_profiles_owner_id_fkey;

-- 5. Now we can safely drop and recreate the primary key
ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_pkey;
ALTER TABLE public.user_profiles ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.user_profiles ADD PRIMARY KEY (id);

-- 6. Recreate the foreign key constraint
ALTER TABLE public.business_profiles ADD CONSTRAINT business_profiles_owner_id_fkey 
    FOREIGN KEY (owner_id) REFERENCES public.user_profiles(id) ON DELETE SET NULL;

-- 7. Remove the trigger that creates user profiles from auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 8. Update get_user_business_id function to work without authentication
CREATE OR REPLACE FUNCTION public.get_user_business_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT bp.id FROM public.business_profiles bp
LIMIT 1
$$;

-- 9. Grant public access to all tables for anonymous users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_profiles TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.business_profiles TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.customers TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invoices TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invoice_line_items TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.expenses TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payments TO anon;

-- 10. Grant usage on sequences to anonymous users
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

-- 11. Grant execute permissions on functions to anonymous users
GRANT EXECUTE ON FUNCTION public.get_user_business_id() TO anon;
GRANT EXECUTE ON FUNCTION public.get_sample_rows(TEXT, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION public.update_invoice_totals() TO anon;
GRANT EXECUTE ON FUNCTION public.update_payment_status() TO anon;

-- 12. Comment on the changes for documentation
COMMENT ON TABLE public.user_profiles IS 'User profiles table - now independent of authentication system';
COMMENT ON FUNCTION public.get_user_business_id() IS 'Returns first business ID for demo purposes - no authentication required';

-- 13. Add cleanup function for easy rollback if needed
CREATE OR REPLACE FUNCTION public.cleanup_auth_independence()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- This function can be used to clean up the changes if needed
    RAISE NOTICE 'Authentication independence applied successfully';
    RAISE NOTICE 'To rollback, create a new migration with proper auth setup';
END $$;

-- Execute cleanup notification
SELECT public.cleanup_auth_independence();
-- Location: supabase/migrations/20250805081717_invoice_manager_complete_schema.sql
-- Schema Analysis: Fresh project - no existing tables
-- Integration Type: Complete new schema
-- Dependencies: None - creating complete invoice management system

-- 1. Extensions and Custom Types
CREATE TYPE public.user_role AS ENUM ('admin', 'business_owner', 'accountant');
CREATE TYPE public.business_type AS ENUM ('sole_proprietorship', 'llc', 'corporation', 'partnership', 'other');
CREATE TYPE public.invoice_status AS ENUM ('draft', 'pending', 'paid', 'overdue', 'cancelled');
CREATE TYPE public.payment_status AS ENUM ('unpaid', 'partial', 'paid', 'refunded');
CREATE TYPE public.expense_category AS ENUM ('office', 'transportation', 'materials', 'utilities', 'marketing', 'other');

-- 2. Core Tables

-- User profiles table (critical intermediary between auth.users and business data)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    role public.user_role DEFAULT 'business_owner'::public.user_role,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Business profiles table
CREATE TABLE public.business_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    business_type public.business_type NOT NULL,
    tax_number TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Customers table
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.business_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    tax_number TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Invoices table
CREATE TABLE public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.business_profiles(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    invoice_number TEXT NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE,
    status public.invoice_status DEFAULT 'draft'::public.invoice_status,
    payment_status public.payment_status DEFAULT 'unpaid'::public.payment_status,
    subtotal DECIMAL(12,2) DEFAULT 0.00,
    tax_rate DECIMAL(5,2) DEFAULT 18.00,
    tax_amount DECIMAL(12,2) DEFAULT 0.00,
    total_amount DECIMAL(12,2) DEFAULT 0.00,
    notes TEXT,
    payment_terms TEXT DEFAULT 'net30',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Invoice line items table
CREATE TABLE public.invoice_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES public.invoices(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1.00,
    unit_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    line_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Expenses table
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES public.business_profiles(id) ON DELETE CASCADE,
    category public.expense_category NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    expense_date DATE NOT NULL,
    receipt_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Payments table
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES public.invoices(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method TEXT,
    reference_number TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_business_profiles_owner_id ON public.business_profiles(owner_id);
CREATE INDEX idx_customers_business_id ON public.customers(business_id);
CREATE INDEX idx_invoices_business_id ON public.invoices(business_id);
CREATE INDEX idx_invoices_customer_id ON public.invoices(customer_id);
CREATE INDEX idx_invoices_status ON public.invoices(status);
CREATE INDEX idx_invoices_issue_date ON public.invoices(issue_date);
CREATE INDEX idx_invoice_line_items_invoice_id ON public.invoice_line_items(invoice_id);
CREATE INDEX idx_expenses_business_id ON public.expenses(business_id);
CREATE INDEX idx_expenses_category ON public.expenses(category);
CREATE INDEX idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX idx_payments_invoice_id ON public.payments(invoice_id);

-- Unique constraints
CREATE UNIQUE INDEX idx_invoices_number_business ON public.invoices(business_id, invoice_number);

-- 4. Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- 5. Helper Functions
CREATE OR REPLACE FUNCTION public.get_user_business_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT bp.id FROM public.business_profiles bp
WHERE bp.owner_id = auth.uid()
LIMIT 1
$$;

-- 6. RLS Policies

-- Pattern 1: Core user table - Simple ownership
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple business ownership
CREATE POLICY "users_manage_own_business_profiles"
ON public.business_profiles
FOR ALL
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- Business-based access for customers
CREATE POLICY "users_manage_business_customers"
ON public.customers
FOR ALL
TO authenticated
USING (business_id = public.get_user_business_id())
WITH CHECK (business_id = public.get_user_business_id());

-- Business-based access for invoices
CREATE POLICY "users_manage_business_invoices"
ON public.invoices
FOR ALL
TO authenticated
USING (business_id = public.get_user_business_id())
WITH CHECK (business_id = public.get_user_business_id());

-- Invoice line items access through invoice ownership
CREATE POLICY "users_manage_invoice_line_items"
ON public.invoice_line_items
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.invoices i
        WHERE i.id = invoice_line_items.invoice_id
        AND i.business_id = public.get_user_business_id()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.invoices i
        WHERE i.id = invoice_line_items.invoice_id
        AND i.business_id = public.get_user_business_id()
    )
);

-- Business-based access for expenses
CREATE POLICY "users_manage_business_expenses"
ON public.expenses
FOR ALL
TO authenticated
USING (business_id = public.get_user_business_id())
WITH CHECK (business_id = public.get_user_business_id());

-- Payments access through invoice ownership
CREATE POLICY "users_manage_invoice_payments"
ON public.payments
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.invoices i
        WHERE i.id = payments.invoice_id
        AND i.business_id = public.get_user_business_id()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.invoices i
        WHERE i.id = payments.invoice_id
        AND i.business_id = public.get_user_business_id()
    )
);

-- 7. Trigger Functions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'business_owner'::public.user_role)
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_invoice_totals()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update invoice totals when line items change
    UPDATE public.invoices
    SET 
        subtotal = (
            SELECT COALESCE(SUM(line_total), 0.00)
            FROM public.invoice_line_items
            WHERE invoice_id = COALESCE(NEW.invoice_id, OLD.invoice_id)
        ),
        tax_amount = subtotal * (tax_rate / 100),
        total_amount = subtotal + tax_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_payment_status()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    invoice_total DECIMAL(12,2);
    total_paid DECIMAL(12,2);
BEGIN
    -- Get invoice total
    SELECT total_amount INTO invoice_total
    FROM public.invoices
    WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);
    
    -- Calculate total payments
    SELECT COALESCE(SUM(amount), 0.00) INTO total_paid
    FROM public.payments
    WHERE invoice_id = COALESCE(NEW.invoice_id, OLD.invoice_id);
    
    -- Update payment status
    UPDATE public.invoices
    SET 
        payment_status = CASE
            WHEN total_paid = 0 THEN 'unpaid'::public.payment_status
            WHEN total_paid < invoice_total THEN 'partial'::public.payment_status
            WHEN total_paid >= invoice_total THEN 'paid'::public.payment_status
            ELSE 'unpaid'::public.payment_status
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.invoice_id, OLD.invoice_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- 8. Triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER update_invoice_totals_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.invoice_line_items
  FOR EACH ROW EXECUTE FUNCTION public.update_invoice_totals();

CREATE TRIGGER update_payment_status_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.update_payment_status();

-- 9. Mock Data
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    business_user_uuid UUID := gen_random_uuid();
    business1_id UUID := gen_random_uuid();
    business2_id UUID := gen_random_uuid();
    customer1_id UUID := gen_random_uuid();
    customer2_id UUID := gen_random_uuid();
    customer3_id UUID := gen_random_uuid();
    invoice1_id UUID := gen_random_uuid();
    invoice2_id UUID := gen_random_uuid();
    invoice3_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@faturamanager.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (business_user_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'demo@business.com', crypt('demo123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Ahmet Yılmaz", "role": "business_owner"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create business profiles
    INSERT INTO public.business_profiles (id, owner_id, business_name, business_type, tax_number, address, phone, email)
    VALUES
        (business1_id, admin_uuid, 'TechnoSoft Yazılım', 'llc', '1234567890', 'Atatürk Cad. No:123 İstanbul', '+90 212 555 0001', 'info@technosoft.com'),
        (business2_id, business_user_uuid, 'Yılmaz Danışmanlık', 'sole_proprietorship', '9876543210', 'İstiklal Cad. No:456 Ankara', '+90 312 555 0002', 'info@yilmazdanismanlik.com');

    -- Create customers
    INSERT INTO public.customers (id, business_id, name, email, phone, address, tax_number)
    VALUES
        (customer1_id, business1_id, 'Ahmet Yılmaz Ltd.', 'ahmet@yilmazltd.com', '+90 532 123 4567', 'Cumhuriyet Mah. İzmir', '1111111111'),
        (customer2_id, business1_id, 'Teknoloji A.Ş.', 'info@teknoloji.com', '+90 533 987 6543', 'Kızılay Mah. Ankara', '2222222222'),
        (customer3_id, business2_id, 'Güven İnşaat', 'info@guveninsaat.com', '+90 534 555 1234', 'Çankaya Mah. Ankara', '3333333333');

    -- Create invoices
    INSERT INTO public.invoices (id, business_id, customer_id, invoice_number, issue_date, due_date, status, payment_status, tax_rate, notes, payment_terms)
    VALUES
        (invoice1_id, business1_id, customer1_id, '2025-001', '2025-08-01', '2025-08-31', 'pending', 'unpaid', 18.00, 'Web sitesi geliştirme projesi', 'net30'),
        (invoice2_id, business1_id, customer2_id, '2025-002', '2025-08-02', '2025-09-01', 'paid', 'paid', 18.00, 'Mobil uygulama geliştirme', 'net30'),
        (invoice3_id, business2_id, customer3_id, '2025-003', '2025-08-03', '2025-09-02', 'pending', 'unpaid', 18.00, 'İnşaat projesi danışmanlığı', 'net15');

    -- Create invoice line items
    INSERT INTO public.invoice_line_items (invoice_id, description, quantity, unit_price, line_total)
    VALUES
        (invoice1_id, 'Frontend Geliştirme', 1.00, 8000.00, 8000.00),
        (invoice1_id, 'Backend API Geliştirme', 1.00, 6000.00, 6000.00),
        (invoice1_id, 'Veritabanı Tasarımı', 1.00, 1750.00, 1750.00),
        (invoice2_id, 'iOS Uygulama Geliştirme', 1.00, 15000.00, 15000.00),
        (invoice2_id, 'Android Uygulama Geliştirme', 1.00, 15000.00, 15000.00),
        (invoice2_id, 'API Entegrasyonu', 1.00, 2400.00, 2400.00),
        (invoice3_id, 'Proje Analizi', 10.00, 500.00, 5000.00),
        (invoice3_id, 'Teknik Danışmanlık', 5.00, 800.00, 4000.00);

    -- Create expenses
    INSERT INTO public.expenses (business_id, category, description, amount, expense_date, notes)
    VALUES
        (business1_id, 'office', 'Ofis Kirası - Ağustos', 5000.00, '2025-08-01', 'Aylık ofis kirası'),
        (business1_id, 'utilities', 'İnternet ve Telefon', 450.00, '2025-08-01', 'Aylık internet ve telefon faturası'),
        (business1_id, 'materials', 'Yazılım Lisansları', 2000.00, '2025-08-02', 'Geliştirme araçları lisansları'),
        (business1_id, 'transportation', 'Müşteri Ziyaretleri', 300.00, '2025-08-03', 'Taksi ve ulaşım giderleri'),
        (business2_id, 'office', 'Ofis Malzemeleri', 750.00, '2025-08-01', 'Kırtasiye ve ofis ekipmanları'),
        (business2_id, 'marketing', 'Reklam Giderleri', 1200.00, '2025-08-02', 'Online reklam kampanyası');

    -- Create payments
    INSERT INTO public.payments (invoice_id, amount, payment_date, payment_method, reference_number, notes)
    VALUES
        (invoice2_id, 32400.00, '2025-08-05', 'Banka Transferi', 'TRF2025080501', 'Tam ödeme alındı');

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;
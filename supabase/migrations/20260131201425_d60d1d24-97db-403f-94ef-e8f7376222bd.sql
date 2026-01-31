-- Create app_role enum for house member roles
CREATE TYPE public.app_role AS ENUM ('admin', 'member');

-- Create profiles table (linked to auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  avatar_url TEXT,
  color TEXT DEFAULT '#0D9488',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create houses table (shared living spaces)
CREATE TABLE public.houses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  invite_code TEXT UNIQUE DEFAULT gen_random_uuid()::text,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create house_members table (junction table with roles)
CREATE TABLE public.house_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL DEFAULT 'member',
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(house_id, user_id)
);

-- Create tasks table
CREATE TABLE public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  due_date DATE,
  completed BOOLEAN NOT NULL DEFAULT false,
  recurring TEXT CHECK (recurring IN ('daily', 'weekly', 'monthly')),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create rules table
CREATE TABLE public.rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create bills table
CREATE TABLE public.bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  due_date DATE NOT NULL,
  paid BOOLEAN NOT NULL DEFAULT false,
  paid_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  category TEXT NOT NULL CHECK (category IN ('rent', 'utilities', 'internet', 'other')),
  split_between UUID[] NOT NULL DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create shopping_items table
CREATE TABLE public.shopping_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  bought BOOLEAN NOT NULL DEFAULT false,
  bought_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  price DECIMAL(10,2),
  added_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create passwords table
CREATE TABLE public.passwords (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  value TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('wifi', 'streaming', 'other')),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create damaged_items table
CREATE TABLE public.damaged_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  photo_url TEXT,
  location TEXT NOT NULL,
  reported_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'fixed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create events table
CREATE TABLE public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id UUID NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  event_date DATE NOT NULL,
  event_time TIME,
  location TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Apply triggers to all tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_houses_updated_at BEFORE UPDATE ON public.houses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_rules_updated_at BEFORE UPDATE ON public.rules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_bills_updated_at BEFORE UPDATE ON public.bills FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_shopping_items_updated_at BEFORE UPDATE ON public.shopping_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_passwords_updated_at BEFORE UPDATE ON public.passwords FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_damaged_items_updated_at BEFORE UPDATE ON public.damaged_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create profile on signup trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Security definer function to check house membership (avoids RLS recursion)
CREATE OR REPLACE FUNCTION public.is_house_member(_user_id UUID, _house_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.house_members
    WHERE user_id = _user_id AND house_id = _house_id
  )
$$;

-- Security definer function to check if user is house admin
CREATE OR REPLACE FUNCTION public.is_house_admin(_user_id UUID, _house_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.house_members
    WHERE user_id = _user_id AND house_id = _house_id AND role = 'admin'
  )
$$;

-- Get user's house IDs
CREATE OR REPLACE FUNCTION public.get_user_house_ids(_user_id UUID)
RETURNS UUID[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT ARRAY_AGG(house_id) FROM public.house_members WHERE user_id = _user_id
$$;

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.houses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.house_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passwords ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.damaged_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

-- Houses policies
CREATE POLICY "Members can view their houses" ON public.houses FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), id));
CREATE POLICY "Anyone can create a house" ON public.houses FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Admins can update their houses" ON public.houses FOR UPDATE TO authenticated 
  USING (public.is_house_admin(auth.uid(), id));
CREATE POLICY "Admins can delete their houses" ON public.houses FOR DELETE TO authenticated 
  USING (public.is_house_admin(auth.uid(), id));

-- House members policies
CREATE POLICY "Members can view house members" ON public.house_members FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Users can join houses" ON public.house_members FOR INSERT TO authenticated 
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can manage house members" ON public.house_members FOR UPDATE TO authenticated 
  USING (public.is_house_admin(auth.uid(), house_id));
CREATE POLICY "Admins can remove house members" ON public.house_members FOR DELETE TO authenticated 
  USING (public.is_house_admin(auth.uid(), house_id) OR auth.uid() = user_id);

-- Tasks policies
CREATE POLICY "Members can view house tasks" ON public.tasks FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can create tasks" ON public.tasks FOR INSERT TO authenticated 
  WITH CHECK (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can update tasks" ON public.tasks FOR UPDATE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can delete tasks" ON public.tasks FOR DELETE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));

-- Rules policies
CREATE POLICY "Members can view house rules" ON public.rules FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Admins can create rules" ON public.rules FOR INSERT TO authenticated 
  WITH CHECK (public.is_house_admin(auth.uid(), house_id));
CREATE POLICY "Admins can update rules" ON public.rules FOR UPDATE TO authenticated 
  USING (public.is_house_admin(auth.uid(), house_id));
CREATE POLICY "Admins can delete rules" ON public.rules FOR DELETE TO authenticated 
  USING (public.is_house_admin(auth.uid(), house_id));

-- Bills policies
CREATE POLICY "Members can view house bills" ON public.bills FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can create bills" ON public.bills FOR INSERT TO authenticated 
  WITH CHECK (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can update bills" ON public.bills FOR UPDATE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can delete bills" ON public.bills FOR DELETE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));

-- Shopping items policies
CREATE POLICY "Members can view shopping items" ON public.shopping_items FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can create shopping items" ON public.shopping_items FOR INSERT TO authenticated 
  WITH CHECK (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can update shopping items" ON public.shopping_items FOR UPDATE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can delete shopping items" ON public.shopping_items FOR DELETE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));

-- Passwords policies
CREATE POLICY "Members can view house passwords" ON public.passwords FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Admins can create passwords" ON public.passwords FOR INSERT TO authenticated 
  WITH CHECK (public.is_house_admin(auth.uid(), house_id));
CREATE POLICY "Admins can update passwords" ON public.passwords FOR UPDATE TO authenticated 
  USING (public.is_house_admin(auth.uid(), house_id));
CREATE POLICY "Admins can delete passwords" ON public.passwords FOR DELETE TO authenticated 
  USING (public.is_house_admin(auth.uid(), house_id));

-- Damaged items policies
CREATE POLICY "Members can view damaged items" ON public.damaged_items FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can report damaged items" ON public.damaged_items FOR INSERT TO authenticated 
  WITH CHECK (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can update damaged items" ON public.damaged_items FOR UPDATE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Admins can delete damaged items" ON public.damaged_items FOR DELETE TO authenticated 
  USING (public.is_house_admin(auth.uid(), house_id));

-- Events policies
CREATE POLICY "Members can view house events" ON public.events FOR SELECT TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can create events" ON public.events FOR INSERT TO authenticated 
  WITH CHECK (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can update events" ON public.events FOR UPDATE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
CREATE POLICY "Members can delete events" ON public.events FOR DELETE TO authenticated 
  USING (public.is_house_member(auth.uid(), house_id));
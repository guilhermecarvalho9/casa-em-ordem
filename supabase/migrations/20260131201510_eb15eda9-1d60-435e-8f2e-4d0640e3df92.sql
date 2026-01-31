-- Drop the overly permissive policy
DROP POLICY IF EXISTS "Anyone can create a house" ON public.houses;

-- Create a function to handle house creation with automatic admin membership
CREATE OR REPLACE FUNCTION public.create_house_with_admin(
  _name TEXT,
  _address TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _house_id UUID;
BEGIN
  -- Insert the house
  INSERT INTO public.houses (name, address)
  VALUES (_name, _address)
  RETURNING id INTO _house_id;
  
  -- Add the creator as admin
  INSERT INTO public.house_members (house_id, user_id, role)
  VALUES (_house_id, auth.uid(), 'admin');
  
  RETURN _house_id;
END;
$$;
import { useState, useEffect, createContext, useContext, ReactNode } from 'react';
import { supabase } from '@/integrations/supabase/client';
import type { User, Session } from '@supabase/supabase-js';

interface Profile {
  id: string;
  name: string;
  avatar_url: string | null;
  color: string;
}

interface HouseMember {
  id: string;
  house_id: string;
  user_id: string;
  role: 'admin' | 'member';
  entry_date: string;
}

interface House {
  id: string;
  name: string;
  address: string | null;
  invite_code: string;
}

interface AuthContextType {
  user: User | null;
  session: Session | null;
  profile: Profile | null;
  currentHouse: House | null;
  houseMembership: HouseMember | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, name: string) => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
  createHouse: (name: string, address?: string) => Promise<{ error: Error | null; houseId?: string }>;
  joinHouse: (inviteCode: string) => Promise<{ error: Error | null }>;
  refreshHouse: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [currentHouse, setCurrentHouse] = useState<House | null>(null);
  const [houseMembership, setHouseMembership] = useState<HouseMember | null>(null);
  const [loading, setLoading] = useState(true);

  // Fetch user profile
  const fetchProfile = async (userId: string) => {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (!error && data) {
      setProfile(data as Profile);
    }
  };

  // Fetch user's house membership
  const fetchHouseMembership = async (userId: string) => {
    const { data: membership, error } = await supabase
      .from('house_members')
      .select('*')
      .eq('user_id', userId)
      .limit(1)
      .maybeSingle();

    if (!error && membership) {
      setHouseMembership(membership as HouseMember);
      
      // Fetch the house details
      const { data: house } = await supabase
        .from('houses')
        .select('*')
        .eq('id', membership.house_id)
        .single();

      if (house) {
        setCurrentHouse(house as House);
      }
    } else {
      setHouseMembership(null);
      setCurrentHouse(null);
    }
  };

  const refreshHouse = async () => {
    if (user) {
      await fetchHouseMembership(user.id);
    }
  };

  useEffect(() => {
    // Set up auth state listener FIRST
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setSession(session);
        setUser(session?.user ?? null);

        if (session?.user) {
          // Use setTimeout to avoid Supabase deadlock
          setTimeout(() => {
            fetchProfile(session.user.id);
            fetchHouseMembership(session.user.id);
          }, 0);
        } else {
          setProfile(null);
          setCurrentHouse(null);
          setHouseMembership(null);
        }
        
        setLoading(false);
      }
    );

    // THEN check for existing session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);

      if (session?.user) {
        fetchProfile(session.user.id);
        fetchHouseMembership(session.user.id);
      }
      
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    return { error };
  };

  const signUp = async (email: string, password: string, name: string) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { name },
        emailRedirectTo: window.location.origin,
      },
    });
    return { error };
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setSession(null);
    setProfile(null);
    setCurrentHouse(null);
    setHouseMembership(null);
  };

  const createHouse = async (name: string, address?: string) => {
    try {
      const { data, error } = await supabase.rpc('create_house_with_admin', {
        _name: name,
        _address: address || null,
      });

      if (error) {
        return { error };
      }

      // Refresh house membership
      if (user) {
        await fetchHouseMembership(user.id);
      }

      return { error: null, houseId: data };
    } catch (err) {
      return { error: err as Error };
    }
  };

  const joinHouse = async (inviteCode: string) => {
    try {
      // Find house by invite code
      const { data: house, error: findError } = await supabase
        .from('houses')
        .select('id')
        .eq('invite_code', inviteCode)
        .single();

      if (findError || !house) {
        return { error: new Error('Código de convite inválido') };
      }

      // Join the house
      const { error: joinError } = await supabase
        .from('house_members')
        .insert({
          house_id: house.id,
          user_id: user!.id,
          role: 'member',
        });

      if (joinError) {
        if (joinError.code === '23505') {
          return { error: new Error('Você já é membro desta casa') };
        }
        return { error: joinError };
      }

      // Refresh house membership
      if (user) {
        await fetchHouseMembership(user.id);
      }

      return { error: null };
    } catch (err) {
      return { error: err as Error };
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        profile,
        currentHouse,
        houseMembership,
        loading,
        signIn,
        signUp,
        signOut,
        createHouse,
        joinHouse,
        refreshHouse,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

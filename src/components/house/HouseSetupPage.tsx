import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Home, Plus, Users, Key, Loader2, LogOut, Copy, Check } from 'lucide-react';
import { toast } from 'sonner';
import { useAuth } from '@/hooks/useAuth';
import logoImg from '@/assets/logo.png';

interface HouseSetupPageProps {
  language: 'pt' | 'en';
}

export function HouseSetupPage({ language }: HouseSetupPageProps) {
  const { profile, signOut, createHouse, joinHouse } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [newHouse, setNewHouse] = useState({ name: '', address: '' });
  const [inviteCode, setInviteCode] = useState('');

  const t = (pt: string, en: string) => language === 'pt' ? pt : en;

  const handleCreateHouse = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newHouse.name.trim()) {
      toast.error(t('Digite o nome da casa', 'Enter the house name'));
      return;
    }

    setIsLoading(true);
    const { error } = await createHouse(newHouse.name, newHouse.address || undefined);
    setIsLoading(false);

    if (error) {
      toast.error(error.message);
      return;
    }

    toast.success(t('Casa criada com sucesso!', 'House created successfully!'));
  };

  const handleJoinHouse = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inviteCode.trim()) {
      toast.error(t('Digite o código de convite', 'Enter the invite code'));
      return;
    }

    setIsLoading(true);
    const { error } = await joinHouse(inviteCode.trim());
    setIsLoading(false);

    if (error) {
      toast.error(error.message);
      return;
    }

    toast.success(t('Você entrou na casa!', 'You joined the house!'));
  };

  const handleSignOut = async () => {
    await signOut();
    toast.success(t('Logout realizado', 'Logged out'));
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5 flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        {/* Header */}
        <div className="text-center space-y-4">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-3xl bg-gradient-to-br from-primary to-primary/60 shadow-xl shadow-primary/20">
            <img src={logoImg} alt="Logo" className="w-12 h-12 object-contain" />
          </div>
          <div>
            <h1 className="text-2xl font-display font-bold">
              {t('Olá', 'Hello')}, {profile?.name || t('Usuário', 'User')}!
            </h1>
            <p className="text-muted-foreground mt-1">
              {t('Configure sua casa para começar', 'Set up your house to get started')}
            </p>
          </div>
        </div>

        {/* House Setup Card */}
        <Card className="border-0 shadow-2xl shadow-primary/10 backdrop-blur-sm bg-card/95">
          <CardContent className="pt-6">
            <Tabs defaultValue="create" className="space-y-4">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="create" className="flex items-center gap-2">
                  <Plus className="w-4 h-4" />
                  {t('Criar Casa', 'Create House')}
                </TabsTrigger>
                <TabsTrigger value="join" className="flex items-center gap-2">
                  <Users className="w-4 h-4" />
                  {t('Entrar', 'Join')}
                </TabsTrigger>
              </TabsList>

              {/* Create House Tab */}
              <TabsContent value="create">
                <form onSubmit={handleCreateHouse} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="house-name">{t('Nome da Casa', 'House Name')}</Label>
                    <div className="relative">
                      <Home className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                      <Input
                        id="house-name"
                        type="text"
                        placeholder={t('Ex: Apartamento 101', 'Ex: Apartment 101')}
                        className="pl-10 input-field"
                        value={newHouse.name}
                        onChange={(e) => setNewHouse(prev => ({ ...prev, name: e.target.value }))}
                        disabled={isLoading}
                      />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="house-address">{t('Endereço (opcional)', 'Address (optional)')}</Label>
                    <Input
                      id="house-address"
                      type="text"
                      placeholder={t('Rua, número, cidade', 'Street, number, city')}
                      className="input-field"
                      value={newHouse.address}
                      onChange={(e) => setNewHouse(prev => ({ ...prev, address: e.target.value }))}
                      disabled={isLoading}
                    />
                  </div>
                  <Button 
                    type="submit" 
                    className="w-full btn-gradient rounded-xl h-11"
                    disabled={isLoading}
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                        {t('Criando...', 'Creating...')}
                      </>
                    ) : (
                      <>
                        <Plus className="w-4 h-4 mr-2" />
                        {t('Criar Casa', 'Create House')}
                      </>
                    )}
                  </Button>
                </form>
              </TabsContent>

              {/* Join House Tab */}
              <TabsContent value="join">
                <form onSubmit={handleJoinHouse} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="invite-code">{t('Código de Convite', 'Invite Code')}</Label>
                    <div className="relative">
                      <Key className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                      <Input
                        id="invite-code"
                        type="text"
                        placeholder={t('Cole o código aqui', 'Paste the code here')}
                        className="pl-10 input-field"
                        value={inviteCode}
                        onChange={(e) => setInviteCode(e.target.value)}
                        disabled={isLoading}
                      />
                    </div>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    {t(
                      'Peça ao administrador da casa o código de convite para entrar.',
                      'Ask the house admin for the invite code to join.'
                    )}
                  </p>
                  <Button 
                    type="submit" 
                    className="w-full btn-gradient rounded-xl h-11"
                    disabled={isLoading}
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                        {t('Entrando...', 'Joining...')}
                      </>
                    ) : (
                      <>
                        <Users className="w-4 h-4 mr-2" />
                        {t('Entrar na Casa', 'Join House')}
                      </>
                    )}
                  </Button>
                </form>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>

        {/* Sign Out */}
        <div className="text-center">
          <Button
            variant="ghost"
            onClick={handleSignOut}
            className="text-muted-foreground hover:text-foreground"
          >
            <LogOut className="w-4 h-4 mr-2" />
            {t('Sair da conta', 'Sign out')}
          </Button>
        </div>
      </div>
    </div>
  );
}

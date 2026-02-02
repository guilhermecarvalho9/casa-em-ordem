import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Mail, Lock, User, Eye, EyeOff, Loader2, ArrowLeft } from 'lucide-react';
import { toast } from 'sonner';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import logoImg from '@/assets/logo.png';

interface LoginPageProps {
  language: 'pt' | 'en';
}

type AuthView = 'main' | 'forgot-password' | 'reset-password';

export function LoginPage({ language }: LoginPageProps) {
  const { signIn, signUp } = useAuth();
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [loginData, setLoginData] = useState({ email: '', password: '' });
  const [registerData, setRegisterData] = useState({ name: '', email: '', password: '' });
  const [forgotEmail, setForgotEmail] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [view, setView] = useState<AuthView>('main');

  const t = (pt: string, en: string) => language === 'pt' ? pt : en;

  // Check if we're in password recovery mode (from email link)
  useState(() => {
    const hashParams = new URLSearchParams(window.location.hash.substring(1));
    const type = hashParams.get('type');
    if (type === 'recovery') {
      setView('reset-password');
    }
  });

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!loginData.email || !loginData.password) {
      toast.error(t('Preencha todos os campos', 'Fill in all fields'));
      return;
    }
    
    setIsLoading(true);
    const { error } = await signIn(loginData.email, loginData.password);
    setIsLoading(false);

    if (error) {
      if (error.message.includes('Invalid login credentials')) {
        toast.error(t('Email ou senha incorretos', 'Invalid email or password'));
      } else if (error.message.includes('Email not confirmed')) {
        toast.error(t('Por favor, confirme seu email antes de entrar', 'Please confirm your email before signing in'));
      } else {
        toast.error(error.message);
      }
      return;
    }
    
    toast.success(t('Login realizado com sucesso!', 'Login successful!'));
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!registerData.name || !registerData.email || !registerData.password) {
      toast.error(t('Preencha todos os campos', 'Fill in all fields'));
      return;
    }

    if (registerData.password.length < 6) {
      toast.error(t('A senha deve ter pelo menos 6 caracteres', 'Password must be at least 6 characters'));
      return;
    }
    
    setIsLoading(true);
    const { error } = await signUp(registerData.email, registerData.password, registerData.name);
    setIsLoading(false);

    if (error) {
      if (error.message.includes('already registered')) {
        toast.error(t('Este email já está cadastrado', 'This email is already registered'));
      } else {
        toast.error(error.message);
      }
      return;
    }
    
    toast.success(t(
      'Conta criada! Verifique seu email para confirmar o cadastro.',
      'Account created! Check your email to confirm registration.'
    ));
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!forgotEmail) {
      toast.error(t('Digite seu email', 'Enter your email'));
      return;
    }

    setIsLoading(true);
    const { error } = await supabase.auth.resetPasswordForEmail(forgotEmail, {
      redirectTo: window.location.origin,
    });
    setIsLoading(false);

    if (error) {
      toast.error(error.message);
      return;
    }

    toast.success(t(
      'Email enviado! Verifique sua caixa de entrada para redefinir sua senha.',
      'Email sent! Check your inbox to reset your password.'
    ));
    setView('main');
    setForgotEmail('');
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPassword) {
      toast.error(t('Digite sua nova senha', 'Enter your new password'));
      return;
    }

    if (newPassword.length < 6) {
      toast.error(t('A senha deve ter pelo menos 6 caracteres', 'Password must be at least 6 characters'));
      return;
    }

    setIsLoading(true);
    const { error } = await supabase.auth.updateUser({ password: newPassword });
    setIsLoading(false);

    if (error) {
      toast.error(error.message);
      return;
    }

    toast.success(t('Senha atualizada com sucesso!', 'Password updated successfully!'));
    setView('main');
    setNewPassword('');
    // Clear the hash from URL
    window.history.replaceState(null, '', window.location.pathname);
  };

  // Forgot Password View
  if (view === 'forgot-password') {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5 flex items-center justify-center p-4">
        <div className="w-full max-w-md space-y-6">
          <div className="text-center space-y-4">
            <div className="inline-flex items-center justify-center w-20 h-20 rounded-3xl bg-gradient-to-br from-primary to-primary/60 shadow-xl shadow-primary/20">
              <img src={logoImg} alt="Logo" className="w-12 h-12 object-contain" />
            </div>
            <div>
              <h1 className="text-2xl font-display font-bold">
                {t('Esqueceu a senha?', 'Forgot your password?')}
              </h1>
              <p className="text-muted-foreground mt-1">
                {t('Digite seu email para receber um link de recuperação', 'Enter your email to receive a recovery link')}
              </p>
            </div>
          </div>

          <Card className="border-0 shadow-2xl shadow-primary/10 backdrop-blur-sm bg-card/95">
            <CardContent className="pt-6">
              <form onSubmit={handleForgotPassword} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="forgot-email">{t('Email', 'Email')}</Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                    <Input
                      id="forgot-email"
                      type="email"
                      placeholder="seu@email.com"
                      className="pl-10 input-field"
                      value={forgotEmail}
                      onChange={(e) => setForgotEmail(e.target.value)}
                      disabled={isLoading}
                    />
                  </div>
                </div>
                <Button 
                  type="submit" 
                  className="w-full btn-gradient rounded-xl h-11"
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      {t('Enviando...', 'Sending...')}
                    </>
                  ) : (
                    t('Enviar Link de Recuperação', 'Send Recovery Link')
                  )}
                </Button>
                <Button
                  type="button"
                  variant="ghost"
                  className="w-full"
                  onClick={() => setView('main')}
                >
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  {t('Voltar ao login', 'Back to login')}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  // Reset Password View
  if (view === 'reset-password') {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5 flex items-center justify-center p-4">
        <div className="w-full max-w-md space-y-6">
          <div className="text-center space-y-4">
            <div className="inline-flex items-center justify-center w-20 h-20 rounded-3xl bg-gradient-to-br from-primary to-primary/60 shadow-xl shadow-primary/20">
              <img src={logoImg} alt="Logo" className="w-12 h-12 object-contain" />
            </div>
            <div>
              <h1 className="text-2xl font-display font-bold">
                {t('Redefinir Senha', 'Reset Password')}
              </h1>
              <p className="text-muted-foreground mt-1">
                {t('Digite sua nova senha', 'Enter your new password')}
              </p>
            </div>
          </div>

          <Card className="border-0 shadow-2xl shadow-primary/10 backdrop-blur-sm bg-card/95">
            <CardContent className="pt-6">
              <form onSubmit={handleResetPassword} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="new-password">{t('Nova Senha', 'New Password')}</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                    <Input
                      id="new-password"
                      type={showPassword ? 'text' : 'password'}
                      placeholder="••••••••"
                      className="pl-10 pr-10 input-field"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      disabled={isLoading}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
                <Button 
                  type="submit" 
                  className="w-full btn-gradient rounded-xl h-11"
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      {t('Atualizando...', 'Updating...')}
                    </>
                  ) : (
                    t('Atualizar Senha', 'Update Password')
                  )}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  // Main Login/Register View
  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5 flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        {/* Logo & Brand */}
        <div className="text-center space-y-4">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-3xl bg-gradient-to-br from-primary to-primary/60 shadow-xl shadow-primary/20">
            <img src={logoImg} alt="Logo" className="w-12 h-12 object-contain" />
          </div>
          <div>
            <h1 className="text-3xl font-display font-bold bg-gradient-to-r from-primary to-primary/60 bg-clip-text text-transparent">
              {t('Casa Organizada', 'Home Organized')}
            </h1>
            <p className="text-muted-foreground mt-1">
              {t('Gerencie sua casa de forma inteligente', 'Manage your home smartly')}
            </p>
          </div>
        </div>

        {/* Auth Card */}
        <Card className="border-0 shadow-2xl shadow-primary/10 backdrop-blur-sm bg-card/95">
          <CardContent className="pt-6">
            <Tabs defaultValue="login" className="space-y-4">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="login">{t('Entrar', 'Login')}</TabsTrigger>
                <TabsTrigger value="register">{t('Criar Conta', 'Sign Up')}</TabsTrigger>
              </TabsList>

              {/* Login Tab */}
              <TabsContent value="login">
                <form onSubmit={handleLogin} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="login-email">{t('Email', 'Email')}</Label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                      <Input
                        id="login-email"
                        type="email"
                        placeholder="seu@email.com"
                        className="pl-10 input-field"
                        value={loginData.email}
                        onChange={(e) => setLoginData(prev => ({ ...prev, email: e.target.value }))}
                        disabled={isLoading}
                      />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="login-password">{t('Senha', 'Password')}</Label>
                    <div className="relative">
                      <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                      <Input
                        id="login-password"
                        type={showPassword ? 'text' : 'password'}
                        placeholder="••••••••"
                        className="pl-10 pr-10 input-field"
                        value={loginData.password}
                        onChange={(e) => setLoginData(prev => ({ ...prev, password: e.target.value }))}
                        disabled={isLoading}
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                      >
                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>
                  <div className="text-right">
                    <button
                      type="button"
                      onClick={() => setView('forgot-password')}
                      className="text-sm text-primary hover:underline"
                    >
                      {t('Esqueceu a senha?', 'Forgot password?')}
                    </button>
                  </div>
                  <Button 
                    type="submit" 
                    className="w-full btn-gradient rounded-xl h-11"
                    disabled={isLoading}
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                        {t('Entrando...', 'Logging in...')}
                      </>
                    ) : (
                      t('Entrar', 'Login')
                    )}
                  </Button>
                </form>
              </TabsContent>

              {/* Register Tab */}
              <TabsContent value="register">
                <form onSubmit={handleRegister} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="register-name">{t('Nome', 'Name')}</Label>
                    <div className="relative">
                      <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                      <Input
                        id="register-name"
                        type="text"
                        placeholder={t('Seu nome', 'Your name')}
                        className="pl-10 input-field"
                        value={registerData.name}
                        onChange={(e) => setRegisterData(prev => ({ ...prev, name: e.target.value }))}
                        disabled={isLoading}
                      />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="register-email">{t('Email', 'Email')}</Label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                      <Input
                        id="register-email"
                        type="email"
                        placeholder="seu@email.com"
                        className="pl-10 input-field"
                        value={registerData.email}
                        onChange={(e) => setRegisterData(prev => ({ ...prev, email: e.target.value }))}
                        disabled={isLoading}
                      />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="register-password">{t('Senha', 'Password')}</Label>
                    <div className="relative">
                      <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                      <Input
                        id="register-password"
                        type={showPassword ? 'text' : 'password'}
                        placeholder="••••••••"
                        className="pl-10 pr-10 input-field"
                        value={registerData.password}
                        onChange={(e) => setRegisterData(prev => ({ ...prev, password: e.target.value }))}
                        disabled={isLoading}
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                      >
                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
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
                      t('Criar Conta', 'Sign Up')
                    )}
                  </Button>
                </form>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>

        {/* Footer */}
        <p className="text-center text-xs text-muted-foreground">
          {t('Organize sua casa, simplifique sua vida.', 'Organize your home, simplify your life.')}
        </p>
      </div>
    </div>
  );
}

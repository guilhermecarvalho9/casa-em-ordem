import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Plus, Key, Wifi, Tv, Lock, Eye, EyeOff, Copy, Check } from 'lucide-react';
import { toast } from 'sonner';

export function PasswordsPage() {
  const { t, passwords, setPasswords } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const [newPassword, setNewPassword] = useState({ name: '', value: '', category: 'wifi' as const });
  const [visiblePasswords, setVisiblePasswords] = useState<Record<string, boolean>>({});
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const categoryIcons = {
    wifi: Wifi,
    streaming: Tv,
    other: Lock,
  };

  const categoryLabels = {
    wifi: t('passwords.wifi'),
    streaming: t('passwords.streaming'),
    other: t('passwords.other'),
  };

  const handleAddPassword = () => {
    if (!newPassword.name.trim() || !newPassword.value.trim()) return;
    
    setPasswords(prev => [...prev, {
      id: Date.now().toString(),
      name: newPassword.name,
      value: newPassword.value,
      category: newPassword.category,
    }]);
    setNewPassword({ name: '', value: '', category: 'wifi' });
    setIsOpen(false);
  };

  const toggleVisibility = (id: string) => {
    setVisiblePasswords(prev => ({ ...prev, [id]: !prev[id] }));
  };

  const copyToClipboard = async (id: string, value: string) => {
    await navigator.clipboard.writeText(value);
    setCopiedId(id);
    toast.success('Senha copiada!');
    setTimeout(() => setCopiedId(null), 2000);
  };

  const groupedPasswords = passwords.reduce((acc, pwd) => {
    if (!acc[pwd.category]) acc[pwd.category] = [];
    acc[pwd.category].push(pwd);
    return acc;
  }, {} as Record<string, typeof passwords>);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t('passwords.title')}</h1>
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {t('passwords.add')}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="font-display">{t('passwords.add')}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Nome</Label>
                <Input
                  value={newPassword.name}
                  onChange={(e) => setNewPassword(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Ex: Wi-Fi Casa"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Senha</Label>
                <Input
                  type="text"
                  value={newPassword.value}
                  onChange={(e) => setNewPassword(prev => ({ ...prev, value: e.target.value }))}
                  placeholder="Senha"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Categoria</Label>
                <Select
                  value={newPassword.category}
                  onValueChange={(value: any) => setNewPassword(prev => ({ ...prev, category: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="wifi">{t('passwords.wifi')}</SelectItem>
                    <SelectItem value="streaming">{t('passwords.streaming')}</SelectItem>
                    <SelectItem value="other">{t('passwords.other')}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <Button onClick={handleAddPassword} className="w-full btn-gradient">
                {t('common.save')}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <div className="space-y-6">
        {Object.entries(groupedPasswords).map(([category, items]) => {
          const Icon = categoryIcons[category as keyof typeof categoryIcons];
          return (
            <Card key={category}>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 font-display">
                  <Icon className="w-5 h-5 text-primary" />
                  {categoryLabels[category as keyof typeof categoryLabels]}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {items.map(pwd => (
                  <div
                    key={pwd.id}
                    className="flex items-center gap-3 p-4 rounded-lg bg-secondary/50"
                  >
                    <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                      <Key className="w-5 h-5 text-primary" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium">{pwd.name}</p>
                      <p className="text-sm font-mono text-muted-foreground">
                        {visiblePasswords[pwd.id] ? pwd.value : '••••••••••'}
                      </p>
                    </div>
                    <div className="flex items-center gap-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => toggleVisibility(pwd.id)}
                      >
                        {visiblePasswords[pwd.id] ? (
                          <EyeOff className="w-4 h-4" />
                        ) : (
                          <Eye className="w-4 h-4" />
                        )}
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => copyToClipboard(pwd.id, pwd.value)}
                      >
                        {copiedId === pwd.id ? (
                          <Check className="w-4 h-4 text-success" />
                        ) : (
                          <Copy className="w-4 h-4" />
                        )}
                      </Button>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}

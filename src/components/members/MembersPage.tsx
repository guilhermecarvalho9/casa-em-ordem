import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Plus, Calendar, Shield, User, Pencil, Trash2 } from 'lucide-react';

export function MembersPage() {
  const { t, members, setMembers } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const [editingMember, setEditingMember] = useState<string | null>(null);
  const [newMember, setNewMember] = useState<{ name: string; role: 'admin' | 'member'; color: string }>({ name: '', role: 'member', color: '#0D9488' });

  const colors = ['#0D9488', '#F59E0B', '#8B5CF6', '#EF4444', '#10B981', '#3B82F6'];

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  const handleAddMember = () => {
    if (!newMember.name.trim()) return;
    
    if (editingMember) {
      setMembers(prev => prev.map(m => 
        m.id === editingMember 
          ? { ...m, name: newMember.name, role: newMember.role, color: newMember.color }
          : m
      ));
      setEditingMember(null);
    } else {
      setMembers(prev => [...prev, {
        id: Date.now().toString(),
        name: newMember.name,
        avatar: '',
        entryDate: new Date().toISOString().split('T')[0],
        role: newMember.role,
        color: newMember.color,
      }]);
    }
    setNewMember({ name: '', role: 'member', color: '#0D9488' });
    setIsOpen(false);
  };

  const handleEditMember = (member: typeof members[0]) => {
    setNewMember({
      name: member.name,
      role: member.role,
      color: member.color,
    });
    setEditingMember(member.id);
    setIsOpen(true);
  };

  const handleDeleteMember = (id: string) => {
    setMembers(prev => prev.filter(m => m.id !== id));
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t('members.title')}</h1>
        <Dialog open={isOpen} onOpenChange={(open) => {
          setIsOpen(open);
          if (!open) {
            setEditingMember(null);
            setNewMember({ name: '', role: 'member', color: '#0D9488' });
          }
        }}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {t('members.add')}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="font-display">
                {editingMember ? 'Editar Membro' : t('members.add')}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Nome</Label>
                <Input
                  value={newMember.name}
                  onChange={(e) => setNewMember(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Nome do membro"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Função</Label>
                <Select
                  value={newMember.role}
                  onValueChange={(value: 'admin' | 'member') => setNewMember(prev => ({ ...prev, role: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">{t('members.role.admin')}</SelectItem>
                    <SelectItem value="member">{t('members.role.member')}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Cor</Label>
                <div className="flex gap-2">
                  {colors.map(color => (
                    <button
                      key={color}
                      onClick={() => setNewMember(prev => ({ ...prev, color }))}
                      className={`w-8 h-8 rounded-full transition-transform ${newMember.color === color ? 'ring-2 ring-offset-2 ring-primary scale-110' : ''}`}
                      style={{ backgroundColor: color }}
                    />
                  ))}
                </div>
              </div>
              <Button onClick={handleAddMember} className="w-full btn-gradient">
                {t('common.save')}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {members.map((member) => (
          <Card key={member.id} className="card-hover">
            <CardContent className="pt-6">
              <div className="flex flex-col items-center text-center space-y-4">
                <Avatar className="w-20 h-20">
                  <AvatarFallback
                    style={{ backgroundColor: member.color }}
                    className="text-2xl font-bold text-white"
                  >
                    {getInitials(member.name)}
                  </AvatarFallback>
                </Avatar>
                <div className="space-y-1">
                  <h3 className="font-display font-semibold text-lg">{member.name}</h3>
                  <Badge variant={member.role === 'admin' ? 'default' : 'secondary'}>
                    {member.role === 'admin' ? (
                      <><Shield className="w-3 h-3 mr-1" />{t('members.role.admin')}</>
                    ) : (
                      <><User className="w-3 h-3 mr-1" />{t('members.role.member')}</>
                    )}
                  </Badge>
                </div>
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <Calendar className="w-4 h-4" />
                  {t('members.entry')}: {member.entryDate}
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8"
                    onClick={() => handleEditMember(member)}
                  >
                    <Pencil className="w-4 h-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-8 w-8 text-destructive hover:text-destructive"
                    onClick={() => handleDeleteMember(member.id)}
                  >
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}

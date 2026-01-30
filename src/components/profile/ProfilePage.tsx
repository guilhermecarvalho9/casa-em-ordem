import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { User, Mail, Phone, Calendar, Pencil, Save, X } from 'lucide-react';

export function ProfilePage() {
  const { language, members } = useApp();
  const [isEditing, setIsEditing] = useState(false);
  
  // Using the first member as the current user profile (demo)
  const currentUser = members[0];
  
  const [profile, setProfile] = useState({
    name: currentUser?.name || '',
    email: 'joao.silva@email.com',
    phone: '(11) 99999-9999',
    birthDate: '1990-05-15',
    occupation: language === 'pt' ? 'Engenheiro de Software' : 'Software Engineer',
    emergencyContact: 'Maria Silva - (11) 98888-8888',
  });

  const getInitials = (name: string) => name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);

  const handleSave = () => {
    setIsEditing(false);
  };

  const handleCancel = () => {
    setProfile({
      name: currentUser?.name || '',
      email: 'joao.silva@email.com',
      phone: '(11) 99999-9999',
      birthDate: '1990-05-15',
      occupation: language === 'pt' ? 'Engenheiro de Software' : 'Software Engineer',
      emergencyContact: 'Maria Silva - (11) 98888-8888',
    });
    setIsEditing(false);
  };

  const t = {
    title: language === 'pt' ? 'Meu Perfil' : 'My Profile',
    personalInfo: language === 'pt' ? 'Informações Pessoais' : 'Personal Information',
    name: language === 'pt' ? 'Nome Completo' : 'Full Name',
    email: language === 'pt' ? 'Email' : 'Email',
    phone: language === 'pt' ? 'Telefone' : 'Phone',
    birthDate: language === 'pt' ? 'Data de Nascimento' : 'Birth Date',
    occupation: language === 'pt' ? 'Ocupação' : 'Occupation',
    emergencyContact: language === 'pt' ? 'Contato de Emergência' : 'Emergency Contact',
    edit: language === 'pt' ? 'Editar' : 'Edit',
    save: language === 'pt' ? 'Salvar' : 'Save',
    cancel: language === 'pt' ? 'Cancelar' : 'Cancel',
    memberSince: language === 'pt' ? 'Membro desde' : 'Member since',
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t.title}</h1>
        {!isEditing ? (
          <Button className="btn-gradient rounded-xl" onClick={() => setIsEditing(true)}>
            <Pencil className="w-4 h-4 mr-2" />
            {t.edit}
          </Button>
        ) : (
          <div className="flex gap-2">
            <Button variant="outline" onClick={handleCancel}>
              <X className="w-4 h-4 mr-2" />
              {t.cancel}
            </Button>
            <Button className="btn-gradient" onClick={handleSave}>
              <Save className="w-4 h-4 mr-2" />
              {t.save}
            </Button>
          </div>
        )}
      </div>

      <div className="max-w-3xl">
        {/* Profile Header */}
        <Card className="mb-6">
          <CardContent className="pt-6">
            <div className="flex items-center gap-6">
              <Avatar className="w-24 h-24">
                <AvatarFallback 
                  style={{ backgroundColor: currentUser?.color || '#0D9488' }} 
                  className="text-2xl text-white font-bold"
                >
                  {getInitials(profile.name)}
                </AvatarFallback>
              </Avatar>
              <div>
                <h2 className="text-2xl font-display font-bold">{profile.name}</h2>
                <p className="text-muted-foreground">{profile.occupation}</p>
                <div className="flex items-center gap-2 mt-2 text-sm text-muted-foreground">
                  <Calendar className="w-4 h-4" />
                  {t.memberSince} {currentUser?.entryDate || '2024-01-15'}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Personal Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <User className="w-5 h-5 text-primary" />
              {t.personalInfo}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>{t.name}</Label>
                {isEditing ? (
                  <Input
                    value={profile.name}
                    onChange={(e) => setProfile(prev => ({ ...prev, name: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{profile.name}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Mail className="w-4 h-4" />
                  {t.email}
                </Label>
                {isEditing ? (
                  <Input
                    type="email"
                    value={profile.email}
                    onChange={(e) => setProfile(prev => ({ ...prev, email: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{profile.email}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Phone className="w-4 h-4" />
                  {t.phone}
                </Label>
                {isEditing ? (
                  <Input
                    value={profile.phone}
                    onChange={(e) => setProfile(prev => ({ ...prev, phone: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{profile.phone}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  {t.birthDate}
                </Label>
                {isEditing ? (
                  <Input
                    type="date"
                    value={profile.birthDate}
                    onChange={(e) => setProfile(prev => ({ ...prev, birthDate: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{profile.birthDate}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.occupation}</Label>
                {isEditing ? (
                  <Input
                    value={profile.occupation}
                    onChange={(e) => setProfile(prev => ({ ...prev, occupation: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{profile.occupation}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label>{t.emergencyContact}</Label>
                {isEditing ? (
                  <Input
                    value={profile.emergencyContact}
                    onChange={(e) => setProfile(prev => ({ ...prev, emergencyContact: e.target.value }))}
                    className="input-field"
                  />
                ) : (
                  <p className="p-2 rounded-lg bg-secondary/50">{profile.emergencyContact}</p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

import { useState, useRef } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Plus, AlertTriangle, Check, MapPin, Calendar, Camera, Image } from 'lucide-react';

export function DamagedPage() {
  const { t, damagedItems, setDamagedItems, members } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const [newItem, setNewItem] = useState({ title: '', description: '', location: '', photo: '' });
  const fileInputRef = useRef<HTMLInputElement>(null);

  const getInitials = (name: string) => name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  const getMemberById = (id: string) => members.find(m => m.id === id);

  const handleAddItem = () => {
    if (!newItem.title.trim()) return;
    
    setDamagedItems(prev => [...prev, {
      id: Date.now().toString(),
      title: newItem.title,
      description: newItem.description,
      location: newItem.location,
      photo: newItem.photo,
      reportedBy: members[0]?.id || '',
      reportedAt: new Date().toISOString().split('T')[0],
      status: 'pending',
    }]);
    setNewItem({ title: '', description: '', location: '', photo: '' });
    setIsOpen(false);
  };

  const toggleStatus = (id: string) => {
    setDamagedItems(prev => prev.map(item =>
      item.id === id ? { ...item, status: item.status === 'pending' ? 'fixed' : 'pending' } : item
    ));
  };

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setNewItem(prev => ({ ...prev, photo: reader.result as string }));
      };
      reader.readAsDataURL(file);
    }
  };

  const pending = damagedItems.filter(i => i.status === 'pending');
  const fixed = damagedItems.filter(i => i.status === 'fixed');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t('damaged.title')}</h1>
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {t('damaged.add')}
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle className="font-display">{t('damaged.add')}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Título</Label>
                <Input
                  value={newItem.title}
                  onChange={(e) => setNewItem(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="Ex: Torneira vazando"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Descrição</Label>
                <Textarea
                  value={newItem.description}
                  onChange={(e) => setNewItem(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Descreva o problema"
                  className="input-field min-h-20"
                />
              </div>
              <div className="space-y-2">
                <Label>Localização</Label>
                <Input
                  value={newItem.location}
                  onChange={(e) => setNewItem(prev => ({ ...prev, location: e.target.value }))}
                  placeholder="Ex: Cozinha, Banheiro"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Foto</Label>
                <input
                  type="file"
                  accept="image/*"
                  ref={fileInputRef}
                  onChange={handlePhotoUpload}
                  className="hidden"
                />
                {newItem.photo ? (
                  <div className="relative">
                    <img
                      src={newItem.photo}
                      alt="Preview"
                      className="w-full h-32 object-cover rounded-lg"
                    />
                    <Button
                      variant="secondary"
                      size="sm"
                      className="absolute top-2 right-2"
                      onClick={() => setNewItem(prev => ({ ...prev, photo: '' }))}
                    >
                      Remover
                    </Button>
                  </div>
                ) : (
                  <Button
                    variant="outline"
                    className="w-full h-20 border-dashed"
                    onClick={() => fileInputRef.current?.click()}
                  >
                    <Camera className="w-5 h-5 mr-2" />
                    Adicionar foto
                  </Button>
                )}
              </div>
              <Button onClick={handleAddItem} className="w-full btn-gradient">
                {t('common.save')}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* Pending */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <AlertTriangle className="w-5 h-5 text-warning" />
              {t('damaged.pending')} ({pending.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {pending.map(item => {
              const reporter = getMemberById(item.reportedBy);
              return (
                <div key={item.id} className="p-4 rounded-lg bg-warning/5 border border-warning/20">
                  {item.photo && (
                    <img
                      src={item.photo}
                      alt={item.title}
                      className="w-full h-32 object-cover rounded-lg mb-3"
                    />
                  )}
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex-1">
                      <h4 className="font-semibold">{item.title}</h4>
                      {item.description && (
                        <p className="text-sm text-muted-foreground mt-1">{item.description}</p>
                      )}
                      <div className="flex flex-wrap items-center gap-3 mt-2 text-xs text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <MapPin className="w-3 h-3" />
                          {item.location}
                        </span>
                        <span className="flex items-center gap-1">
                          <Calendar className="w-3 h-3" />
                          {item.reportedAt}
                        </span>
                        {reporter && (
                          <span className="flex items-center gap-1">
                            <Avatar className="w-4 h-4">
                              <AvatarFallback style={{ backgroundColor: reporter.color }} className="text-[8px] text-white">
                                {getInitials(reporter.name)}
                              </AvatarFallback>
                            </Avatar>
                            {reporter.name}
                          </span>
                        )}
                      </div>
                    </div>
                    <Button size="sm" onClick={() => toggleStatus(item.id)}>
                      <Check className="w-4 h-4 mr-1" />
                      Resolvido
                    </Button>
                  </div>
                </div>
              );
            })}
            {pending.length === 0 && (
              <p className="text-center text-muted-foreground py-4">{t('common.noData')}</p>
            )}
          </CardContent>
        </Card>

        {/* Fixed */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <Check className="w-5 h-5 text-success" />
              {t('damaged.fixed')} ({fixed.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {fixed.map(item => (
              <div key={item.id} className="p-4 rounded-lg bg-secondary/30">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1">
                    <h4 className="font-semibold line-through text-muted-foreground">{item.title}</h4>
                    <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                      <MapPin className="w-3 h-3" />
                      {item.location}
                    </div>
                  </div>
                  <Badge className="bg-success">Resolvido</Badge>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

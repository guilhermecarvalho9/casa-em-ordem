import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Plus, BookOpen, User } from 'lucide-react';

export function RulesPage() {
  const { t, rules, setRules, members } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const [newRule, setNewRule] = useState({ title: '', description: '' });

  const getInitials = (name: string) => name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  const getMemberById = (id: string) => members.find(m => m.id === id);

  const handleAddRule = () => {
    if (!newRule.title.trim()) return;
    
    setRules(prev => [...prev, {
      id: Date.now().toString(),
      title: newRule.title,
      description: newRule.description,
      createdBy: members[0]?.id || '',
    }]);
    setNewRule({ title: '', description: '' });
    setIsOpen(false);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t('rules.title')}</h1>
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {t('rules.add')}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="font-display">{t('rules.add')}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Título</Label>
                <Input
                  value={newRule.title}
                  onChange={(e) => setNewRule(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="Nome da regra"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Descrição</Label>
                <Textarea
                  value={newRule.description}
                  onChange={(e) => setNewRule(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Descreva a regra"
                  className="input-field min-h-24"
                />
              </div>
              <Button onClick={handleAddRule} className="w-full btn-gradient">
                {t('common.save')}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid sm:grid-cols-2 gap-4">
        {rules.map((rule, index) => {
          const creator = getMemberById(rule.createdBy);
          return (
            <Card key={rule.id} className="card-hover">
              <CardContent className="pt-6">
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                    <BookOpen className="w-5 h-5 text-primary" />
                  </div>
                  <div className="flex-1 space-y-2">
                    <h3 className="font-display font-semibold">{rule.title}</h3>
                    <p className="text-sm text-muted-foreground">{rule.description}</p>
                    {creator && (
                      <div className="flex items-center gap-2 pt-2">
                        <Avatar className="w-6 h-6">
                          <AvatarFallback style={{ backgroundColor: creator.color }} className="text-[10px] text-white">
                            {getInitials(creator.name)}
                          </AvatarFallback>
                        </Avatar>
                        <span className="text-xs text-muted-foreground">{creator.name}</span>
                      </div>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}

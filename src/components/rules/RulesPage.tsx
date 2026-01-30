import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Plus, BookOpen, Pencil, Trash2 } from 'lucide-react';

export function RulesPage() {
  const { t, rules, setRules, members, language } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const [editingRule, setEditingRule] = useState<string | null>(null);
  const [newRule, setNewRule] = useState({ title: '', description: '' });

  const getInitials = (name: string) => name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  const getMemberById = (id: string) => members.find(m => m.id === id);

  const handleAddRule = () => {
    if (!newRule.title.trim()) return;
    
    if (editingRule) {
      setRules(prev => prev.map(r => 
        r.id === editingRule 
          ? { ...r, title: newRule.title, description: newRule.description }
          : r
      ));
      setEditingRule(null);
    } else {
      setRules(prev => [...prev, {
        id: Date.now().toString(),
        title: newRule.title,
        description: newRule.description,
        createdBy: members[0]?.id || '',
      }]);
    }
    
    setNewRule({ title: '', description: '' });
    setIsOpen(false);
  };

  const handleEditRule = (rule: typeof rules[0]) => {
    setNewRule({ title: rule.title, description: rule.description });
    setEditingRule(rule.id);
    setIsOpen(true);
  };

  const handleDeleteRule = (id: string) => {
    setRules(prev => prev.filter(r => r.id !== id));
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t('rules.title')}</h1>
        <Dialog open={isOpen} onOpenChange={(open) => {
          setIsOpen(open);
          if (!open) {
            setEditingRule(null);
            setNewRule({ title: '', description: '' });
          }
        }}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {t('rules.add')}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="font-display">
                {editingRule 
                  ? (language === 'pt' ? 'Editar Regra' : 'Edit Rule')
                  : t('rules.add')}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>{language === 'pt' ? 'Título' : 'Title'}</Label>
                <Input
                  value={newRule.title}
                  onChange={(e) => setNewRule(prev => ({ ...prev, title: e.target.value }))}
                  placeholder={language === 'pt' ? 'Nome da regra' : 'Rule name'}
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>{language === 'pt' ? 'Descrição' : 'Description'}</Label>
                <Textarea
                  value={newRule.description}
                  onChange={(e) => setNewRule(prev => ({ ...prev, description: e.target.value }))}
                  placeholder={language === 'pt' ? 'Descreva a regra' : 'Describe the rule'}
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
        {rules.map((rule) => {
          const creator = getMemberById(rule.createdBy);
          return (
            <Card key={rule.id} className="card-hover group">
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
                  <div className="flex gap-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8"
                      onClick={() => handleEditRule(rule)}
                    >
                      <Pencil className="w-4 h-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-destructive hover:text-destructive"
                      onClick={() => handleDeleteRule(rule.id)}
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
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

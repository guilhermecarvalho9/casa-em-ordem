import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Plus, ShoppingCart, Check, Circle, User } from 'lucide-react';

export function ShoppingPage() {
  const { t, shoppingItems, setShoppingItems, members } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const [newItem, setNewItem] = useState({ name: '', quantity: '1', addedBy: '' });

  const getInitials = (name: string) => name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  const getMemberById = (id: string) => members.find(m => m.id === id);

  const handleAddItem = () => {
    if (!newItem.name.trim()) return;
    
    setShoppingItems(prev => [...prev, {
      id: Date.now().toString(),
      name: newItem.name,
      quantity: parseInt(newItem.quantity) || 1,
      addedBy: newItem.addedBy || members[0]?.id || '',
      bought: false,
    }]);
    setNewItem({ name: '', quantity: '1', addedBy: '' });
    setIsOpen(false);
  };

  const toggleBought = (id: string, boughtBy: string) => {
    setShoppingItems(prev => prev.map(item =>
      item.id === id ? { ...item, bought: !item.bought, boughtBy: !item.bought ? boughtBy : undefined } : item
    ));
  };

  const toBuy = shoppingItems.filter(i => !i.bought);
  const bought = shoppingItems.filter(i => i.bought);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t('shopping.title')}</h1>
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {t('shopping.add')}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="font-display">{t('shopping.add')}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Item</Label>
                <Input
                  value={newItem.name}
                  onChange={(e) => setNewItem(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Nome do item"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Quantidade</Label>
                <Input
                  type="number"
                  min="1"
                  value={newItem.quantity}
                  onChange={(e) => setNewItem(prev => ({ ...prev, quantity: e.target.value }))}
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Adicionado por</Label>
                <Select
                  value={newItem.addedBy}
                  onValueChange={(value) => setNewItem(prev => ({ ...prev, addedBy: value }))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Selecione" />
                  </SelectTrigger>
                  <SelectContent>
                    {members.map(member => (
                      <SelectItem key={member.id} value={member.id}>{member.name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <Button onClick={handleAddItem} className="w-full btn-gradient">
                {t('common.save')}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* To Buy */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <ShoppingCart className="w-5 h-5 text-accent" />
              {t('shopping.toBuy')} ({toBuy.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {toBuy.map(item => {
              const addedByMember = getMemberById(item.addedBy);
              return (
                <div
                  key={item.id}
                  className="flex items-center gap-3 p-3 rounded-lg bg-secondary/50 hover:bg-secondary transition-colors"
                >
                  <Checkbox
                    checked={false}
                    onCheckedChange={() => toggleBought(item.id, members[0]?.id || '')}
                  />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium">{item.name}</p>
                    <p className="text-xs text-muted-foreground">Qtd: {item.quantity}</p>
                  </div>
                  {addedByMember && (
                    <div className="flex items-center gap-1 text-xs text-muted-foreground">
                      <Avatar className="w-5 h-5">
                        <AvatarFallback style={{ backgroundColor: addedByMember.color }} className="text-[8px] text-white">
                          {getInitials(addedByMember.name)}
                        </AvatarFallback>
                      </Avatar>
                      <span>adicionou</span>
                    </div>
                  )}
                </div>
              );
            })}
            {toBuy.length === 0 && (
              <p className="text-center text-muted-foreground py-4">{t('common.noData')}</p>
            )}
          </CardContent>
        </Card>

        {/* Bought */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <Check className="w-5 h-5 text-success" />
              {t('shopping.bought')} ({bought.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {bought.map(item => {
              const boughtByMember = getMemberById(item.boughtBy || '');
              return (
                <div
                  key={item.id}
                  className="flex items-center gap-3 p-3 rounded-lg bg-secondary/30"
                >
                  <Checkbox
                    checked={true}
                    onCheckedChange={() => toggleBought(item.id, '')}
                  />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium line-through text-muted-foreground">{item.name}</p>
                    <p className="text-xs text-muted-foreground">Qtd: {item.quantity}</p>
                  </div>
                  {boughtByMember && (
                    <div className="flex items-center gap-1 text-xs text-muted-foreground">
                      <Avatar className="w-5 h-5">
                        <AvatarFallback style={{ backgroundColor: boughtByMember.color }} className="text-[8px] text-white">
                          {getInitials(boughtByMember.name)}
                        </AvatarFallback>
                      </Avatar>
                      <span>comprou</span>
                    </div>
                  )}
                </div>
              );
            })}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

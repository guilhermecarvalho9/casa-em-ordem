import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Plus, Receipt, DollarSign, Calendar, Check, Clock, Home, Zap, Wifi, HelpCircle } from 'lucide-react';
import { StatCard } from '@/components/dashboard/StatCard';

export function BillsPage() {
  const { t, bills, setBills, members } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const [newBill, setNewBill] = useState({
    title: '',
    amount: '',
    dueDate: '',
    category: 'other' as const,
    splitBetween: [] as string[],
  });

  const getInitials = (name: string) => name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  const getMemberById = (id: string) => members.find(m => m.id === id);

  const categoryIcons = {
    rent: Home,
    utilities: Zap,
    internet: Wifi,
    other: HelpCircle,
  };

  const handleAddBill = () => {
    if (!newBill.title.trim() || !newBill.amount) return;
    
    setBills(prev => [...prev, {
      id: Date.now().toString(),
      title: newBill.title,
      amount: parseFloat(newBill.amount),
      dueDate: newBill.dueDate,
      category: newBill.category,
      splitBetween: newBill.splitBetween.length > 0 ? newBill.splitBetween : members.map(m => m.id),
      paid: false,
    }]);
    setNewBill({ title: '', amount: '', dueDate: '', category: 'other', splitBetween: [] });
    setIsOpen(false);
  };

  const togglePaid = (id: string) => {
    setBills(prev => prev.map(b => b.id === id ? { ...b, paid: !b.paid } : b));
  };

  const totalAmount = bills.reduce((sum, b) => sum + b.amount, 0);
  const paidAmount = bills.filter(b => b.paid).reduce((sum, b) => sum + b.amount, 0);
  const pendingAmount = totalAmount - paidAmount;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t('bills.title')}</h1>
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {t('bills.add')}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="font-display">{t('bills.add')}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Título</Label>
                <Input
                  value={newBill.title}
                  onChange={(e) => setNewBill(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="Nome da conta"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Valor (R$)</Label>
                <Input
                  type="number"
                  value={newBill.amount}
                  onChange={(e) => setNewBill(prev => ({ ...prev, amount: e.target.value }))}
                  placeholder="0.00"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Vencimento</Label>
                <Input
                  type="date"
                  value={newBill.dueDate}
                  onChange={(e) => setNewBill(prev => ({ ...prev, dueDate: e.target.value }))}
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Categoria</Label>
                <Select
                  value={newBill.category}
                  onValueChange={(value: any) => setNewBill(prev => ({ ...prev, category: value }))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="rent">Aluguel</SelectItem>
                    <SelectItem value="utilities">Utilidades (Luz, Água, Gás)</SelectItem>
                    <SelectItem value="internet">Internet</SelectItem>
                    <SelectItem value="other">Outros</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Dividir entre</Label>
                <div className="flex flex-wrap gap-2">
                  {members.map(member => (
                    <label
                      key={member.id}
                      className={`flex items-center gap-2 p-2 rounded-lg border cursor-pointer transition-colors ${
                        newBill.splitBetween.includes(member.id) ? 'border-primary bg-primary/10' : 'border-border'
                      }`}
                    >
                      <Checkbox
                        checked={newBill.splitBetween.includes(member.id)}
                        onCheckedChange={(checked) => {
                          setNewBill(prev => ({
                            ...prev,
                            splitBetween: checked
                              ? [...prev.splitBetween, member.id]
                              : prev.splitBetween.filter(id => id !== member.id),
                          }));
                        }}
                      />
                      <span className="text-sm">{member.name}</span>
                    </label>
                  ))}
                </div>
              </div>
              <Button onClick={handleAddBill} className="w-full btn-gradient">
                {t('common.save')}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <StatCard title={t('bills.total')} value={`R$ ${totalAmount.toFixed(0)}`} icon={Receipt} color="primary" />
        <StatCard title={t('bills.paid')} value={`R$ ${paidAmount.toFixed(0)}`} icon={Check} color="success" />
        <StatCard title={t('bills.pending')} value={`R$ ${pendingAmount.toFixed(0)}`} icon={Clock} color="warning" />
      </div>

      {/* Bills List */}
      <div className="space-y-3">
        {bills.map(bill => {
          const Icon = categoryIcons[bill.category];
          const sharePerPerson = bill.amount / bill.splitBetween.length;
          
          return (
            <Card key={bill.id} className={`card-hover ${bill.paid ? 'opacity-60' : ''}`}>
              <CardContent className="p-4">
                <div className="flex items-center gap-4">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${bill.paid ? 'bg-success/10' : 'bg-warning/10'}`}>
                    <Icon className={`w-6 h-6 ${bill.paid ? 'text-success' : 'text-warning'}`} />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h3 className={`font-semibold ${bill.paid ? 'line-through' : ''}`}>{bill.title}</h3>
                      <Badge variant={bill.paid ? 'default' : 'secondary'} className={bill.paid ? 'bg-success' : 'bg-warning'}>
                        {bill.paid ? 'Pago' : 'Pendente'}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-4 mt-1 text-sm text-muted-foreground">
                      <span className="flex items-center gap-1">
                        <Calendar className="w-3 h-3" />
                        {bill.dueDate}
                      </span>
                      <span className="flex items-center gap-1">
                        <DollarSign className="w-3 h-3" />
                        R$ {sharePerPerson.toFixed(2)}/pessoa
                      </span>
                    </div>
                    <div className="flex items-center gap-1 mt-2">
                      {bill.splitBetween.map(id => {
                        const member = getMemberById(id);
                        return member ? (
                          <Avatar key={id} className="w-6 h-6">
                            <AvatarFallback style={{ backgroundColor: member.color }} className="text-[10px] text-white">
                              {getInitials(member.name)}
                            </AvatarFallback>
                          </Avatar>
                        ) : null;
                      })}
                    </div>
                  </div>
                  
                  <div className="text-right">
                    <p className="text-xl font-bold">R$ {bill.amount.toFixed(2)}</p>
                    <Button
                      size="sm"
                      variant={bill.paid ? 'outline' : 'default'}
                      onClick={() => togglePaid(bill.id)}
                      className="mt-2"
                    >
                      {bill.paid ? 'Desfazer' : 'Marcar Pago'}
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

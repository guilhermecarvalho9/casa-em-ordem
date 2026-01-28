import { useApp } from '@/contexts/AppContext';
import { StatCard } from './StatCard';
import { CheckSquare, Receipt, ShoppingCart, Users, AlertTriangle, TrendingUp } from 'lucide-react';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export function Dashboard() {
  const { t, members, tasks, bills, shoppingItems, damagedItems } = useApp();

  const pendingTasks = tasks.filter(t => !t.completed).length;
  const totalBills = bills.reduce((sum, b) => sum + b.amount, 0);
  const pendingBills = bills.filter(b => !b.paid).length;
  const itemsToBuy = shoppingItems.filter(i => !i.bought).length;
  const pendingDamaged = damagedItems.filter(d => d.status === 'pending').length;

  const getMemberById = (id: string) => members.find(m => m.id === id);

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  return (
    <div className="space-y-6">
      {/* Welcome Header */}
      <div className="space-y-1">
        <h1 className="text-3xl font-display font-bold">{t('dashboard.welcome')}! 👋</h1>
        <p className="text-muted-foreground">Aqui está o resumo da sua casa</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title={t('dashboard.tasks')}
          value={pendingTasks}
          icon={CheckSquare}
          color="primary"
        />
        <StatCard
          title={t('dashboard.bills')}
          value={`R$ ${totalBills.toFixed(0)}`}
          icon={Receipt}
          trend={`${pendingBills} pendentes`}
          color="warning"
        />
        <StatCard
          title={t('dashboard.shopping')}
          value={itemsToBuy}
          icon={ShoppingCart}
          color="accent"
        />
        <StatCard
          title={t('dashboard.members')}
          value={members.length}
          icon={Users}
          color="success"
        />
      </div>

      {/* Main Content Grid */}
      <div className="grid lg:grid-cols-2 gap-6">
        {/* Recent Tasks */}
        <Card className="card-hover">
          <CardHeader className="pb-3">
            <CardTitle className="flex items-center gap-2 font-display">
              <CheckSquare className="w-5 h-5 text-primary" />
              {t('tasks.title')}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {tasks.slice(0, 4).map((task) => {
              const member = getMemberById(task.assignedTo);
              return (
                <div
                  key={task.id}
                  className="flex items-center gap-3 p-3 rounded-lg bg-secondary/50 hover:bg-secondary transition-colors"
                >
                  <div
                    className={`w-3 h-3 rounded-full ${
                      task.completed ? 'bg-success' : 'bg-warning'
                    }`}
                  />
                  <div className="flex-1 min-w-0">
                    <p className={`font-medium truncate ${task.completed ? 'line-through text-muted-foreground' : ''}`}>
                      {task.title}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {task.dueDate}
                    </p>
                  </div>
                  {member && (
                    <Avatar className="w-8 h-8">
                      <AvatarFallback
                        style={{ backgroundColor: member.color }}
                        className="text-xs font-medium text-white"
                      >
                        {getInitials(member.name)}
                      </AvatarFallback>
                    </Avatar>
                  )}
                </div>
              );
            })}
          </CardContent>
        </Card>

        {/* Bills Overview */}
        <Card className="card-hover">
          <CardHeader className="pb-3">
            <CardTitle className="flex items-center gap-2 font-display">
              <Receipt className="w-5 h-5 text-warning" />
              {t('bills.title')}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {bills.slice(0, 4).map((bill) => (
              <div
                key={bill.id}
                className="flex items-center justify-between p-3 rounded-lg bg-secondary/50 hover:bg-secondary transition-colors"
              >
                <div className="flex-1">
                  <p className="font-medium">{bill.title}</p>
                  <p className="text-xs text-muted-foreground">
                    Vence: {bill.dueDate}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-bold">R$ {bill.amount.toFixed(2)}</p>
                  <Badge
                    variant={bill.paid ? 'default' : 'secondary'}
                    className={bill.paid ? 'bg-success' : 'bg-warning text-warning-foreground'}
                  >
                    {bill.paid ? 'Pago' : 'Pendente'}
                  </Badge>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Members */}
        <Card className="card-hover">
          <CardHeader className="pb-3">
            <CardTitle className="flex items-center gap-2 font-display">
              <Users className="w-5 h-5 text-success" />
              {t('members.title')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-4">
              {members.map((member) => (
                <div key={member.id} className="flex items-center gap-3">
                  <Avatar className="w-10 h-10">
                    <AvatarFallback
                      style={{ backgroundColor: member.color }}
                      className="font-medium text-white"
                    >
                      {getInitials(member.name)}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-medium text-sm">{member.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {member.role === 'admin' ? t('members.role.admin') : t('members.role.member')}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Alerts */}
        {pendingDamaged > 0 && (
          <Card className="card-hover border-warning/50 bg-warning/5">
            <CardHeader className="pb-3">
              <CardTitle className="flex items-center gap-2 font-display text-warning">
                <AlertTriangle className="w-5 h-5" />
                {t('damaged.title')}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {damagedItems
                  .filter(d => d.status === 'pending')
                  .slice(0, 3)
                  .map((item) => (
                    <div
                      key={item.id}
                      className="p-3 rounded-lg bg-background"
                    >
                      <p className="font-medium">{item.title}</p>
                      <p className="text-xs text-muted-foreground">
                        {item.location} • {item.reportedAt}
                      </p>
                    </div>
                  ))}
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}

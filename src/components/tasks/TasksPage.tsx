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
import { Plus, Check, Circle, Calendar } from 'lucide-react';

export function TasksPage() {
  const { t, tasks, setTasks, members } = useApp();
  const [isOpen, setIsOpen] = useState(false);
  const [newTask, setNewTask] = useState({ title: '', assignedTo: '', dueDate: '' });

  const getInitials = (name: string) => name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  const getMemberById = (id: string) => members.find(m => m.id === id);

  const handleAddTask = () => {
    if (!newTask.title.trim()) return;
    
    setTasks(prev => [...prev, {
      id: Date.now().toString(),
      title: newTask.title,
      assignedTo: newTask.assignedTo || members[0]?.id || '',
      dueDate: newTask.dueDate,
      completed: false,
    }]);
    setNewTask({ title: '', assignedTo: '', dueDate: '' });
    setIsOpen(false);
  };

  const toggleTask = (id: string) => {
    setTasks(prev => prev.map(t => t.id === id ? { ...t, completed: !t.completed } : t));
  };

  const pendingTasks = tasks.filter(t => !t.completed);
  const completedTasks = tasks.filter(t => t.completed);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-display font-bold">{t('tasks.title')}</h1>
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {t('tasks.add')}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="font-display">{t('tasks.add')}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Tarefa</Label>
                <Input
                  value={newTask.title}
                  onChange={(e) => setNewTask(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="Nome da tarefa"
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>Responsável</Label>
                <Select
                  value={newTask.assignedTo}
                  onValueChange={(value) => setNewTask(prev => ({ ...prev, assignedTo: value }))}
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
              <div className="space-y-2">
                <Label>Data limite</Label>
                <Input
                  type="date"
                  value={newTask.dueDate}
                  onChange={(e) => setNewTask(prev => ({ ...prev, dueDate: e.target.value }))}
                  className="input-field"
                />
              </div>
              <Button onClick={handleAddTask} className="w-full btn-gradient">
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
              <Circle className="w-5 h-5 text-warning" />
              {t('tasks.pending')} ({pendingTasks.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {pendingTasks.map(task => {
              const member = getMemberById(task.assignedTo);
              return (
                <div
                  key={task.id}
                  className="flex items-center gap-3 p-3 rounded-lg bg-secondary/50 hover:bg-secondary transition-colors"
                >
                  <Checkbox
                    checked={task.completed}
                    onCheckedChange={() => toggleTask(task.id)}
                  />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium truncate">{task.title}</p>
                    {task.dueDate && (
                      <p className="text-xs text-muted-foreground flex items-center gap-1">
                        <Calendar className="w-3 h-3" />
                        {task.dueDate}
                      </p>
                    )}
                  </div>
                  {member && (
                    <Avatar className="w-8 h-8">
                      <AvatarFallback style={{ backgroundColor: member.color }} className="text-xs text-white">
                        {getInitials(member.name)}
                      </AvatarFallback>
                    </Avatar>
                  )}
                </div>
              );
            })}
            {pendingTasks.length === 0 && (
              <p className="text-center text-muted-foreground py-4">{t('common.noData')}</p>
            )}
          </CardContent>
        </Card>

        {/* Completed */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <Check className="w-5 h-5 text-success" />
              {t('tasks.completed')} ({completedTasks.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {completedTasks.map(task => {
              const member = getMemberById(task.assignedTo);
              return (
                <div
                  key={task.id}
                  className="flex items-center gap-3 p-3 rounded-lg bg-secondary/30"
                >
                  <Checkbox
                    checked={task.completed}
                    onCheckedChange={() => toggleTask(task.id)}
                  />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium truncate line-through text-muted-foreground">{task.title}</p>
                  </div>
                  {member && (
                    <Avatar className="w-8 h-8 opacity-50">
                      <AvatarFallback style={{ backgroundColor: member.color }} className="text-xs text-white">
                        {getInitials(member.name)}
                      </AvatarFallback>
                    </Avatar>
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

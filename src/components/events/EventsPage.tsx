import { useState } from 'react';
import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Plus, CalendarDays, Clock, MapPin, Pencil, Trash2 } from 'lucide-react';
import { format, isSameDay, parseISO } from 'date-fns';
import { ptBR, enUS } from 'date-fns/locale';
import { cn } from '@/lib/utils';

export function EventsPage() {
  const { t, events, setEvents, members, language } = useApp();
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [isOpen, setIsOpen] = useState(false);
  const [editingEvent, setEditingEvent] = useState<string | null>(null);
  const [newEvent, setNewEvent] = useState({
    title: '',
    description: '',
    date: '',
    time: '',
    location: '',
  });

  const locale = language === 'pt' ? ptBR : enUS;

  const getInitials = (name: string) => name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  const getMemberById = (id: string) => members.find(m => m.id === id);

  const eventsOnSelectedDate = events.filter(event => 
    isSameDay(parseISO(event.date), selectedDate)
  );

  const upcomingEvents = events
    .filter(event => parseISO(event.date) >= new Date())
    .sort((a, b) => parseISO(a.date).getTime() - parseISO(b.date).getTime())
    .slice(0, 5);

  const handleAddEvent = () => {
    if (!newEvent.title.trim() || !newEvent.date) return;

    if (editingEvent) {
      setEvents(prev => prev.map(e => 
        e.id === editingEvent 
          ? { ...e, ...newEvent }
          : e
      ));
      setEditingEvent(null);
    } else {
      setEvents(prev => [...prev, {
        id: Date.now().toString(),
        ...newEvent,
        createdBy: members[0]?.id || '',
      }]);
    }
    
    setNewEvent({ title: '', description: '', date: '', time: '', location: '' });
    setIsOpen(false);
  };

  const handleEditEvent = (event: typeof events[0]) => {
    setNewEvent({
      title: event.title,
      description: event.description || '',
      date: event.date,
      time: event.time || '',
      location: event.location || '',
    });
    setEditingEvent(event.id);
    setIsOpen(true);
  };

  const handleDeleteEvent = (id: string) => {
    setEvents(prev => prev.filter(e => e.id !== id));
  };

  const datesWithEvents = events.map(e => parseISO(e.date));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
            <CalendarDays className="w-6 h-6 text-primary-foreground" />
          </div>
          <div>
            <h1 className="text-3xl font-display font-bold">
              {language === 'pt' ? 'Eventos' : 'Events'}
            </h1>
            <p className="text-muted-foreground text-sm">
              {language === 'pt' ? 'Gerencie os eventos da casa' : 'Manage house events'}
            </p>
          </div>
        </div>
        <Dialog open={isOpen} onOpenChange={(open) => {
          setIsOpen(open);
          if (!open) {
            setEditingEvent(null);
            setNewEvent({ title: '', description: '', date: '', time: '', location: '' });
          }
        }}>
          <DialogTrigger asChild>
            <Button className="btn-gradient rounded-xl">
              <Plus className="w-4 h-4 mr-2" />
              {language === 'pt' ? 'Novo Evento' : 'New Event'}
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="font-display">
                {editingEvent 
                  ? (language === 'pt' ? 'Editar Evento' : 'Edit Event')
                  : (language === 'pt' ? 'Novo Evento' : 'New Event')}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>{language === 'pt' ? 'Título' : 'Title'}</Label>
                <Input
                  value={newEvent.title}
                  onChange={(e) => setNewEvent(prev => ({ ...prev, title: e.target.value }))}
                  placeholder={language === 'pt' ? 'Nome do evento' : 'Event name'}
                  className="input-field"
                />
              </div>
              <div className="space-y-2">
                <Label>{language === 'pt' ? 'Descrição' : 'Description'}</Label>
                <Textarea
                  value={newEvent.description}
                  onChange={(e) => setNewEvent(prev => ({ ...prev, description: e.target.value }))}
                  placeholder={language === 'pt' ? 'Detalhes do evento' : 'Event details'}
                  className="input-field min-h-20"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>{language === 'pt' ? 'Data' : 'Date'}</Label>
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        className={cn(
                          "w-full justify-start text-left font-normal",
                          !newEvent.date && "text-muted-foreground"
                        )}
                      >
                        <CalendarDays className="mr-2 h-4 w-4" />
                        {newEvent.date 
                          ? format(parseISO(newEvent.date), 'PPP', { locale })
                          : (language === 'pt' ? 'Selecione' : 'Pick a date')}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={newEvent.date ? parseISO(newEvent.date) : undefined}
                        onSelect={(date) => date && setNewEvent(prev => ({ 
                          ...prev, 
                          date: format(date, 'yyyy-MM-dd') 
                        }))}
                        initialFocus
                        className={cn("p-3 pointer-events-auto")}
                      />
                    </PopoverContent>
                  </Popover>
                </div>
                <div className="space-y-2">
                  <Label>{language === 'pt' ? 'Hora' : 'Time'}</Label>
                  <Input
                    type="time"
                    value={newEvent.time}
                    onChange={(e) => setNewEvent(prev => ({ ...prev, time: e.target.value }))}
                    className="input-field"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label>{language === 'pt' ? 'Local' : 'Location'}</Label>
                <Input
                  value={newEvent.location}
                  onChange={(e) => setNewEvent(prev => ({ ...prev, location: e.target.value }))}
                  placeholder={language === 'pt' ? 'Onde será o evento' : 'Event location'}
                  className="input-field"
                />
              </div>
              <Button onClick={handleAddEvent} className="w-full btn-gradient">
                {t('common.save')}
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Calendar */}
        <Card className="lg:col-span-1">
          <CardHeader className="pb-2">
            <CardTitle className="font-display text-lg">
              {language === 'pt' ? 'Calendário' : 'Calendar'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <Calendar
              mode="single"
              selected={selectedDate}
              onSelect={(date) => date && setSelectedDate(date)}
              locale={locale}
              className="rounded-md"
              modifiers={{
                hasEvent: datesWithEvents
              }}
              modifiersStyles={{
                hasEvent: {
                  fontWeight: 'bold',
                  backgroundColor: 'hsl(var(--primary) / 0.1)',
                  color: 'hsl(var(--primary))',
                  borderRadius: '50%'
                }
              }}
            />
          </CardContent>
        </Card>

        {/* Events on selected date */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <CalendarDays className="w-5 h-5 text-primary" />
              {format(selectedDate, "PPPP", { locale })}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {eventsOnSelectedDate.length > 0 ? (
              eventsOnSelectedDate.map(event => {
                const creator = getMemberById(event.createdBy);
                return (
                  <div
                    key={event.id}
                    className="flex items-start gap-4 p-4 rounded-xl bg-secondary/50 hover:bg-secondary transition-colors"
                  >
                    <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                      <CalendarDays className="w-5 h-5 text-primary" />
                    </div>
                    <div className="flex-1 min-w-0 space-y-1">
                      <h3 className="font-display font-semibold">{event.title}</h3>
                      {event.description && (
                        <p className="text-sm text-muted-foreground">{event.description}</p>
                      )}
                      <div className="flex flex-wrap gap-3 text-xs text-muted-foreground">
                        {event.time && (
                          <span className="flex items-center gap-1">
                            <Clock className="w-3 h-3" />
                            {event.time}
                          </span>
                        )}
                        {event.location && (
                          <span className="flex items-center gap-1">
                            <MapPin className="w-3 h-3" />
                            {event.location}
                          </span>
                        )}
                      </div>
                      {creator && (
                        <div className="flex items-center gap-2 pt-1">
                          <Avatar className="w-5 h-5">
                            <AvatarFallback style={{ backgroundColor: creator.color }} className="text-[8px] text-white">
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
                        onClick={() => handleEditEvent(event)}
                      >
                        <Pencil className="w-4 h-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-destructive hover:text-destructive"
                        onClick={() => handleDeleteEvent(event.id)}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
                );
              })
            ) : (
              <p className="text-center text-muted-foreground py-8">
                {language === 'pt' ? 'Nenhum evento neste dia' : 'No events on this day'}
              </p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Upcoming Events */}
      {upcomingEvents.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="font-display">
              {language === 'pt' ? 'Próximos Eventos' : 'Upcoming Events'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {upcomingEvents.map(event => (
                <div
                  key={event.id}
                  className="p-4 rounded-xl bg-muted/50 hover:bg-muted transition-colors cursor-pointer"
                  onClick={() => setSelectedDate(parseISO(event.date))}
                >
                  <div className="flex items-center gap-2 mb-2">
                    <Badge variant="secondary" className="text-xs">
                      {format(parseISO(event.date), 'dd MMM', { locale })}
                    </Badge>
                    {event.time && (
                      <span className="text-xs text-muted-foreground">{event.time}</span>
                    )}
                  </div>
                  <h4 className="font-medium text-sm">{event.title}</h4>
                  {event.location && (
                    <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
                      <MapPin className="w-3 h-3" />
                      {event.location}
                    </p>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

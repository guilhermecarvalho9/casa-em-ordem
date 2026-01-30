import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

export type Language = 'pt' | 'en';

export interface Member {
  id: string;
  name: string;
  avatar: string;
  entryDate: string;
  role: 'admin' | 'member';
  color: string;
}

export interface Task {
  id: string;
  title: string;
  description?: string;
  assignedTo: string;
  dueDate?: string;
  completed: boolean;
  recurring?: 'daily' | 'weekly' | 'monthly';
}

export interface Rule {
  id: string;
  title: string;
  description: string;
  createdBy: string;
}

export interface Bill {
  id: string;
  title: string;
  amount: number;
  dueDate: string;
  paidBy?: string;
  splitBetween: string[];
  paid: boolean;
  category: 'rent' | 'utilities' | 'internet' | 'other';
}

export interface ShoppingItem {
  id: string;
  name: string;
  quantity: number;
  addedBy: string;
  boughtBy?: string;
  bought: boolean;
  price?: number;
}

export interface Password {
  id: string;
  name: string;
  value: string;
  category: 'wifi' | 'streaming' | 'other';
}

export interface DamagedItem {
  id: string;
  title: string;
  description: string;
  photo?: string;
  location: string;
  reportedBy: string;
  reportedAt: string;
  status: 'pending' | 'fixed';
}

export interface Event {
  id: string;
  title: string;
  description?: string;
  date: string;
  time?: string;
  location?: string;
  createdBy: string;
}

interface AppContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  darkMode: boolean;
  setDarkMode: (dark: boolean) => void;
  members: Member[];
  setMembers: React.Dispatch<React.SetStateAction<Member[]>>;
  tasks: Task[];
  setTasks: React.Dispatch<React.SetStateAction<Task[]>>;
  rules: Rule[];
  setRules: React.Dispatch<React.SetStateAction<Rule[]>>;
  bills: Bill[];
  setBills: React.Dispatch<React.SetStateAction<Bill[]>>;
  shoppingItems: ShoppingItem[];
  setShoppingItems: React.Dispatch<React.SetStateAction<ShoppingItem[]>>;
  passwords: Password[];
  setPasswords: React.Dispatch<React.SetStateAction<Password[]>>;
  damagedItems: DamagedItem[];
  setDamagedItems: React.Dispatch<React.SetStateAction<DamagedItem[]>>;
  events: Event[];
  setEvents: React.Dispatch<React.SetStateAction<Event[]>>;
  t: (key: string) => string;
}

const translations: Record<Language, Record<string, string>> = {
  pt: {
    'app.title': 'Casa Organizada',
    'nav.dashboard': 'Dashboard',
    'nav.profile': 'Perfil',
    'nav.address': 'Endereço',
    'nav.members': 'Membros',
    'nav.tasks': 'Tarefas',
    'nav.events': 'Eventos',
    'nav.rules': 'Regras',
    'nav.bills': 'Contas',
    'nav.shopping': 'Mercado',
    'nav.passwords': 'Senhas',
    'nav.damaged': 'Itens Danificados',
    'nav.qrcode': 'QR Code',
    'nav.settings': 'Configurações',
    'dashboard.welcome': 'Bem-vindo de volta',
    'dashboard.tasks': 'Tarefas Pendentes',
    'dashboard.bills': 'Contas do Mês',
    'dashboard.shopping': 'Itens no Mercado',
    'dashboard.members': 'Membros',
    'members.title': 'Membros da Casa',
    'members.add': 'Adicionar Membro',
    'members.entry': 'Entrada',
    'members.role.admin': 'Administrador',
    'members.role.member': 'Membro',
    'tasks.title': 'Tarefas',
    'tasks.add': 'Nova Tarefa',
    'tasks.completed': 'Concluídas',
    'tasks.pending': 'Pendentes',
    'rules.title': 'Regras da Casa',
    'rules.add': 'Nova Regra',
    'bills.title': 'Contas e Pagamentos',
    'bills.add': 'Nova Conta',
    'bills.total': 'Total do Mês',
    'bills.paid': 'Pagas',
    'bills.pending': 'Pendentes',
    'bills.yourShare': 'Sua Parte',
    'shopping.title': 'Lista de Mercado',
    'shopping.add': 'Adicionar Item',
    'shopping.bought': 'Comprados',
    'shopping.toBuy': 'A Comprar',
    'passwords.title': 'Senhas da Casa',
    'passwords.add': 'Adicionar Senha',
    'passwords.wifi': 'Wi-Fi',
    'passwords.streaming': 'Streaming',
    'passwords.other': 'Outros',
    'damaged.title': 'Itens Danificados',
    'damaged.add': 'Reportar Item',
    'damaged.fixed': 'Corrigidos',
    'damaged.pending': 'Pendentes',
    'settings.title': 'Configurações',
    'settings.language': 'Idioma',
    'settings.darkMode': 'Modo Escuro',
    'common.save': 'Salvar',
    'common.cancel': 'Cancelar',
    'common.delete': 'Excluir',
    'common.edit': 'Editar',
    'common.search': 'Buscar',
    'common.noData': 'Nenhum dado encontrado',
  },
  en: {
    'app.title': 'Home Organized',
    'nav.dashboard': 'Dashboard',
    'nav.profile': 'Profile',
    'nav.address': 'Address',
    'nav.members': 'Members',
    'nav.tasks': 'Tasks',
    'nav.events': 'Events',
    'nav.rules': 'Rules',
    'nav.bills': 'Bills',
    'nav.shopping': 'Shopping',
    'nav.passwords': 'Passwords',
    'nav.damaged': 'Damaged Items',
    'nav.qrcode': 'QR Code',
    'nav.settings': 'Settings',
    'dashboard.welcome': 'Welcome back',
    'dashboard.tasks': 'Pending Tasks',
    'dashboard.bills': 'Monthly Bills',
    'dashboard.shopping': 'Shopping Items',
    'dashboard.members': 'Members',
    'members.title': 'House Members',
    'members.add': 'Add Member',
    'members.entry': 'Entry',
    'members.role.admin': 'Admin',
    'members.role.member': 'Member',
    'tasks.title': 'Tasks',
    'tasks.add': 'New Task',
    'tasks.completed': 'Completed',
    'tasks.pending': 'Pending',
    'rules.title': 'House Rules',
    'rules.add': 'New Rule',
    'bills.title': 'Bills & Payments',
    'bills.add': 'New Bill',
    'bills.total': 'Monthly Total',
    'bills.paid': 'Paid',
    'bills.pending': 'Pending',
    'bills.yourShare': 'Your Share',
    'shopping.title': 'Shopping List',
    'shopping.add': 'Add Item',
    'shopping.bought': 'Bought',
    'shopping.toBuy': 'To Buy',
    'passwords.title': 'House Passwords',
    'passwords.add': 'Add Password',
    'passwords.wifi': 'Wi-Fi',
    'passwords.streaming': 'Streaming',
    'passwords.other': 'Other',
    'damaged.title': 'Damaged Items',
    'damaged.add': 'Report Item',
    'damaged.fixed': 'Fixed',
    'damaged.pending': 'Pending',
    'settings.title': 'Settings',
    'settings.language': 'Language',
    'settings.darkMode': 'Dark Mode',
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.delete': 'Delete',
    'common.edit': 'Edit',
    'common.search': 'Search',
    'common.noData': 'No data found',
  },
};

const AppContext = createContext<AppContextType | undefined>(undefined);

const initialMembers: Member[] = [
  { id: '1', name: 'João Silva', avatar: '', entryDate: '2024-01-15', role: 'admin', color: '#0D9488' },
  { id: '2', name: 'Maria Santos', avatar: '', entryDate: '2024-02-01', role: 'member', color: '#F59E0B' },
  { id: '3', name: 'Pedro Costa', avatar: '', entryDate: '2024-03-10', role: 'member', color: '#8B5CF6' },
];

const initialTasks: Task[] = [
  { id: '1', title: 'Limpar a cozinha', assignedTo: '1', dueDate: '2025-01-30', completed: false, recurring: 'weekly' },
  { id: '2', title: 'Lavar roupa', assignedTo: '2', dueDate: '2025-01-29', completed: true },
  { id: '3', title: 'Varrer a sala', assignedTo: '3', dueDate: '2025-01-31', completed: false },
];

const initialRules: Rule[] = [
  { id: '1', title: 'Silêncio após 22h', description: 'Manter silêncio após às 22h para não incomodar os vizinhos', createdBy: '1' },
  { id: '2', title: 'Limpeza da cozinha', description: 'Sempre limpar a cozinha após usar', createdBy: '1' },
];

const initialBills: Bill[] = [
  { id: '1', title: 'Aluguel', amount: 1500, dueDate: '2025-02-05', splitBetween: ['1', '2', '3'], paid: false, category: 'rent' },
  { id: '2', title: 'Internet', amount: 150, dueDate: '2025-02-10', splitBetween: ['1', '2', '3'], paid: true, paidBy: '1', category: 'internet' },
  { id: '3', title: 'Luz', amount: 280, dueDate: '2025-02-15', splitBetween: ['1', '2', '3'], paid: false, category: 'utilities' },
];

const initialShopping: ShoppingItem[] = [
  { id: '1', name: 'Arroz 5kg', quantity: 1, addedBy: '1', bought: false },
  { id: '2', name: 'Leite', quantity: 6, addedBy: '2', bought: true, boughtBy: '2', price: 35.90 },
  { id: '3', name: 'Pão de forma', quantity: 2, addedBy: '3', bought: false },
];

const initialPasswords: Password[] = [
  { id: '1', name: 'Wi-Fi Casa', value: 'casa2024@wifi', category: 'wifi' },
  { id: '2', name: 'Netflix', value: 'netflix123', category: 'streaming' },
];

const initialDamaged: DamagedItem[] = [
  { id: '1', title: 'Torneira vazando', description: 'A torneira da cozinha está pingando', location: 'Cozinha', reportedBy: '2', reportedAt: '2025-01-25', status: 'pending' },
];

const initialEvents: Event[] = [
  { id: '1', title: 'Reunião da casa', description: 'Discutir regras e tarefas', date: '2025-02-01', time: '19:00', location: 'Sala de estar', createdBy: '1' },
  { id: '2', title: 'Limpeza geral', description: 'Dia de faxina coletiva', date: '2025-02-05', time: '09:00', createdBy: '1' },
];

export function AppProvider({ children }: { children: ReactNode }) {
  const [language, setLanguage] = useState<Language>('pt');
  const [darkMode, setDarkMode] = useState(false);
  const [members, setMembers] = useState<Member[]>(initialMembers);
  const [tasks, setTasks] = useState<Task[]>(initialTasks);
  const [rules, setRules] = useState<Rule[]>(initialRules);
  const [bills, setBills] = useState<Bill[]>(initialBills);
  const [shoppingItems, setShoppingItems] = useState<ShoppingItem[]>(initialShopping);
  const [passwords, setPasswords] = useState<Password[]>(initialPasswords);
  const [damagedItems, setDamagedItems] = useState<DamagedItem[]>(initialDamaged);
  const [events, setEvents] = useState<Event[]>(initialEvents);

  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [darkMode]);

  const t = (key: string): string => {
    return translations[language][key] || key;
  };

  return (
    <AppContext.Provider
      value={{
        language,
        setLanguage,
        darkMode,
        setDarkMode,
        members,
        setMembers,
        tasks,
        setTasks,
        rules,
        setRules,
        bills,
        setBills,
        shoppingItems,
        setShoppingItems,
        passwords,
        setPasswords,
        damagedItems,
        setDamagedItems,
        events,
        setEvents,
        t,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
}

import { useApp } from '@/contexts/AppContext';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  Users,
  CheckSquare,
  BookOpen,
  Receipt,
  ShoppingCart,
  Key,
  AlertTriangle,
  Settings,
  X,
  QrCode,
} from 'lucide-react';
import logoImg from '@/assets/logo.png';

interface SidebarProps {
  currentPage: string;
  onPageChange: (page: string) => void;
  isOpen: boolean;
  onClose: () => void;
}

const navItems = [
  { id: 'dashboard', icon: LayoutDashboard, labelKey: 'nav.dashboard' },
  { id: 'members', icon: Users, labelKey: 'nav.members' },
  { id: 'tasks', icon: CheckSquare, labelKey: 'nav.tasks' },
  { id: 'rules', icon: BookOpen, labelKey: 'nav.rules' },
  { id: 'bills', icon: Receipt, labelKey: 'nav.bills' },
  { id: 'shopping', icon: ShoppingCart, labelKey: 'nav.shopping' },
  { id: 'passwords', icon: Key, labelKey: 'nav.passwords' },
  { id: 'damaged', icon: AlertTriangle, labelKey: 'nav.damaged' },
  { id: 'qrcode', icon: QrCode, labelKey: 'nav.qrcode' },
];

export function Sidebar({ currentPage, onPageChange, isOpen, onClose }: SidebarProps) {
  const { t } = useApp();

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-foreground/20 backdrop-blur-sm z-40 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed top-0 left-0 z-50 h-full w-72 bg-sidebar border-r border-sidebar-border transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static",
          isOpen ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-sidebar-border">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center shadow-lg shadow-primary/20">
                <img src={logoImg} alt="Logo" className="w-6 h-6 object-contain" />
              </div>
              <span className="font-display font-bold text-lg text-sidebar-foreground">
                {t('app.title')}
              </span>
            </div>
            <button
              onClick={onClose}
              className="lg:hidden p-2 rounded-lg hover:bg-sidebar-accent transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentPage === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => {
                    onPageChange(item.id);
                    onClose();
                  }}
                  className={cn(
                    "w-full",
                    isActive ? "nav-item-active" : "nav-item"
                  )}
                >
                  <Icon className="w-5 h-5" />
                  <span className="font-medium">{t(item.labelKey)}</span>
                </button>
              );
            })}
          </nav>

          {/* Settings */}
          <div className="p-4 border-t border-sidebar-border">
            <button
              onClick={() => {
                onPageChange('settings');
                onClose();
              }}
              className={cn(
                "w-full",
                currentPage === 'settings' ? "nav-item-active" : "nav-item"
              )}
            >
              <Settings className="w-5 h-5" />
              <span className="font-medium">{t('nav.settings')}</span>
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}

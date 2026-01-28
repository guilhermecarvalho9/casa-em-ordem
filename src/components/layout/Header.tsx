import { useApp } from '@/contexts/AppContext';
import { Menu, Moon, Sun, Globe } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface HeaderProps {
  onMenuClick: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
  const { darkMode, setDarkMode, language, setLanguage } = useApp();

  return (
    <header className="sticky top-0 z-30 h-16 bg-background/80 backdrop-blur-md border-b border-border px-4 lg:px-6 flex items-center justify-between">
      <button
        onClick={onMenuClick}
        className="lg:hidden p-2 rounded-lg hover:bg-secondary transition-colors"
      >
        <Menu className="w-6 h-6" />
      </button>

      <div className="flex-1" />

      <div className="flex items-center gap-2">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setLanguage(language === 'pt' ? 'en' : 'pt')}
          className="relative"
        >
          <Globe className="w-5 h-5" />
          <span className="absolute -bottom-1 -right-1 text-[10px] font-bold bg-primary text-primary-foreground px-1 rounded">
            {language.toUpperCase()}
          </span>
        </Button>

        <Button
          variant="ghost"
          size="icon"
          onClick={() => setDarkMode(!darkMode)}
        >
          {darkMode ? (
            <Sun className="w-5 h-5" />
          ) : (
            <Moon className="w-5 h-5" />
          )}
        </Button>
      </div>
    </header>
  );
}

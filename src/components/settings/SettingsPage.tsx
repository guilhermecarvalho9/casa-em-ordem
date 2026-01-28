import { useApp } from '@/contexts/AppContext';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Settings, Moon, Globe } from 'lucide-react';

export function SettingsPage() {
  const { t, darkMode, setDarkMode, language, setLanguage } = useApp();

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-display font-bold">{t('settings.title')}</h1>

      <div className="max-w-2xl space-y-4">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <Globe className="w-5 h-5 text-primary" />
              {t('settings.language')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <Select value={language} onValueChange={(value: 'pt' | 'en') => setLanguage(value)}>
              <SelectTrigger className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pt">🇧🇷 Português</SelectItem>
                <SelectItem value="en">🇺🇸 English</SelectItem>
              </SelectContent>
            </Select>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 font-display">
              <Moon className="w-5 h-5 text-primary" />
              {t('settings.darkMode')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">{t('settings.darkMode')}</p>
                <p className="text-sm text-muted-foreground">
                  {language === 'pt' ? 'Ativar tema escuro' : 'Enable dark theme'}
                </p>
              </div>
              <Switch checked={darkMode} onCheckedChange={setDarkMode} />
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

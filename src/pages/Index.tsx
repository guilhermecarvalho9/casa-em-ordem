import { useState } from 'react';
import { AppProvider, useApp } from '@/contexts/AppContext';
import { AuthProvider, useAuth } from '@/hooks/useAuth';
import { AppLayout } from '@/components/layout/AppLayout';
import { Dashboard } from '@/components/dashboard/Dashboard';
import { MembersPage } from '@/components/members/MembersPage';
import { TasksPage } from '@/components/tasks/TasksPage';
import { EventsPage } from '@/components/events/EventsPage';
import { RulesPage } from '@/components/rules/RulesPage';
import { BillsPage } from '@/components/bills/BillsPage';
import { ShoppingPage } from '@/components/shopping/ShoppingPage';
import { PasswordsPage } from '@/components/passwords/PasswordsPage';
import { DamagedPage } from '@/components/damaged/DamagedPage';
import { SettingsPage } from '@/components/settings/SettingsPage';
import { QRCodePage } from '@/components/qrcode/QRCodePage';
import { LoginPage } from '@/components/auth/LoginPage';
import { ProfilePage } from '@/components/profile/ProfilePage';
import { AddressPage } from '@/components/address/AddressPage';
import { HouseSetupPage } from '@/components/house/HouseSetupPage';
import { Loader2 } from 'lucide-react';

function AppContent() {
  const { language } = useApp();
  const { user, currentHouse, loading } = useAuth();
  const [currentPage, setCurrentPage] = useState('dashboard');

  const renderPage = () => {
    switch (currentPage) {
      case 'dashboard':
        return <Dashboard />;
      case 'profile':
        return <ProfilePage />;
      case 'address':
        return <AddressPage />;
      case 'members':
        return <MembersPage />;
      case 'tasks':
        return <TasksPage />;
      case 'events':
        return <EventsPage />;
      case 'rules':
        return <RulesPage />;
      case 'bills':
        return <BillsPage />;
      case 'shopping':
        return <ShoppingPage />;
      case 'passwords':
        return <PasswordsPage />;
      case 'damaged':
        return <DamagedPage />;
      case 'qrcode':
        return <QRCodePage />;
      case 'settings':
        return <SettingsPage />;
      default:
        return <Dashboard />;
    }
  };

  // Loading state
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center space-y-4">
          <Loader2 className="w-8 h-8 animate-spin mx-auto text-primary" />
          <p className="text-muted-foreground">Carregando...</p>
        </div>
      </div>
    );
  }

  // Not logged in
  if (!user) {
    return <LoginPage language={language} />;
  }

  // Logged in but no house
  if (!currentHouse) {
    return <HouseSetupPage language={language} />;
  }

  // Logged in with house
  return (
    <AppLayout currentPage={currentPage} onPageChange={setCurrentPage}>
      {renderPage()}
    </AppLayout>
  );
}

const Index = () => {
  return (
    <AuthProvider>
      <AppProvider>
        <AppContent />
      </AppProvider>
    </AuthProvider>
  );
};

export default Index;

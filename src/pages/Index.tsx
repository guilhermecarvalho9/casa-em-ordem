import { useState } from 'react';
import { AppProvider, useApp } from '@/contexts/AppContext';
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

function AppContent() {
  const { language } = useApp();
  const [currentPage, setCurrentPage] = useState('dashboard');
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  const renderPage = () => {
    switch (currentPage) {
      case 'dashboard':
        return <Dashboard />;
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

  if (!isLoggedIn) {
    return <LoginPage onLogin={() => setIsLoggedIn(true)} language={language} />;
  }

  return (
    <AppLayout currentPage={currentPage} onPageChange={setCurrentPage}>
      {renderPage()}
    </AppLayout>
  );
}

const Index = () => {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  );
};

export default Index;

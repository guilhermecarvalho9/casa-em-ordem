import { useState } from 'react';
import { AppProvider } from '@/contexts/AppContext';
import { AppLayout } from '@/components/layout/AppLayout';
import { Dashboard } from '@/components/dashboard/Dashboard';
import { MembersPage } from '@/components/members/MembersPage';
import { TasksPage } from '@/components/tasks/TasksPage';
import { RulesPage } from '@/components/rules/RulesPage';
import { BillsPage } from '@/components/bills/BillsPage';
import { ShoppingPage } from '@/components/shopping/ShoppingPage';
import { PasswordsPage } from '@/components/passwords/PasswordsPage';
import { DamagedPage } from '@/components/damaged/DamagedPage';
import { SettingsPage } from '@/components/settings/SettingsPage';

const Index = () => {
  const [currentPage, setCurrentPage] = useState('dashboard');

  const renderPage = () => {
    switch (currentPage) {
      case 'dashboard':
        return <Dashboard />;
      case 'members':
        return <MembersPage />;
      case 'tasks':
        return <TasksPage />;
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
      case 'settings':
        return <SettingsPage />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <AppProvider>
      <AppLayout currentPage={currentPage} onPageChange={setCurrentPage}>
        {renderPage()}
      </AppLayout>
    </AppProvider>
  );
};

export default Index;

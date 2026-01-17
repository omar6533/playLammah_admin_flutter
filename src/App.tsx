import { useState } from 'react';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Categories from './pages/Categories';
import Questions from './pages/Questions';
import Games from './pages/Games';
import Users from './pages/Users';
import Payments from './pages/Payments';
import Settings from './pages/Settings';

function App() {
  const [currentPage, setCurrentPage] = useState('dashboard');

  const renderPage = () => {
    switch (currentPage) {
      case 'dashboard':
        return <Dashboard />;
      case 'categories':
        return <Categories />;
      case 'questions':
        return <Questions />;
      case 'games':
        return <Games />;
      case 'users':
        return <Users />;
      case 'payments':
        return <Payments />;
      case 'settings':
        return <Settings />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <Layout currentPage={currentPage} onNavigate={setCurrentPage}>
      {renderPage()}
    </Layout>
  );
}

export default App;

import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Layout } from './components/layout/Layout';
import Dashboard from './pages/Dashboard';
import UsersManager from './pages/UsersManager';
import NutritionManager from './pages/NutritionManager';
import FetalDevelopmentManager from './pages/FetalDevelopmentManager';
import ExerciseManager from './pages/ExerciseManager';
import SleepPositionManager from './pages/SleepPositionManager';
import MusicLibraryManager from './pages/MusicLibraryManager';
import NotificationsManager from './pages/NotificationsManager';
import EmergencyContactsManager from './pages/EmergencyContactsManager';
import LanguageManager from './pages/LanguageManager';
import Settings from './pages/Settings';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          <Route path="users" element={<UsersManager />} />
          <Route path="nutrition" element={<NutritionManager />} />
          <Route path="fetal-development" element={<FetalDevelopmentManager />} />
          <Route path="exercise" element={<ExerciseManager />} />
          <Route path="sleep" element={<SleepPositionManager />} />
          <Route path="music" element={<MusicLibraryManager />} />
          <Route path="notifications" element={<NotificationsManager />} />
          <Route path="emergency" element={<EmergencyContactsManager />} />
          <Route path="language" element={<LanguageManager />} />
          <Route path="settings" element={<Settings />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

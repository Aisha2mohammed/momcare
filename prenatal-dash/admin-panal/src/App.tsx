import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import './i18n/index';
import { AuthProvider, ProtectedRoute } from './context/AuthContext';
import { Layout } from './components/layout/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import { ToastProvider } from './context/ToastContext';
import UsersManager from './pages/UsersManager';
import DoctorApprovals from './pages/DoctorApprovals';
import DoctorReviewDetail from './pages/DoctorReviewDetail';
import HealthProviders from './pages/HealthProviders';
import NutritionManager from './pages/NutritionManager';
import FetalDevelopmentManager from './pages/FetalDevelopmentManager';
import ExerciseManager from './pages/ExerciseManager';
import SleepPositionManager from './pages/SleepPositionManager';
import MusicLibraryManager from './pages/MusicLibraryManager';
import NotificationsManager from './pages/NotificationsManager';
import EmergencyContactsManager from './pages/EmergencyContactsManager';
import LanguageManager from './pages/LanguageManager';
import Announcements from './pages/Announcements';
import AuditLog from './pages/AuditLog';
import CommunityModeration from './pages/CommunityModeration';
import Settings from './pages/Settings';

export default function App() {
  return (
    <ToastProvider>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            {/* Public */}
            <Route path="/login" element={<Login />} />

            {/* Protected */}
            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <Layout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="doctor-approvals" element={<DoctorApprovals />} />
              <Route path="doctor-approvals/:id" element={<DoctorReviewDetail />} />
              <Route path="users" element={<UsersManager />} />
              <Route path="health-providers" element={<HealthProviders />} />
              <Route path="nutrition" element={<NutritionManager />} />
              <Route path="fetal-development" element={<FetalDevelopmentManager />} />
              <Route path="exercise" element={<ExerciseManager />} />
              <Route path="sleep" element={<SleepPositionManager />} />
              <Route path="music" element={<MusicLibraryManager />} />
              <Route path="notifications" element={<NotificationsManager />} />
              <Route path="emergency" element={<EmergencyContactsManager />} />
              <Route path="language" element={<LanguageManager />} />
              <Route path="announcements" element={<Announcements />} />
              <Route path="audit-log" element={<AuditLog />} />
              <Route path="community" element={<CommunityModeration />} />
              <Route path="settings" element={<Settings />} />
            </Route>

            {/* Fallback */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </ToastProvider>
  );
}

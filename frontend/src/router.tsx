import { createBrowserRouter, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import UsersPage from './pages/UsersPage';
import VerifyEmailPage from './pages/VerifyEmailPage';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <Navigate to="/users" replace />,
  },
  {
    path: '/users',
    element: <UsersPage />,
  },
  {
    path: '/register',
    element: <RegisterPage />,
  },
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/verify-email',
    element: <VerifyEmailPage />,
  },
]);

import { createBrowserRouter, Navigate } from 'react-router-dom';
import AppLayout from './components/AppLayout';
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
    element: <AppLayout />,
    children: [
      {
        path: '/auth/register',
        element: <RegisterPage />,
        handle: { title: 'Register' },
      },
      {
        path: '/auth/login',
        element: <LoginPage />,
        handle: { title: 'Login' },
      },
      {
        path: '/auth/verifyEmail/:code',
        element: <VerifyEmailPage />,
        handle: { title: 'Email Verification' },
      },
      {
        path: '/users',
        element: <UsersPage />,
        handle: { title: 'Users' },
      },
    ],
  },
]);
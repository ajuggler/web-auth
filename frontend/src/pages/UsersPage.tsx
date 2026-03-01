import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getUser, isUnauthenticatedError } from '../api/client';

export default function UsersPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState<string>('');

  useEffect(() => {
    async function loadUser() {
      try {
        const response = await getUser();
        setEmail(response);
      } catch (error) {
        if (isUnauthenticatedError(error)) {
          navigate('/auth/login', { replace: true });
          return;
        }

        setEmail('Unknown');
      }
    }

    void loadUser();
  }, [navigate]);

  return (
    <>
      <h1>Users</h1>
      <p>Current user email: {email}</p>
    </>
  );
}
import { useEffect, useState } from 'react';
import { apiRequest } from '../api/client';

export default function UsersPage() {
  const [email, setEmail] = useState<string>('');

  useEffect(() => {
    async function loadUser() {
      try {
        const response = await apiRequest<string>('/users');
        setEmail(response);
      } catch {
        setEmail('Unknown');
      }
    }

    void loadUser();
  }, []);

  return (
    <>
      <h1>Users</h1>
      <p>Current user email: {email}</p>
    </>
  );
}
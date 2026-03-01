import type { FormEvent } from 'react';
import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { ApiError, login } from '../api/client';

export default function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState<string | null>(null);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setMessage(null);

    try {
      await login({ email, password });
      navigate('/');
    } catch (error) {
      if (error instanceof ApiError) {
        setMessage(error.uiMessage);
        return;
      }

      setMessage('Something went wrong');
    }
  }

  return (
    <>
      <h1>Login</h1>
      <form onSubmit={onSubmit}>
        <label htmlFor="login-email">Email</label>
        <input
          id="login-email"
          name="email"
          type="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />

        <label htmlFor="login-password">Password</label>
        <input
          id="login-password"
          name="password"
          type="password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />

        <button type="submit">Submit</button>
      </form>

      {message ? <p>{message}</p> : null}

      <p>
        <Link to="/auth/register">Register</Link>
      </p>
    </>
  );
}
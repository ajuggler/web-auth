import type { FormEvent } from 'react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { ApiError, apiRequest } from '../api/client';

type FormErrors = {
  email?: string;
  password?: string;
};

type RegistrationErrorBody = {
  tag?: string;
};

function validateEmail(email: string): string | undefined {
  const emailRegex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,64}$/i;
  if (!email.trim()) return 'Email is required';
  if (!emailRegex.test(email)) return 'Not a valid email';
  return undefined;
}

function validatePassword(password: string): string | undefined {
  if (!password) return 'Password is required';
  if (password.length < 5 || password.length > 50) return 'Should be between 5 and 50';
  if (!/\d/.test(password)) return 'Should contain number';
  if (!/[A-Z]/.test(password)) return 'Should contain uppercase letter';
  if (!/[a-z]/.test(password)) return 'Should contain lowercase letter';
  return undefined;
}

export default function RegisterPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<FormErrors>({});
  const [message, setMessage] = useState<string | null>(null);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors: FormErrors = {
      email: validateEmail(email),
      password: validatePassword(password),
    };

    setErrors(nextErrors);
    setMessage(null);

    if (nextErrors.email || nextErrors.password) {
      return;
    }

    try {
      await apiRequest<null>('/auth/register', 'POST', { email, password });
      setMessage('Registered successfully');
      setPassword('');
    } catch (error) {
      if (error instanceof ApiError) {
        const body = error.body as RegistrationErrorBody | null;
        if (body?.tag === 'EmailTaken') {
          setMessage('Email has been taken');
          return;
        }
      }
      setMessage('Something went wrong');
    }
  }

  return (
    <>
      <h1>Register</h1>
      <form onSubmit={onSubmit} noValidate>
        <label htmlFor="register-email">Email</label>
        <input
          id="register-email"
          name="email"
          type="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />
        {errors.email ? <p className="error-message">{errors.email}</p> : null}

        <label htmlFor="register-password">Password</label>
        <input
          id="register-password"
          name="password"
          type="password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />
        {errors.password ? <p className="error-message">{errors.password}</p> : null}

        <button type="submit">Submit</button>
      </form>

      {message ? <p>{message}</p> : null}

      <p>
        <Link to="/auth/login">Login</Link>
      </p>
    </>
  );
}
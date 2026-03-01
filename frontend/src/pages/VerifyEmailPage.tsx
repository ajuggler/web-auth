import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ApiError, apiRequest } from '../api/client';

type VerifyEmailErrorBody = {
  tag?: string;
};

export default function VerifyEmailPage() {
  const { code } = useParams();
  const [message, setMessage] = useState('');

  useEffect(() => {
    async function verify() {
      if (!code) {
        setMessage('The verification code is invalid');
        return;
      }

      try {
        await apiRequest<null>('/auth/verifyEmail', 'POST', code);
        setMessage('Your Email has been verified');
      } catch (error) {
        if (error instanceof ApiError) {
          const body = error.body as VerifyEmailErrorBody | null;
          if (body?.tag === 'InvalidCode') {
            setMessage('The verification code is invalid');
            return;
          }
        }
        setMessage('The verification code is invalid');
      }
    }

    void verify();
  }, [code]);

  return (
    <>
      <h1>Email Verification</h1>
      <p>{message}</p>
      <p>
        <Link to="/auth/login">Login</Link>
      </p>
    </>
  );
}
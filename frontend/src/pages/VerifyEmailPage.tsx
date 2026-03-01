import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ApiError, verifyEmail } from '../api/client';

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
        await verifyEmail(code);
        setMessage('Your Email has been verified');
      } catch (error) {
        if (error instanceof ApiError) {
          setMessage(error.uiMessage);
          return;
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
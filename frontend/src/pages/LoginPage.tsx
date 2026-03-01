import { Link } from 'react-router-dom';

export default function LoginPage() {
  return (
    <main>
      <h1>Login</h1>
      <p>Sign in with your credentials.</p>
      <p>
        Need an account? <Link to="/register">Register</Link>
      </p>
    </main>
  );
}

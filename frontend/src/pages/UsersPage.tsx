import { Link } from 'react-router-dom';

export default function UsersPage() {
  return (
    <main>
      <img src="/images/logo.png" alt="Application logo" width={120} height={120} />
      <h1>Users</h1>
      <p>This is the default post-auth landing route.</p>
      <nav>
        <Link to="/login">Login</Link> | <Link to="/register">Register</Link> |{' '}
        <Link to="/verify-email">Verify Email</Link>
      </nav>
    </main>
  );
}

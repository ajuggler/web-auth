import { Link } from 'react-router-dom';

export default function RegisterPage() {
  return (
    <main>
      <h1>Register</h1>
      <p>Create your account to get started.</p>
      <p>
        Already have an account? <Link to="/login">Log in</Link>
      </p>
    </main>
  );
}

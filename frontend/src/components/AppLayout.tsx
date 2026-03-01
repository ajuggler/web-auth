import { useEffect } from 'react';
import { Outlet, useMatches } from 'react-router-dom';

type RouteHandle = {
  title?: string;
};

export default function AppLayout() {
  const matches = useMatches();
  const title =
    [...matches]
      .reverse()
      .map((match) => (match.handle as RouteHandle | undefined)?.title)
      .find(Boolean) ?? 'App';

  useEffect(() => {
    document.title = title;
  }, [title]);

  return (
    <main className="layout">
      <img className="logo" src="/images/logo.png" alt="Application logo" width={120} height={120} />
      <section className="content">
        <Outlet />
      </section>
    </main>
  );
}
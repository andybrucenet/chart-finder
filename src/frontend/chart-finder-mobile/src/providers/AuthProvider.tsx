import { createContext, ReactNode, useContext, useEffect, useState } from 'react';

export type AuthStatus = 'checking' | 'authenticated' | 'unauthenticated';

interface AuthContextValue {
  status: AuthStatus;
  login: () => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

interface Props {
  children: ReactNode;
}

export function AuthProvider({ children }: Props): JSX.Element {
  const [status, setStatus] = useState<AuthStatus>('checking');

  useEffect(() => {
    const timer = setTimeout(() => setStatus('authenticated'), 300);
    return () => clearTimeout(timer);
  }, []);

  const login = (): void => setStatus('authenticated');
  const logout = (): void => setStatus('unauthenticated');

  return (
    <AuthContext.Provider value={{ status, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

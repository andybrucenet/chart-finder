import { AuthProvider } from './src/providers/AuthProvider';
import { AppNavigator } from './src/navigation/AppNavigator';

export default function App(): JSX.Element {
  return (
    <AuthProvider>
      <AppNavigator />
    </AuthProvider>
  );
}

import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View, Button } from 'react-native';
import { useAuth } from '../providers/AuthProvider';

export function AuthScreen(): JSX.Element {
  const { login } = useAuth();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Chart Finder</Text>
      <Text style={styles.subtitle}>Sign in to continue.</Text>
      <Button title="Mock Sign In" onPress={login} />
      <StatusBar style="light" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#020617',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
    color: '#e2e8f0',
    marginBottom: 12
  },
  subtitle: {
    fontSize: 16,
    color: '#94a3b8',
    marginBottom: 32
  }
});

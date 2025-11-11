import { StatusBar } from 'expo-status-bar';
import { SafeAreaView, StyleSheet, Text } from 'react-native';

export default function App(): JSX.Element {
  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Chart Finder Mobile</Text>
      <Text style={styles.subtitle}>React Native skeleton ready for emulator testing.</Text>
      <StatusBar style="light" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0f172a',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: '#f8fafc',
    marginBottom: 12
  },
  subtitle: {
    fontSize: 16,
    color: '#cbd5f5',
    textAlign: 'center'
  }
});

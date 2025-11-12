import { StatusBar } from 'expo-status-bar';
import { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Button,
  SafeAreaView,
  StyleSheet,
  Text,
  TextInput,
  View
} from 'react-native';

const API_BASE = process.env.EXPO_PUBLIC_API_BASE_URL ?? '';

async function callCalculator(x: number, y: number): Promise<number> {
  if (!API_BASE) {
    throw new Error('API base URL missing. Set EXPO_PUBLIC_API_BASE_URL before building.');
  }

  const url = `${API_BASE.replace(/\/+$/, '')}/calculator/v1/add/${x}/${y}`;
  const response = await fetch(url, { method: 'GET' });

  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`Request failed: ${response.status} ${response.statusText}\n${detail}`);
  }

  const payload = await response.json();
  if (typeof payload?.result !== 'number') {
    throw new Error('Calculator payload missing numeric `result` field.');
  }

  return payload.result;
}

export default function App(): JSX.Element {
  const [x, setX] = useState('2');
  const [y, setY] = useState('3');
  const [result, setResult] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (): Promise<void> => {
    const parsedX = Number(x);
    const parsedY = Number(y);

    if (!Number.isFinite(parsedX) || !Number.isFinite(parsedY)) {
      Alert.alert('Input error', 'Both values must be valid numbers.');
      return;
    }

    try {
      setIsLoading(true);
      const sum = await callCalculator(parsedX, parsedY);
      setResult(sum);
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown calculator error';
      Alert.alert('Calculator call failed', message);
      setResult(null);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Chart Finder Mobile</Text>
      <Text style={styles.subtitle}>Call the calculator Lambda for a quick smoke test.</Text>

      <View style={styles.form}>
        <TextInput
          style={styles.input}
          placeholder="First number"
          keyboardType="numeric"
          value={x}
          onChangeText={setX}
        />
        <TextInput
          style={styles.input}
          placeholder="Second number"
          keyboardType="numeric"
          value={y}
          onChangeText={setY}
        />
        <Button title="Add" onPress={handleSubmit} disabled={isLoading} />

        <View style={styles.result}>
          {isLoading && <ActivityIndicator />}
          {!isLoading && result !== null && (
            <Text style={styles.resultText}>Result: {result}</Text>
          )}
        </View>
      </View>

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
    textAlign: 'center',
    marginBottom: 24
  },
  form: {
    width: '100%',
    gap: 12
  },
  input: {
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#475569',
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: '#1e293b',
    color: '#f8fafc'
  },
  result: {
    minHeight: 40,
    justifyContent: 'center',
    alignItems: 'center'
  },
  resultText: {
    color: '#f8fafc',
    fontSize: 18,
    fontWeight: '600'
  }
});
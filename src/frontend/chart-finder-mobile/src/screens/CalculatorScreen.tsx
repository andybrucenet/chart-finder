import { StatusBar } from 'expo-status-bar';
import {
  ActivityIndicator,
  Button,
  SafeAreaView,
  StyleSheet,
  Text,
  TextInput,
  View
} from 'react-native';
import { useCalculator } from '../hooks/useCalculator';

export function CalculatorScreen(): JSX.Element {
  const { x, setX, y, setY, result, isLoading, handleSubmit } = useCalculator();

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

import { StatusBar } from 'expo-status-bar';
import {
  ActivityIndicator,
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
  Platform
} from 'react-native';
import { useVersion } from '../hooks/useVersion';

export function VersionScreen(): JSX.Element {
  const { version, isLoading, handleSubmit } = useVersion();

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Chart Finder Mobile</Text>
      <Text style={styles.subtitle}>Fetch backend version info through the utils endpoint.</Text>

      <View style={styles.form}>
        <Button title="Fetch Version" onPress={handleSubmit} disabled={isLoading} />

        <View style={styles.result}>
          {isLoading && <ActivityIndicator />}
          {!isLoading && version && (
            <ScrollView style={styles.versionScroll}>
              <Text style={styles.resultText}>{JSON.stringify(version, null, 2)}</Text>
            </ScrollView>
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
  result: {
    minHeight: 120,
    width: '100%',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#475569',
    backgroundColor: '#0b1220',
    padding: 12
  },
  resultText: {
    color: '#f8fafc',
    fontSize: 14,
    fontFamily: Platform.select({ ios: 'Menlo', default: 'monospace' })
  },
  versionScroll: {
    maxHeight: 200
  }
});

import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { AuthScreen } from '../screens/AuthScreen';
import { CalculatorScreen } from '../screens/CalculatorScreen';
import { useAuth } from '../providers/AuthProvider';

export type RootStackParamList = {
  Auth: undefined;
  Calculator: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export function AppNavigator(): JSX.Element {
  const { status } = useAuth();

  if (status === 'checking') {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  const isAuthenticated = status === 'authenticated';

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {isAuthenticated ? (
          <Stack.Screen name="Calculator" component={CalculatorScreen} />
        ) : (
          <Stack.Screen name="Auth" component={AuthScreen} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center'
  }
});

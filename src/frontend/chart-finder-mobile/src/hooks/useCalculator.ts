import { useState } from 'react';
import { Alert } from 'react-native';
import { addAsync } from '../services/calculatorService';

export function useCalculator() {
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
      const sum = await addAsync(parsedX, parsedY);
      setResult(sum);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown calculator error';
      Alert.alert('Calculator call failed', message);
      setResult(null);
    } finally {
      setIsLoading(false);
    }
  };

  return {
    x,
    setX,
    y,
    setY,
    result,
    isLoading,
    handleSubmit
  };
}

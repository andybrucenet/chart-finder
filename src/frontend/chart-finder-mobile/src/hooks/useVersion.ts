import { useMemo, useState } from 'react';
import { Alert } from 'react-native';
import { createUtilsApi } from '../services/chartFinderSdk';

type VersionPayload = Record<string, unknown>;

export function useVersion() {
  const [version, setVersion] = useState<VersionPayload | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const utilsApi = useMemo(() => createUtilsApi(), []);

  const handleSubmit = async (): Promise<void> => {
    try {
      setIsLoading(true);
      const apiResponse = await utilsApi.utilsGetVersionRaw();
      const payload = (await apiResponse.raw.json()) as VersionPayload;
      setVersion(payload);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown version error';
      Alert.alert('Version request failed', message);
      setVersion(null);
    } finally {
      setIsLoading(false);
    }
  };

  return {
    version,
    isLoading,
    handleSubmit
  };
}

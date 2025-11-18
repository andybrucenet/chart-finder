import {
  Configuration,
  type ConfigurationParameters,
  UtilsApi,
} from '@andybrucenet/chart-finder-sdk';
import { VersionInfo } from '../versionInfo';

let cachedBaseUrl: string | null = null;

const trimTrailingSlashes = (value: string) => value.replace(/\/+$/, '');

const readEnvApiBase = (): string | undefined => {
  try {
    const env =
      (globalThis as { process?: { env?: Record<string, string | undefined> } })
        ?.process?.env;
    const raw = env?.EXPO_PUBLIC_API_BASE_URL?.trim();
    return raw ? raw : undefined;
  } catch {
    return undefined;
  }
};

export const getChartFinderApiBaseUrl = (): string => {
  if (cachedBaseUrl) {
    return cachedBaseUrl;
  }

  const envBase = readEnvApiBase();
  const fallback = VersionInfo.apiBaseUrl?.trim();
  const resolved = envBase || fallback;

  if (!resolved) {
    throw new Error(
      'API base URL missing. Set EXPO_PUBLIC_API_BASE_URL or versionInfo.apiBaseUrl.',
    );
  }

  cachedBaseUrl = trimTrailingSlashes(resolved);
  return cachedBaseUrl;
};

export const createChartFinderConfiguration = (
  overrides?: ConfigurationParameters,
) =>
  new Configuration({
    basePath: getChartFinderApiBaseUrl(),
    ...(overrides ?? {}),
  });

export const createUtilsApi = (
  overrides?: ConfigurationParameters,
) => new UtilsApi(createChartFinderConfiguration(overrides));

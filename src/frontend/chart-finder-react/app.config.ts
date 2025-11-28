import type { ConfigContext, ExpoConfig } from 'expo/config';
import { VersionInfo } from './src/versionInfo.ts';

const requireValue = <T>(value: T | undefined | null, key: string): T => {
  if (!value) {
    throw new Error(`VersionInfo missing ${key}`);
  }
  return value;
};

const versionShort = requireValue(VersionInfo.versionShort, 'versionShort');
const iosBuildNumber = requireValue(VersionInfo.versionFullNumeric, 'versionFullNumeric');
const androidVersionCode = Number(requireValue(VersionInfo.versionShortNumeric, 'versionShortNumeric'));
const companySlug = requireValue(VersionInfo.companySlug, 'companySlug');
const productSlug = requireValue(VersionInfo.productSlug, 'productSlug');
const iosBundleId = `com.${companySlug}.${productSlug}`;
const androidPackage = iosBundleId;
const appName = requireValue(VersionInfo.productName, 'productName');
const slug = `${productSlug}-react`;

export default ({ config }: ConfigContext = {} as ConfigContext): ExpoConfig => ({
  ...config,
  name: appName,
  slug: slug,
  version: versionShort,
  orientation: 'portrait',
  jsEngine: 'hermes',
  platforms: ['ios', 'android', 'web'],
  splash: {
    backgroundColor: '#0f172a',
  },
  assetBundlePatterns: ['**/*'],
  ios: {
    bundleIdentifier: iosBundleId,
    buildNumber: iosBuildNumber,
  },
  android: {
    package: androidPackage,
    versionCode: androidVersionCode,
  },
  extra: {
    companyName: VersionInfo.companyName,
    productName: VersionInfo.productName,
    apiBaseUrl: VersionInfo.apiBaseUrl,
    buildNumber: VersionInfo.buildNumber,
    buildComment: VersionInfo.buildComment,
    branch: VersionInfo.branch,
    informationalVersion: VersionInfo.informationalVersion,
  },
});

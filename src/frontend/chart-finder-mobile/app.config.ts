import type { ConfigContext, ExpoConfig } from 'expo/config';
import { VersionInfo } from './src/versionInfo.ts';

const DEFAULT_APP_NAME = 'Chart Finder';
const DEFAULT_SLUG = 'chart-finder-mobile';

const versionShort = VersionInfo.versionShort || '1.0.0';
const iosBuildNumber = VersionInfo.versionFullNumeric || '1';
const androidVersionCode = Number(VersionInfo.versionShortNumeric || '1');
const companySlug = VersionInfo.companySlug || 'softwareab';
const productSlug = VersionInfo.productSlug || 'chartfinder';
const iosBundleId = `com.${companySlug}.${productSlug}`;
const androidPackage = iosBundleId;
const appName = VersionInfo.productName || DEFAULT_APP_NAME;
const slug = DEFAULT_SLUG;

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

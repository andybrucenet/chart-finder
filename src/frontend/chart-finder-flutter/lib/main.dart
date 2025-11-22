import 'dart:convert';
import 'package:chart_finder_client/chart_finder_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'version_info.dart';

void main() {
  final service = VersionService(
    baseUrlOverride: versionInfo.apiBaseUrl,
  );
  runApp(ChartFinderApp(versionService: service));
}

class ChartFinderApp extends StatelessWidget {
  const ChartFinderApp({super.key, required this.versionService});

  final VersionService versionService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chart Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: VersionScreen(service: versionService),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VersionScreen extends StatefulWidget {
  const VersionScreen({super.key, required this.service});

  final VersionService service;

  @override
  State<VersionScreen> createState() => _VersionScreenState();
}

class _VersionScreenState extends State<VersionScreen> {
  late Future<BackendVersion> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = widget.service.fetchVersion();
  }

  void _reload() {
    setState(() {
      _versionFuture = widget.service.fetchVersion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart Finder'),
        actions: [
          IconButton(
            tooltip: 'Reload backend version',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<BackendVersion>(
          future: _versionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _CenteredProgress();
            }

            if (snapshot.hasError) {
              return _ErrorView(
                error: snapshot.error,
                onRetry: _reload,
              );
            }

            final backendVersion = snapshot.data;
            if (backendVersion == null) {
              return _ErrorView(
                error: const FormatException('No payload returned from backend.'),
                onRetry: _reload,
              );
            }

            final expectedApiVersion = versionInfo.backendApiVersion;
            final expectedBuild = versionInfo.backendApiBuildNumber;
            final backendBuildNumber = backendVersion.buildNumber ?? '';

            final versionMismatch = expectedApiVersion.isNotEmpty &&
                backendVersion.version != expectedApiVersion;
            final buildMismatch = expectedBuild.isNotEmpty &&
                backendBuildNumber.isNotEmpty &&
                backendBuildNumber != expectedBuild;

            final children = <Widget>[];

            if (versionMismatch || buildMismatch) {
              children.add(
                _WarningCard(
                  versionMismatch: versionMismatch,
                  buildMismatch: buildMismatch,
                  backendVersion: backendVersion.version,
                  expectedVersion: expectedApiVersion,
                  backendBuild: backendBuildNumber,
                  expectedBuild: expectedBuild,
                ),
              );
              children.add(const SizedBox(height: 16));
            }

            children.addAll([
              _SectionHeader(title: 'App Version'),
              Card(
                child: ListTile(
                  title: Text(versionInfo.productName),
                  subtitle: Text('Frontend build ${versionInfo.buildNumber}'),
                  trailing: Text(versionInfo.version),
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Backend Version'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(backendVersion.product),
                      subtitle: Text(backendVersion.description),
                      trailing: Text(backendVersion.version),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      title: const Text('Branch'),
                      trailing: Text(backendVersion.branch ?? 'unknown'),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      title: const Text('Build number'),
                      trailing: Text(backendVersion.buildNumber ?? 'n/a'),
                    ),
                  ],
                ),
              ),
            ]);

            return ListView(children: children);
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(
            'Unable to reach backend',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? 'Unknown error',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.versionMismatch,
    required this.buildMismatch,
    required this.backendVersion,
    required this.expectedVersion,
    required this.backendBuild,
    required this.expectedBuild,
  });

  final bool versionMismatch;
  final bool buildMismatch;
  final String backendVersion;
  final String expectedVersion;
  final String? backendBuild;
  final String expectedBuild;

  @override
  Widget build(BuildContext context) {
    final details = <String>[];
    if (versionMismatch) {
      details.add('Backend reports $backendVersion but client expects $expectedVersion.');
    }
    if (buildMismatch) {
      details.add('Backend build ${backendBuild ?? 'unknown'} differs from spec $expectedBuild.');
    }

    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: const Text('API version mismatch'),
        subtitle: Text(details.join('\n')),
      ),
    );
  }
}

class VersionService {
  VersionService({String? baseUrlOverride})
      : _utilsApi = UtilsApi(
          Dio(
            BaseOptions(
              baseUrl: _normalizeBaseUrl(baseUrlOverride),
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          ),
        );

  final UtilsApi _utilsApi;

  Future<BackendVersion> fetchVersion() async {
    final response = await _utilsApi.utilsGetVersion();
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Backend returned an empty payload.');
    }

    final decoded = utf8.decode(bytes);
    final data = jsonDecode(decoded) as Map<String, dynamic>;
    return BackendVersion.fromJson(data);
  }

  static String _normalizeBaseUrl(String? value) {
    var sanitized = value?.trim();
    sanitized = (sanitized == null || sanitized.isEmpty)
        ? versionInfo.apiBaseUrl
        : sanitized;

    sanitized = (sanitized.isEmpty ? 'https://sab-u-dev-api.chart-finder.app' : sanitized);

    return sanitized.endsWith('/')
        ? sanitized.substring(0, sanitized.length - 1)
        : sanitized;
  }
}

class BackendVersion {
  const BackendVersion({
    required this.product,
    required this.version,
    required this.description,
    this.branch,
    this.comment,
    this.buildNumber,
  });

  final String product;
  final String version;
  final String description;
  final String? branch;
  final String? comment;
  final String? buildNumber;

  factory BackendVersion.fromJson(Map<String, dynamic> json) {
    return BackendVersion(
      product: json['product'] as String? ?? 'Chart Finder API',
      version: json['version'] as String? ?? 'unknown',
      description: json['description'] as String? ?? '',
      branch: json['branch'] as String?,
      comment: json['comment'] as String?,
      buildNumber: json['buildNumber'] as String?,
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:super_selectos/services/android_platform_version.dart';

class AppUpdateManifest {
  const AppUpdateManifest({
    required this.version,
    required this.apkUrls,
    required this.changelog,
  });

  final String version;
  final Map<String, String> apkUrls;
  final String changelog;

  factory AppUpdateManifest.fromJson(Map<String, dynamic> json) {
    final version = json['version']?.toString().trim() ?? '';
    final changelog = json['changelog']?.toString().trim() ?? '';
    final rawUrls = json['apk_urls'];
    if (version.isEmpty || rawUrls is! Map<String, dynamic>) {
      throw const FormatException('El archivo de actualización no es válido.');
    }

    final urls = <String, String>{};
    for (final entry in rawUrls.entries) {
      final url = _normalizeUrl(entry.value?.toString() ?? '');
      if (url.isNotEmpty) urls[entry.key] = url;
    }
    if (urls.isEmpty) {
      throw const FormatException('No hay APK disponibles en el manifiesto.');
    }

    return AppUpdateManifest(
      version: version,
      apkUrls: urls,
      changelog: changelog,
    );
  }

  static String _normalizeUrl(String value) {
    final trimmed = value.trim();
    final markdownUrl = RegExp(r'^\[[^\]]*\]\((https?://[^)]+)\)$')
        .firstMatch(trimmed);
    return markdownUrl?.group(1) ?? trimmed;
  }
}

class AppUpdateCheck {
  const AppUpdateCheck({
    required this.installedVersion,
    required this.manifest,
    required this.abi,
    required this.downloadUrl,
  });

  final String installedVersion;
  final AppUpdateManifest manifest;
  final String abi;
  final String downloadUrl;

  bool get updateAvailable =>
      AppUpdateService.compareVersions(manifest.version, installedVersion) > 0;
}

class AppUpdateService {
  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri manifestUri = Uri.parse(
    'https://raw.githubusercontent.com/KirbyNx64/Selectos-Prices/'
    'main/updates/latest.json',
  );

  final http.Client _client;

  Future<AppUpdateCheck> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Las actualizaciones OTA solo están disponibles en Android.',
      );
    }

    final installedVersion = AndroidPlatformVersion.appVersion;
    if (installedVersion == null || installedVersion.isEmpty) {
      throw StateError('No se pudo obtener la versión instalada.');
    }

    final requestUri = manifestUri.replace(
      queryParameters: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
    );
    final response = await _client
        .get(requestUri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError(
        'GitHub respondió con el código ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El manifiesto de actualización no es válido.',
      );
    }
    final manifest = AppUpdateManifest.fromJson(decoded);
    final abi = _selectAbi(manifest.apkUrls);
    final downloadUrl = manifest.apkUrls[abi];
    if (downloadUrl == null || !Uri.parse(downloadUrl).isScheme('https')) {
      throw StateError('No hay un APK compatible con este dispositivo ($abi).');
    }

    return AppUpdateCheck(
      installedVersion: installedVersion,
      manifest: manifest,
      abi: abi,
      downloadUrl: downloadUrl,
    );
  }

  String _selectAbi(Map<String, String> apkUrls) {
    for (final abi in AndroidPlatformVersion.supportedAbis) {
      if (apkUrls.containsKey(abi)) return abi;
    }
    if (apkUrls.containsKey('universal')) return 'universal';
    throw StateError(
      'Arquitectura no compatible: '
      '${AndroidPlatformVersion.supportedAbis.join(', ')}.',
    );
  }

  Stream<OtaEvent> install(AppUpdateCheck update) {
    final filename = Uri.parse(update.downloadUrl).pathSegments.last;
    return OtaUpdate().execute(
      update.downloadUrl,
      destinationFilename: filename.isEmpty
          ? 'selectos-prices-${update.manifest.version}-${update.abi}.apk'
          : filename,
    );
  }

  void dispose() => _client.close();

  static int compareVersions(String left, String right) {
    final leftParts = _numericVersion(left);
    final rightParts = _numericVersion(right);
    final length = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;
    for (var i = 0; i < length; i++) {
      final leftValue = i < leftParts.length ? leftParts[i] : 0;
      final rightValue = i < rightParts.length ? rightParts[i] : 0;
      final comparison = leftValue.compareTo(rightValue);
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  static List<int> _numericVersion(String version) {
    final normalized = version
        .trim()
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split(RegExp(r'[-+]'))
        .first;
    return normalized
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
  }
}

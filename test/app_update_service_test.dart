import 'package:flutter_test/flutter_test.dart';
import 'package:super_selectos/services/app_update_service.dart';

void main() {
  test('compares release versions numerically', () {
    expect(AppUpdateService.compareVersions('2.2.5', '2.2.4'), isPositive);
    expect(AppUpdateService.compareVersions('v2.2.5', '2.2.5+10'), 0);
    expect(AppUpdateService.compareVersions('1.9.9', '2.0.0'), isNegative);
  });

  test('parses ABI URLs and changelog from the GitHub manifest', () {
    final manifest = AppUpdateManifest.fromJson({
      'version': '2.2.5',
      'apk_urls': {
        'arm64-v8a': '[APK](https://github.com/example/app/releases/download/v2.2.5/app.apk)',
      },
      'changelog': '• Mejoras generales.',
    });

    expect(manifest.version, '2.2.5');
    expect(
      manifest.apkUrls['arm64-v8a'],
      'https://github.com/example/app/releases/download/v2.2.5/app.apk',
    );
    expect(manifest.changelog, '• Mejoras generales.');
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:durus/models/models.dart';

void main() {
  group('AppRelease.fromJson (app_meta)', () {
    test('parses version/url/notes/apk_url', () {
      final r = AppRelease.fromJson({
        'version': '1.1.3',
        'url': 'https://github.com/amworx/durus/releases/tag/v1.1.3',
        'notes': 'تحديث تجريبي',
        'apk_url': 'https://example.com/durus.apk',
      });
      expect(r.version, '1.1.3');
      expect(r.url, contains('v1.1.3'));
      expect(r.notes, 'تحديث تجريبي');
      expect(r.apkUrl, 'https://example.com/durus.apk');
    });

    test('apk_url is nullable and missing fields default safely', () {
      final r = AppRelease.fromJson(const {});
      expect(r.version, '');
      expect(r.url, '');
      expect(r.notes, '');
      expect(r.apkUrl, isNull);
    });
  });

  group('AppRelease.fromGitHubJson (Releases API)', () {
    Map<String, dynamic> gitHubJson({List<dynamic>? assets}) => {
          'tag_name': 'v1.1.3',
          'html_url': 'https://github.com/amworx/durus/releases/tag/v1.1.3',
          'body': 'الإصدار الجديد\n- ميزة التحديث داخل التطبيق',
          'assets': assets ?? const [],
        };

    test('strips the leading v from the tag', () {
      final r = AppRelease.fromGitHubJson(gitHubJson());
      expect(r.version, '1.1.3');
      expect(r.url, contains('v1.1.3'));
      expect(r.apkUrl, isNull);
    });

    test('prefers the arm64 APK asset', () {
      final r = AppRelease.fromGitHubJson(gitHubJson(assets: [
        {
          'name': 'app-armeabi-v7a-release.apk',
          'browser_download_url':
              'https://github.com/amworx/durus/releases/download/v1.1.3/app-armeabi-v7a-release.apk',
        },
        {
          'name': 'app-arm64-v8a-release.apk',
          'browser_download_url':
              'https://github.com/amworx/durus/releases/download/v1.1.3/app-arm64-v8a-release.apk',
        },
      ]));
      expect(r.apkUrl, endsWith('app-arm64-v8a-release.apk'));
    });

    test('falls back to any .apk asset when no arm64 exists', () {
      final r = AppRelease.fromGitHubJson(gitHubJson(assets: [
        {
          'name': 'app-x86_64-release.apk',
          'browser_download_url':
              'https://github.com/amworx/durus/releases/download/v1.1.3/app-x86_64-release.apk',
        },
      ]));
      expect(r.apkUrl, endsWith('app-x86_64-release.apk'));
    });

    test('ignores non-apk assets', () {
      final r = AppRelease.fromGitHubJson(gitHubJson(assets: [
        {'name': 'durus-sha256.txt', 'browser_download_url': 'https://x/checksum'},
      ]));
      expect(r.apkUrl, isNull);
    });
  });
}
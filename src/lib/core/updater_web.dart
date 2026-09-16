// Durus — in-app updater, web stub.
//
// The web portal never downloads or installs APKs: the Settings screen falls
// back to opening the release page. The GitHub Releases API is also skipped
// on web (no dart:io); `app_meta` remains the single source there.
import '../models/models.dart';
import 'updater.dart' show InstallResult;

Future<AppRelease?> fetchLatestGitHubRelease() async => null;

Future<String?> downloadApk({
  required String url,
  required String fileName,
  required void Function(double progress) onProgress,
}) async => null;

Future<InstallResult> triggerApkInstall(String path) async =>
    const InstallResult(status: 'failed');

Future<void> openDownloadsFolder() async {}
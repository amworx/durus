// Durus — in-app updater.
//
// Cross-platform facade over the update download/install logic:
//   - `updater_io.dart`  — real implementation for Android / desktop
//     (dart:io HttpClient download into the app cache + MethodChannel
//     install via the system package installer).
//   - `updater_web.dart` — web stubs (the web portal never installs APKs;
//     it falls back to opening the release page).
//
// These files are also where the GitHub Releases API is queried, because the
// request needs dart:io on native platforms and there is no direct `http`
// dependency.
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'updater_io.dart' if (dart.library.html) 'updater_web.dart' as impl;

/// Fetches the latest release from the GitHub Releases API
/// (`/repos/amworx/durus/releases/latest`). Returns null on web or when the
/// request/parse fails (callers fall back to `app_meta` metadata).
Future<AppRelease?> fetchLatestGitHubRelease() =>
    impl.fetchLatestGitHubRelease();

/// Downloads an APK to the app's cache (`cache/updates/`, exposed to the
/// system installer via a FileProvider `<cache-path>`).
///
/// [onProgress] is called with a value in `[0, 1]` as bytes arrive and with
/// `1.0` on completion. Returns the absolute file path on success, or null
/// when in-app download is unsupported (web).
Future<String?> downloadApk({
  required String url,
  required String fileName,
  required void Function(double progress) onProgress,
}) {
  return impl.downloadApk(
    url: url,
    fileName: fileName,
    onProgress: onProgress,
  );
}

/// Asks the OS package installer to install the downloaded APK at [path]
/// (FileProvider-backed `ACTION_VIEW` intent). Returns true when the intent
/// was launched; false on web/desktop or when no installer could be started.
Future<bool> triggerApkInstall(String path) => impl.triggerApkInstall(path);

/// True when [kIsWeb] — used by Settings to pick the in-app download path
/// vs. the open-release-page fallback.
bool get canDownloadInApp => !kIsWeb;
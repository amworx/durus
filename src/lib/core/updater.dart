// Durus — in-app updater.
//
// Cross-platform facade over the update download/install logic:
//   - `updater_io.dart`  — real implementation for Android / desktop
//     (dart:io HttpClient download into the app-private cache provided by
//     the native side + MethodChannel install via the system package
//     installer, with an export-to-Downloads fallback).
//   - `updater_web.dart` — web stubs (the web portal never installs APKs;
//     it falls back to opening the release page).
//
// These files are also where the GitHub Releases API is queried, because the
// request needs dart:io on native platforms and there is no direct `http`
// dependency.
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'updater_io.dart' if (dart.library.html) 'updater_web.dart' as impl;

/// Outcome of a `triggerApkInstall` attempt.
class InstallResult {
  /// One of: `installed` (installer launched), `exported` (installer could
  /// not be addressed, APK copied to a user-visible Downloads location),
  /// `failed` (nothing worked / unsupported platform).
  final String status;

  /// Human-readable location for `exported` results (e.g. `Downloads/xxx.apk`).
  final String? message;

  const InstallResult({required this.status, this.message});

  bool get didLaunchInstaller => status == 'installed';
  bool get wasExported => status == 'exported';
}

/// Fetches the latest release from the GitHub Releases API
/// (`/repos/amworx/durus/releases/latest`). Returns null on web or when the
/// request/parse fails (callers fall back to `app_meta` metadata).
Future<AppRelease?> fetchLatestGitHubRelease() =>
    impl.fetchLatestGitHubRelease();

/// Downloads an APK into the app-private `cache/updates/` directory (the
/// directory reported by the native channel — NOT `Directory.systemTemp`,
/// which on Android can resolve outside the FileProvider `<cache-path>` and
/// outside user-visible storage; that was the v1.1.4 "cannot update" bug).
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
/// (FileProvider-backed `ACTION_VIEW` intent). When the installer cannot be
/// addressed the native side exports the APK to user-visible Downloads and
/// reports `exported` so the UI can guide the user to the file.
Future<InstallResult> triggerApkInstall(String path) =>
    impl.triggerApkInstall(path);

/// Opens the system Files/Downloads app so the user can find an exported APK.
Future<void> openDownloadsFolder() => impl.openDownloadsFolder();

/// True when [kIsWeb] — used by Settings to pick the in-app download path
/// vs. the open-release-page fallback.
bool get canDownloadInApp => !kIsWeb;
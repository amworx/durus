// Durus — in-app updater, native (IO) implementation.
//
// Implements the updater facade for Android/desktop where dart:io is
// available: downloads the APK with dart:io HttpClient (no `http` package
// dependency) into the app-private cache directory REPORTED by the native
// channel (`MainActivity.getDownloadDir`), reports progress, and hands the
// file to the `durus/installer` MethodChannel so the system package installer
// can consume it via a FileProvider URI. If the installer cannot be opened,
// the native side exports the APK to user-visible Downloads and the result
// tells the UI where it went.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/models.dart';
import 'updater.dart' show InstallResult;

const MethodChannel _installerChannel = MethodChannel('durus/installer');

const String _githubApi =
    'https://api.github.com/repos/amworx/durus/releases/latest';

/// Fetches the latest release from GitHub. Throws on failure — the caller
/// (`DurusApi.latestRelease`) falls back to `app_meta` metadata.
Future<AppRelease?> fetchLatestGitHubRelease() async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse(_githubApi))
        .timeout(const Duration(seconds: 8));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'Durus/updater');
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GitHub API HTTP ${response.statusCode}',
          uri: Uri.parse(_githubApi));
    }
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 8));
    final json = jsonDecode(body) as Map<String, dynamic>;
    return AppRelease.fromGitHubJson(json);
  } finally {
    client.close(force: true);
  }
}

/// Returns the app-private update directory from the native channel
/// (`<cacheDir>/updates` on Android). Falls back to `Directory.systemTemp`
/// when the channel is unavailable (desktop; rare) — note systemTemp is the
/// ORIGINAL v1.1.4 bug source on Android and must not be relied on there.
Future<String> _getDownloadDir() async {
  try {
    final dir = await _installerChannel.invokeMethod<String>('getDownloadDir');
    if (dir != null && dir.isNotEmpty) return dir;
  } on PlatformException {
    // fall through
  } on MissingPluginException {
    // fall through
  }
  return '${Directory.systemTemp.path}${Platform.pathSeparator}updates';
}

/// Downloads [url] into `<cache>/updates/<fileName>` and reports progress to
/// [onProgress] (`0..1`, finishing at `1.0`). Returns the absolute path.
Future<String?> downloadApk({
  required String url,
  required String fileName,
  required void Function(double progress) onProgress,
}) async {
  final dir = Directory(await _getDownloadDir());
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    request.followRedirects = true;
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Download HTTP ${response.statusCode}',
          uri: Uri.parse(url));
    }

    final total = response.contentLength;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (received == 0) {
      throw const SocketException('Empty download');
    }
    onProgress(1);
    return file.path;
  } finally {
    client.close(force: true);
  }
}

/// Launches the system package installer for [path] via the native channel.
/// Returns an [InstallResult]: `installed` when the installer intent was
/// launched, `exported` when the native side copied the APK to user-visible
/// Downloads instead, or `failed` when neither worked.
Future<InstallResult> triggerApkInstall(String path) async {
  try {
    final result =
        await _installerChannel.invokeMapMethod<String, dynamic>(
      'installApk',
      {'path': path},
    );
    final status = result?['status'] as String? ?? 'failed';
    return InstallResult(
      status: status,
      message: result?['message'] as String?,
    );
  } on PlatformException {
    return const InstallResult(status: 'failed');
  } on MissingPluginException {
    return const InstallResult(status: 'failed');
  }
}

/// Opens the system Files/Downloads app (native side; no-op on failure).
Future<void> openDownloadsFolder() async {
  try {
    await _installerChannel.invokeMethod('openDownloadsFolder');
  } on PlatformException {
    // best effort
  } on MissingPluginException {
    // best effort
  }
}
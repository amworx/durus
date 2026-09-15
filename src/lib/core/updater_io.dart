// Durus — in-app updater, native (IO) implementation.
//
// Implements the updater facade for Android/desktop where dart:io is
// available: downloads the APK into the app cache with dart:io HttpClient
// (no `http` package dependency), reports progress, and hands the file to
// the Android MainActivity MethodChannel (`durus/installer`) so the system
// package installer can consume it via a FileProvider URI.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/models.dart';

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

/// Downloads [url] into `<cache>/updates/<fileName>` and reports progress to
/// [onProgress] (`0..1`, finishing at `1.0`). Returns the absolute path.
Future<String?> downloadApk({
  required String url,
  required String fileName,
  required void Function(double progress) onProgress,
}) async {
  final dir = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}updates');
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
/// Returns false when the channel is unavailable or the intent failed.
Future<bool> triggerApkInstall(String path) async {
  try {
    final ok =
        await _installerChannel.invokeMethod<bool>('installApk', {'path': path});
    return ok ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
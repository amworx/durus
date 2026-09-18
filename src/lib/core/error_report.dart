import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

/// Client error reporting: append-only `client_errors` rows the owner reads
/// from the dashboard. Exists so the next "error with no details" arrives
/// with its server message attached.
///
/// Rules: never throws, never blocks, never reports unattributable
/// (signed-out) failures, and throttles repeats (same message at most once
/// per 5 minutes, 20 reports per launch) so a looping bug can't flood the
/// table or burn the user's data.

final Map<String, DateTime> _lastReport = {};
int _reportsThisLaunch = 0;

@visibleForTesting
const int maxErrorReportsPerLaunch = 20;

@visibleForTesting
const Duration errorReportMinInterval = Duration(minutes: 5);

@visibleForTesting
void resetErrorReportThrottle() {
  _lastReport.clear();
  _reportsThisLaunch = 0;
}

/// Check-and-reserve: true when this key may be reported now (marks the
/// slot, so a repeated call for the same key is denied until the interval
/// passes). Pure apart from the static throttle buckets.
@visibleForTesting
bool shouldReportError(String key, {DateTime? now}) {
  final at = now ?? DateTime.now();
  if (_reportsThisLaunch >= maxErrorReportsPerLaunch) {
    return false;
  }
  final last = _lastReport[key];
  if (last != null && at.difference(last) < errorReportMinInterval) {
    return false;
  }
  _lastReport[key] = at;
  _reportsThisLaunch++;
  return true;
}

@visibleForTesting
String truncateErrorText(String s, int max) =>
    s.length <= max ? s : s.substring(0, max);

/// Fire-and-forget report. Safe to call from anywhere, including error
/// paths — it swallows its own failures. [screen] names the area
/// ('owner', 'auth'); null for uncaught framework errors.
Future<void> reportClientError(
  Object error, {
  String? screen,
  String? stack,
}) async {
  try {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      return;
    }
    final message = truncateErrorText(error.toString(), 500);
    if (!shouldReportError('${screen ?? ''}::$message')) {
      return;
    }
    await Supabase.instance.client.from('client_errors').insert({
      'user_id': uid,
      'app_version': AppConfig.appVersion,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'screen': (screen ?? '').trim(),
      'message': message,
      'stack': truncateErrorText(stack ?? '', 2000),
    });
  } catch (_) {
    // Telemetry never breaks the app.
  }
}

/// Captures uncaught framework and async errors. Call once at startup.
void installErrorReporting() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reportClientError(
      details.exception,
      stack: details.stack?.toString(),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reportClientError(error, stack: stack.toString());
    return true;
  };
}

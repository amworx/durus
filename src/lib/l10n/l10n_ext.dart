import 'package:flutter/widgets.dart';
import 'package:durus/l10n/app_localizations.dart';

/// Convenience accessor for generated [AppLocalizations].
///
/// gen-l10n (Flutter 3.44) does not emit a BuildContext extension, so we
/// define it once here. Files using `context.l10n` import this file.
extension L10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The only supported locale in the Durus app.
const Locale kDurusLocale = Locale('ar');
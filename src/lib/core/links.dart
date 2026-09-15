// Durus — external link helpers (WhatsApp deep links, URL opening).
//
// WhatsApp is the primary teacher<->parent channel, so every parent-facing
// action goes through a wa.me deep link that pre-fills a message.
import 'package:url_launcher/url_launcher.dart';

/// Normalizes a phone number to international digits usable in wa.me links.
///
/// Accepts: '09xx xxx xxx' (Syrian mobile -> 9639xx...), '+963...',
/// '00963...', or bare digits. Returns '' when nothing usable remains.
String waNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = '963${digits.substring(1)}';
  return digits;
}

/// wa.me deep link. [text] becomes the pre-filled message when provided.
/// Returns '' when the phone cannot be normalized.
String waChatLink(String phone, {String? text}) {
  final number = waNumber(phone);
  if (number.isEmpty) return '';
  final query = (text == null || text.isEmpty)
      ? ''
      : '?text=${Uri.encodeQueryComponent(text)}';
  return 'https://wa.me/$number$query';
}

/// Opens an external URL (browser / WhatsApp / download manager).
/// `platformDefault` keeps Android and web behaviour consistent: https URLs
/// resolve to the default browser (and WhatsApp handles wa.me when installed).
Future<bool> openExternal(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
}
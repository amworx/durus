// Deterministic teacher avatars via the free Avatune REST API (no key).
//
// The same seed always renders the same character, so every teacher gets
// a stable auto-generated avatar with zero uploads and zero storage:
// `seed` defaults to the teacher's profile id. Set `gender` to 'm'/'f'
// to render the matching character (pawel-olek-man/woman); null keeps
// the picked neutral style. PNG is used so plain `Image.network` renders
// it with no extra packages.

/// Neutral styles offered in the in-app picker.
const List<String> kAvatarThemes = ['fatin-verse', 'yanliu', 'micah'];

/// Fallback when a stored theme is unknown.
const String kDefaultAvatarTheme = 'fatin-verse';

/// Resolves the Avatune theme for a (style, gender) pair: gender wins.
String resolveAvatarTheme({String? theme, String? gender}) {
  if (gender == 'm') return 'pawel-olek-man';
  if (gender == 'f') return 'pawel-olek-woman';
  if (theme != null && kAvatarThemes.contains(theme)) return theme;
  return kDefaultAvatarTheme;
}

/// Full avatar image URL. [seed] must already be the effective seed
/// (custom shuffle seed, else the profile id).
String teacherAvatarUrl({
  required String seed,
  String? theme,
  String? gender,
  int size = 200,
}) {
  final t = resolveAvatarTheme(theme: theme, gender: gender);
  final s = seed.isEmpty ? 'teacher' : seed;
  final q = Uri.encodeQueryComponent(s);
  final px = size.clamp(64, 512);
  return 'https://www.avatune.dev/api/png/?theme=$t&seed=$q&size=$px';
}

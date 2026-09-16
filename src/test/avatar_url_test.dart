import 'package:durus/core/avatar_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('avatar urls', () {
    test('neutral theme passes through, unknown falls back', () {
      expect(resolveAvatarTheme(theme: 'yanliu'), 'yanliu');
      expect(resolveAvatarTheme(theme: 'micah'), 'micah');
      expect(resolveAvatarTheme(theme: 'nope'), 'fatin-verse');
      expect(resolveAvatarTheme(), 'fatin-verse');
    });

    test('gender overrides the picked style', () {
      expect(
        resolveAvatarTheme(theme: 'micah', gender: 'm'),
        'pawel-olek-man',
      );
      expect(
        resolveAvatarTheme(theme: 'micah', gender: 'f'),
        'pawel-olek-woman',
      );
    });

    test('teacherAvatarUrl encodes seed and clamps size', () {
      expect(
        teacherAvatarUrl(seed: 'p1', theme: 'yanliu', size: 200),
        'https://www.avatune.dev/api/png/?theme=yanliu&seed=p1&size=200',
      );
      expect(teacherAvatarUrl(seed: ''), contains('seed=teacher'));
      expect(teacherAvatarUrl(seed: 'a b'), contains('seed=a+b'));
      expect(
        teacherAvatarUrl(seed: 'p1', size: 9999),
        contains('size=512'),
      );
    });
  });
}

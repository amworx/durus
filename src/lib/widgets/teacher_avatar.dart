import 'package:flutter/material.dart';

import 'package:durus/core/avatar_url.dart';

/// Auto-generated teacher avatar: an Avatune character (deterministic per
/// seed) inside a gradient ring with a soft glow — the Uiverse-gradient-ring
/// idea rebuilt natively in Flutter. Falls back to a designed initial
/// letter when offline or while loading. No new packages: plain
/// `Image.network` over the PNG endpoint.
class TeacherAvatar extends StatelessWidget {
  const TeacherAvatar({
    super.key,
    required this.seed,
    this.theme,
    this.gender,
    this.fallbackLabel = '?',
    this.size = 40,
    this.showStatusDot = false,
    this.active = true,
  });

  /// Effective avatar seed (custom shuffle seed, else the profile id).
  final String seed;

  /// Neutral style key; ignored when [gender] is 'm'/'f'.
  final String? theme;

  /// 'm' | 'f' | null (null = neutral style).
  final String? gender;

  /// Letter shown while loading / offline.
  final String fallbackLabel;

  /// Diameter of the image itself (ring adds ~6px around it).
  final double size;

  /// Pulsing presence dot (Eldora-badge effect) on the ring edge.
  final bool showStatusDot;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fb = fallbackLabel.trim().isEmpty
        ? '?'
        : fallbackLabel.trim().characters.first;
    final px = (size * 3).clamp(96, 512).toInt();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFF0E7C66),
                Color(0xFF12A083),
                Color(0xFFE8622B),
                Color(0xFF0E7C66),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x550E7C66),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox.square(
              dimension: size,
              child: Image.network(
                teacherAvatarUrl(
                  seed: seed,
                  theme: theme,
                  gender: gender,
                  size: px,
                ),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : _Fallback(scheme: scheme, letter: fb, size: size),
                errorBuilder: (context, error, stack) =>
                    _Fallback(scheme: scheme, letter: fb, size: size),
              ),
            ),
          ),
        ),
        if (showStatusDot)
          Positioned(
            bottom: 1,
            right: 1,
            child: PulseDot(active: active),
          ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.scheme,
    required this.letter,
    required this.size,
  });

  final ColorScheme scheme;
  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// Eldora-style animated badge dot: a solid core with an expanding,
/// fading ring. Static grey when [active] is false.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.active = true});

  final bool active;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? const Color(0xFF2E7D32)
        : const Color(0xFF78909C);
    return SizedBox.square(
      dimension: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active)
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.6).animate(
                CurvedAnimation(parent: _c, curve: Curves.easeOut),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0).animate(_c),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
              ),
            ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

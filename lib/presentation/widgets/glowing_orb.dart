import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../bloc/chat_state.dart';

/// The central glowing audio orb. Pulses gently when active and glows in a
/// state-specific colour:
/// Idle -> slate | Listening -> cyan | Processing -> purple | Speaking -> green.
class GlowingOrb extends StatefulWidget {
  const GlowingOrb({
    super.key,
    required this.status,
    required this.onTap,
  });

  final ChatStatus status;
  final VoidCallback onTap;

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _diameter = 190;

  bool get _isActive =>
      widget.status == ChatStatus.listening ||
      widget.status == ChatStatus.processing ||
      widget.status == ChatStatus.speaking;

  Color get _orbColor {
    switch (widget.status) {
      case ChatStatus.listening:
        return AppTheme.accentCyan;
      case ChatStatus.processing:
        return AppTheme.accentPurple;
      case ChatStatus.speaking:
        return AppTheme.accentGreen;
      case ChatStatus.idle:
      case ChatStatus.loading:
        return AppTheme.textSecondary;
    }
  }

  IconData get _orbIcon {
    switch (widget.status) {
      case ChatStatus.listening:
        return Icons.mic_rounded;
      case ChatStatus.speaking:
        return Icons.graphic_eq_rounded;
      case ChatStatus.processing:
      case ChatStatus.idle:
      case ChatStatus.loading:
        return Icons.mic_none_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (_isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GlowingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!_isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double t = Curves.easeInOut.transform(_controller.value);
          final double scale = _isActive ? 1.0 + 0.07 * t : 1.0;
          final double glowStrength =
              _isActive ? 26.0 + 22.0 * t : 12.0 + 4.0 * t;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: _diameter,
              height: _diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    _orbColor.withValues(alpha: 0.35),
                    AppTheme.surfaceHigh.withValues(alpha: 0.95),
                    AppTheme.surface,
                  ],
                  stops: const <double>[0.0, 0.65, 1.0],
                ),
                border: Border.all(
                  color: _orbColor.withValues(alpha: 0.85),
                  width: 2.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _orbColor.withValues(alpha: 0.45),
                    blurRadius: glowStrength,
                    spreadRadius: _isActive ? 6.0 * t : 1.0,
                  ),
                  BoxShadow(
                    color: _orbColor.withValues(alpha: 0.18),
                    blurRadius: glowStrength * 2,
                    spreadRadius: _isActive ? 14.0 * t : 2.0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: widget.status == ChatStatus.processing
                  ? SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: _orbColor,
                      ),
                    )
                  : Icon(
                      _orbIcon,
                      size: 64,
                      color: _orbColor,
                    ),
            ),
          );
        },
      ),
    );
  }
}

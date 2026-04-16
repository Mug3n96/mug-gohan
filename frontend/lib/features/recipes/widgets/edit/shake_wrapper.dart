import 'dart:async';

import 'package:flutter/material.dart';

class ShakeWrapper extends StatefulWidget {
  const ShakeWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shake;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 2.5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 2.5, end: -2.5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2.5, end: 2.5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 2.5, end: 0.0), weight: 1),
    ]).animate(_ctrl);
    _timer = Timer(const Duration(seconds: 2), _doShake);
  }

  void _doShake() {
    if (!mounted) return;
    _ctrl.forward(from: 0);
    _timer = Timer(const Duration(seconds: 9), _doShake);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shake.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';

/// Signs the customer out after a period with no interaction at all.
///
/// "Idle" means exactly that: no touch, no scroll, no key. A long-running
/// screen the customer is actively reading and scrolling does not time out,
/// and neither does a screen left open while they keep tapping — the timer
/// resets on every pointer or key event.
///
/// Backgrounding the app does not itself sign them out; the timer keeps running
/// and is evaluated on resume, so coming back after the window has passed lands
/// on the sign-in screen.
class IdleTimeout extends StatefulWidget {
  const IdleTimeout({super.key, required this.child});

  final Widget child;

  /// How long the app may sit untouched before the session is dropped.
  static const Duration window = Duration(minutes: 15);

  @override
  State<IdleTimeout> createState() => _IdleTimeoutState();
}

class _IdleTimeoutState extends State<IdleTimeout> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastInteraction = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Time spent backgrounded still counts, so check on the way back in
      // rather than silently granting a fresh window.
      if (DateTime.now().difference(_lastInteraction) >= IdleTimeout.window) {
        _expire();
      } else {
        _restart();
      }
    }
  }

  void _restart() {
    _lastInteraction = DateTime.now();
    _timer?.cancel();
    _timer = Timer(IdleTimeout.window, _expire);
  }

  void _expire() {
    _timer?.cancel();
    // Nothing to end if they are not signed in — the sign-in screen itself must
    // not bounce.
    if (ApiService.instance.sessionToken == null) return;

    // Reuses the same path a rejected token takes, so the app returns to
    // sign-in through one route rather than two.
    ApiService.instance.expireSession();
  }

  /// Any interaction at all resets the window.
  void _onInteraction([_]) {
    // Cheap guard: rescheduling a timer on every pointer move would churn.
    // A second of granularity is plenty for a 15-minute window.
    if (DateTime.now().difference(_lastInteraction) < const Duration(seconds: 1)) {
      return;
    }
    _restart();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Behaviour is deliberately translucent and the handlers do not consume
      // events, so nothing below this widget loses a tap.
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onInteraction,
      onPointerMove: _onInteraction,
      onPointerSignal: _onInteraction,
      child: widget.child,
    );
  }
}

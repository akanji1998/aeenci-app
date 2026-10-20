import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/screen_brightness_service.dart';

/// Luminosité au maximum tant que [child] est réellement visible :
/// onglet affiché (`TickerMode`), écran au premier plan (pas d'écran
/// empilé par-dessus) et application active. Rétablie sinon.
class MaxBrightness extends ConsumerStatefulWidget {
  const MaxBrightness({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MaxBrightness> createState() => _MaxBrightnessState();
}

class _MaxBrightnessState extends ConsumerState<MaxBrightness>
    with WidgetsBindingObserver {
  bool _appActive = true;
  bool _maximized = false;
  late final ScreenBrightnessService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(screenBrightnessProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _update();
  }

  void _update() {
    final visible =
        _appActive &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (visible == _maximized) return;
    _maximized = visible;
    unawaited(visible ? _service.maximize() : _service.restore());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_maximized) unawaited(_service.restore());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

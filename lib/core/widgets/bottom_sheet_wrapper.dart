import 'package:flutter/material.dart';

/// A wrapper widget for [showModalBottomSheet] content that overrides tap-to-dismiss behavior.
/// By setting [isDismissible: false] on the sheet and wrapping the sheet content in this widget,
/// the sheet will ignore outside taps that occur within the first 500ms of being opened.
/// This prevents OS-level double-tap or simultaneous tap conflicts that immediately close bottom sheets on tablets.
class ResilientBottomSheetWrapper extends StatefulWidget {
  final Widget child;
  const ResilientBottomSheetWrapper({super.key, required this.child});

  @override
  State<ResilientBottomSheetWrapper> createState() => _ResilientBottomSheetWrapperState();
}

class _ResilientBottomSheetWrapperState extends State<ResilientBottomSheetWrapper> {
  late final DateTime _openedTime;

  @override
  void initState() {
    super.initState();
    _openedTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) {
        if (DateTime.now().difference(_openedTime) < const Duration(milliseconds: 500)) {
          debugPrint('DEBUG: Ignored outside tap on bottom sheet due to tablet gesture conflict protection.');
          return;
        }
        Navigator.of(context).pop();
      },
      child: widget.child,
    );
  }
}

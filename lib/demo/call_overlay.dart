import 'package:flutter/material.dart';

/* USAGE
Overlay который перекрывает нам основной экран

в виджете
  OverlayEntry callOverlay; // слой звонка

в initState
  // слой звонка
  showInCallOverlay(callOverlay, context);

*/

void showInCallOverlay(OverlayEntry overlayEntry, BuildContext context) {
  // В каждой страничке надо создать overlayEntry
  if (WidgetsBinding.instance == null) {
    print('--- WidgetsBindings.instance is null ---');
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final overlay = Overlay.of(context);
    overlayEntry = OverlayEntry(
      builder: (context) {
        return CallOverlay();
      }
    );

    overlay.insert(overlayEntry);
  });
}

class CallOverlay extends StatefulWidget {
  @override
  _CallOverlayState createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Text('TEST'),
    );
  }
}

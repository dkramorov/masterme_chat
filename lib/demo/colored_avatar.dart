import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  for (int i = 0; i < 12; i++) {

    String firstLetter = '$i'[0];
    Color randomColor =
        Colors.primaries[Random().nextInt(Colors.primaries.length)];
    print('$randomColor $firstLetter');

    CircleAvatar(
      backgroundColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
      child: Text('$i'[0]),
    );


  }
}

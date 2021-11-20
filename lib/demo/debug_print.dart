import 'package:flutter/material.dart';

void main() {
  String someSuperLongString = '.' * 1000;
  debugPrint(someSuperLongString, wrapWidth: 1024);
}
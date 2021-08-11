import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//8 (###) #-###-###
String phoneMaskHelper(String phone) {
  String newPhone = phone.replaceAll(RegExp('[^0-9]+'), '');
  int newPhoneLen = newPhone.length;
  String result = '';

  for (int i=0; i<newPhoneLen; i++) {
    if (i >= 11) {
      break;
    }
    if (i == 0) {
      result += newPhone[i];
    } else if (i <= 3) {
      if (i == 1) {
        result += ' (';
      }
      result += newPhone[i];
    } else if (i <= 4) {
      if (i == 4) {
        result += ') ';
      }
      result += newPhone[i];
    } else if (i <= 7) {
      if (i == 5) {
        result += '-';
      }
      result += newPhone[i];
    } else {
      if (i == 8) {
        result += '-';
      }
      result += newPhone[i];
    }
  }
  return result;
}

class PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int selectionIndexFromTheRight =
        newValue.text.length - newValue.selection.end;
    final String newString = phoneMaskHelper(newValue.text);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(
          offset: newString.length - selectionIndexFromTheRight),
    );
  }
}

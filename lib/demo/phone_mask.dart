import 'package:intl/intl.dart';

void main() {
  String phone = '8 (3952) 959-223'; 
  String newPhone = phone.replaceAll(RegExp('[^0-9]+'), '');
  int newPhoneLen = newPhone.length;

  //8 (###) #-###-###
  String firstDigit = '8';
  String prefix = '';
  String fifthDigit = '';
  String phonePart1 = '';
  String phonePart2 = '';
  for (int i=0; i<newPhoneLen; i++) {
    if (i >= 11) {
      return;
    }
    if (i == 0) {
      firstDigit = newPhone[i];
    } else if (i <= 3) {
      prefix += newPhone[i];
    } else if (i <= 4) {
      fifthDigit = newPhone[i];
    } else if (i <= 7) {
      phonePart1 += newPhone[i];
    } else {
      phonePart2 += newPhone[i];
    }
  }
  String result = firstDigit + " (" + prefix + ") " + fifthDigit + "-" + phonePart1 + "-" + phonePart2;
  print(result);
}

import 'package:intl/intl.dart';

/* Пример работы с датой */
void main() {
  DateTime now = DateTime.now();
  Duration threeDays = Duration(days: -3);
  DateTime threeDaysAgo = now.add(threeDays);
  print(now.toString());
  print(threeDaysAgo.toString());
}

/* Я сама была такою три дня тому назад */
DateTime threeDaysAgo() {
  DateTime now = DateTime.now();
  Duration threeDays = Duration(days: -3);
  return now.add(threeDays).toLocal();
}

/* Пример преобразования строки в дату и снова в строку в нужном формате */
String datetimeFromStr() {
  final DateFormat formatter = DateFormat('HH:mm');
  final now = DateTime.now().toIso8601String();
  final msgTime = formatter.format(DateTime.parse(now));
  return msgTime;
}
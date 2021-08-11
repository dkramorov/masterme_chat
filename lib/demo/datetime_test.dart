/* Пример работы с датой */
void main() {
  DateTime now = DateTime.now();
  Duration threeDays = Duration(days: -3);
  DateTime threeDaysAgo = now.add(threeDays);
  print(now.toString());
  print(threeDaysAgo.toString());
}

DateTime threeDaysAgo() {
  /* Я сама была такою три дня тому назад */
  DateTime now = DateTime.now();
  Duration threeDays = Duration(days: -3);
  return now.add(threeDays).toLocal();
}
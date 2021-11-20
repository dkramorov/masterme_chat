import 'dart:async';

void main() async {
  final elapser = Stopwatch();
  elapser.start();
  await Future.delayed(Duration(seconds: 2), () {
    print('delayed done');
  });
  print('elapsed ${elapser.elapsed.inMilliseconds}');
}

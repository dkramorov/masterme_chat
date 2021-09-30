import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masterme_chat/helpers/save_network_file.dart';
import 'package:record/record.dart';

class RecordWidget extends StatefulWidget {
  final Function handleAudioSelection;

  const RecordWidget({Key key, this.handleAudioSelection}) : super(key: key);

  @override
  _RecordWidgetState createState() => _RecordWidgetState();
}

class _RecordWidgetState extends State<RecordWidget> {

  String path;
  static const int maxDuration = 120;

  bool _isRecording;
  int _remainingDuration;
  Timer _timer;

  @override
  void initState() {
    _isRecording = false;
    _remainingDuration = maxDuration;
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /* Получение пути до аудио файла */
  Future<String> getPath() async {
    final String destFolder = await SaveNetworkFile.makeAppFolder();
    final String fullPath =
        destFolder + '/' + DateTime.now().millisecondsSinceEpoch.toString() + '.m4a';
    this.path = fullPath;
    return fullPath;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildControl(),
        SizedBox(width: 20),
        _buildText(),
      ],
    );
  }

  Widget _buildControl() {
    Icon icon;
    Color color;

    if (_isRecording) {
      icon = Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            if (_isRecording) {
              _stop();
            } else {
              _start();
            }
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_isRecording) {
      return _buildTimer();
    }

    return Text("Запись аудио сообщения");
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_remainingDuration ~/ 60);
    final String seconds = _formatNumber(_remainingDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0' + numberStr;
    }

    return numberStr;
  }

  Future<void> _start() async {
    try {
      await getPath();
      if (await Record.hasPermission()) {
        await Record.start(path: path);

        bool isRecording = await Record.isRecording();
        setState(() {
          _isRecording = isRecording;
          _remainingDuration = maxDuration;
        });

        _startTimer();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await Record.stop();

    setState(() {
      _isRecording = false;
      _remainingDuration = maxDuration;
    });

    widget.handleAudioSelection(path);
  }

  void _startTimer() {
    const tick = const Duration(milliseconds: 500);

    _timer?.cancel();

    _timer = Timer.periodic(tick, (Timer t) async {
      if (!_isRecording) {
        t.cancel();
      } else {
        setState(() {
          _remainingDuration = maxDuration - (t.tick / 2).floor();
        });

        if (_remainingDuration <= 0) {
          _stop();
        }
      }
    });
  }
}


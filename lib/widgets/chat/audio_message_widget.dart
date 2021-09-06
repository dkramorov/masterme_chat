import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart' as ap;

class AudioMessageWidget extends StatefulWidget {
  final String url;
  final File file;

  AudioMessageWidget({this.url, this.file});

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  static const String TAG = 'AudioWidget';

  static const double _controlSize = 56;

  final _audioPlayer = ap.AudioPlayer();
  ap.AudioPlayerState _status;
  Duration _duration;
  Duration _position;

  StreamSubscription<ap.AudioPlayerState> _stateChangedSubscription;
  StreamSubscription<Duration> _durationChangedSubscription;
  StreamSubscription<Duration> _positionChangedSubscription;
  StreamSubscription<String> _playerErrorSubscription;

  @override
  void dispose() {
    _stateChangedSubscription?.cancel();
    _durationChangedSubscription?.cancel();
    _positionChangedSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _status = ap.AudioPlayerState.STOPPED;

    _stateChangedSubscription =
        _audioPlayer.onPlayerStateChanged.listen(_onPlayerStateChanged);
    _durationChangedSubscription =
        _audioPlayer.onDurationChanged.listen(_onDurationChanged);
    _positionChangedSubscription =
        _audioPlayer.onAudioPositionChanged.listen(_onAudioPositionChanged);
    _playerErrorSubscription =
        _audioPlayer.onPlayerError.listen((error) => print(error));

    super.initState();
  }


  Widget _buildControl() {
    Icon icon;
    Color color;

    if (_status == ap.AudioPlayerState.PLAYING) {
      icon = Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.play_arrow, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child:
          SizedBox(width: _controlSize, height: _controlSize, child: icon),
          onTap: () {
            if (_status == ap.AudioPlayerState.PLAYING) {
              pause();
            } else if (_status == ap.AudioPlayerState.PAUSED) {
              resume();
            } else {
              play();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSlider() {
    bool canSetValue = false;
    if (_position != null && _duration != null) {
      canSetValue = _position.inMilliseconds > 0;
      canSetValue &= _position.inMilliseconds < _duration.inMilliseconds;
    }

    return SizedBox(
      child: Slider(
        activeColor: Theme.of(context).primaryColor,
        inactiveColor: Theme.of(context).accentColor,
        onChanged: (v) {
          if (_position != null) {
            final position = v * _duration.inMilliseconds;
            _audioPlayer.seek(Duration(milliseconds: position.round()));
          }
        },
        value: canSetValue
            ? _position.inMilliseconds / _duration.inMilliseconds
            : 0.0,
      ),
    );
  }

  Future<int> play() async {
    bool isLocal = false;
    String audioPath = widget.url;
    if (widget.file != null) {
      isLocal = true;
      audioPath = widget.file.path;
    }
    int duration = await _audioPlayer.getDuration();
    int position = await _audioPlayer.getCurrentPosition();
    if (duration != null && position != null) {
      if (position >= duration) {
        _audioPlayer.stop();
      }
    }
    return _audioPlayer.play(audioPath, isLocal: isLocal);
  }

  Future<int> resume() {
    return _audioPlayer.resume();
  }

  Future<int> pause() {
    return _audioPlayer.pause();
  }

  void _onPlayerStateChanged(ap.AudioPlayerState status) {
    setState(() => _status = status);
  }

  void _onDurationChanged(Duration duration) {
    setState(() => _duration = duration);
  }

  void _onAudioPositionChanged(Duration position) {
    setState(() => _position = position);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildControl(),
        _buildSlider(),
      ],
    );
  }
}

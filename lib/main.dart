import 'dart:async';
import 'dart:math';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jam Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainTimerPage(),
    );
  }
}

class Range {
  List<int> _range = [];

  Range(int min, int max) {
    _range = [min, max];
  }

  void updateRange(int? value, int index) {
    if (value != null) {
      _range[index] = value;
      if (index == 0 && _range[index] > _range[1]) {
        _range[1] = _range[0];
      } else if (index == 1 && _range[index] < _range[0]) {
        _range[0] = _range[1];
      }
    }
  }

  int get min => _range[0];
  int get max => _range[1];
}

class MainTimerPage extends StatefulWidget {
  MainTimerPage({super.key});

  final Range musiciansRange = Range(2, 6);
  final Range timeRange = Range(3, 8);

  @override
  State<MainTimerPage> createState() => _MainTimerPageState();
}

class _MainTimerPageState extends State<MainTimerPage> {
  int _numMusicians = 6;
  int _totTime = 5;
  final Random _rng = Random();
  bool _playing = false;
  bool _clockViz = true;

  void onSettingsPress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          musiciansRange: widget.musiciansRange,
          timeRange: widget.timeRange,
        ),
      ),
    );
  }

  Duration _remainingTime = const Duration(minutes: 5);
  Timer? _timer;
  Timer? _blinkTimer;

  // generates a random int in range [min, max] inclusive
  int _randintInRange(int min, int max) {
    return _rng.nextInt(max - min + 1) + min;
  }

  void _randomize() {
    if (!_playing) {
      setState(() {
        _blinkTimer?.cancel();
        _clockViz = true;
        _numMusicians = _randintInRange(
            widget.musiciansRange.min, widget.musiciansRange.max);
        _totTime = _randintInRange(widget.timeRange.min, widget.timeRange.max);
        _remainingTime = Duration(minutes: _totTime);
      });
    }
  }

  void _togglePlay() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _blinkTimer?.cancel();
        _clockViz = true;
        _updateTime();
      } else {
        _timer?.cancel();
        _blink();
      }
    });
  }

  void _blink() {
    setState(() {
      _clockViz = !_clockViz;
      if (_clockViz) {
        _blinkTimer = Timer(const Duration(milliseconds: 500), _blink);
      } else {
        _blinkTimer = Timer(const Duration(milliseconds: 300), _blink);
      }
    });
  }

  IconData _getPlayIcon() {
    if (_playing) {
      return Icons.pause;
    } else {
      return Icons.play_arrow;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkTimer?.cancel();
    Wakelock.disable();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _remainingTime -= const Duration(seconds: 1);
      if (_remainingTime > const Duration(seconds: 0)) {
        _timer = Timer(
          const Duration(seconds: 1),
          _updateTime,
        );
      }
    });
  }

  String _clockDisplay(minute, seconds) {
    var secondsStr = seconds.toString().padLeft(2, '0');
    if (_clockViz) return '$minute:$secondsStr';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final minute = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds - 60 * minute;

    Wakelock.enable();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Jam Generator'),
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  onSettingsPress();
                }),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RichText(
              text: TextSpan(
                text: '$_numMusicians',
                style: Theme.of(context).textTheme.headlineMedium,
                children: <TextSpan>[
                  TextSpan(
                    text: ' musicians',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                text: 'For ',
                style: Theme.of(context).textTheme.headlineSmall,
                children: <TextSpan>[
                  TextSpan(
                    text: '$_totTime',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  TextSpan(
                    text: ' min',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Center(
              heightFactor: 3,
              child: Text(
                _clockDisplay(minute, seconds),
                style: const TextStyle(
                  fontSize: 128,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 30,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'dice',
              onPressed: _randomize,
              tooltip: 'Roll the dice',
              backgroundColor:
                  _playing ? const Color.fromARGB(255, 150, 150, 150) : null,
              child: const Icon(Icons.casino, size: 36),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 30,
            child: FloatingActionButton(
              heroTag: 'play',
              onPressed: _togglePlay,
              tooltip: 'Play/Pause',
              child: Icon(_getPlayIcon()),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.musiciansRange,
    required this.timeRange,
  });

  final Range musiciansRange;
  final Range timeRange;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<int>> timeItems = [];
    for (int i = 0; i < 60; i++) {
      timeItems.add(DropdownMenuItem<int>(
        value: (i + 1),
        child: Text('${i + 1} min'),
      ));
    }
    List<DropdownMenuItem<int>> musiciansItems = [];
    for (int i = 0; i < 100; i++) {
      musiciansItems.add(DropdownMenuItem<int>(
        value: (i + 1),
        child: Text('${i + 1}'),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: const <Widget>[
                  Icon(Icons.alarm),
                  Text('Min time:'),
                ],
              ),
              DropdownButton<int>(
                value: widget.timeRange.min,
                items: timeItems,
                onChanged: (value) {
                  setState(() {
                    widget.timeRange.updateRange(value, 0);
                  });
                },
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: const <Widget>[
                  Icon(Icons.alarm),
                  Text('Max time:'),
                ],
              ),
              DropdownButton<int>(
                value: widget.timeRange.max,
                items: timeItems,
                onChanged: (value) {
                  setState(() {
                    widget.timeRange.updateRange(value, 1);
                  });
                },
              ),
            ],
          ),
          const Divider(
            indent: 40,
            endIndent: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: const <Widget>[
                  Icon(Icons.person),
                  Text('Min Musicians:'),
                ],
              ),
              DropdownButton<int>(
                value: widget.musiciansRange.min,
                items: musiciansItems,
                onChanged: (value) {
                  setState(() {
                    widget.musiciansRange.updateRange(value, 0);
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: const <Widget>[
                  Icon(Icons.person),
                  Text('Max Musicians:'),
                ],
              ),
              DropdownButton<int>(
                value: widget.musiciansRange.max,
                items: musiciansItems,
                onChanged: (value) {
                  setState(() {
                    widget.musiciansRange.updateRange(value, 1);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

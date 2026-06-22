import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:web/web.dart' as web;

// ==================== TUNER ====================

class TunerDialog extends StatefulWidget {
  const TunerDialog({super.key});
  @override
  State<TunerDialog> createState() => _TunerDialogState();
}

class _TunerDialogState extends State<TunerDialog> {
  static const nn = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B',
  ];
  double a4 = 440, cents = 0;
  String note = '--', oct = '', hz = '', err = '';
  bool on = false;
  Timer? _t;
  web.AudioContext? _ctx;
  web.AnalyserNode? _an;
  web.MediaStream? _stream;

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      setState(() {
        err = '';
        on = true;
      });
      _ctx = web.AudioContext();
      _stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;
      final src = _ctx!.createMediaStreamSource(_stream!);
      _an = _ctx!.createAnalyser();
      _an!.fftSize = 4096;
      _an!.smoothingTimeConstant = 0.3;
      src.connect(_an!);
      _t = Timer.periodic(const Duration(milliseconds: 50), (_) => _detect());
    } catch (e) {
      setState(() {
        on = false;
        err = '麦克风错误: $e';
      });
    }
  }

  void _stop() {
    _t?.cancel();
    _t = null;
    _stream?.getTracks().toDart.forEach((t) => t.stop());
    _stream = null;
    try {
      _ctx?.close();
    } catch (_) {}
    _ctx = null;
    _an = null;
    if (mounted)
      setState(() {
        on = false;
        note = '--';
        oct = '';
        hz = '';
        cents = 0;
      });
  }

  void _detect() {
    if (_an == null || _ctx == null) return;
    try {
      final len = _an!.fftSize;
      final dartArr = Float32List(len);
      final jsArr = dartArr.toJS;
      _an!.getFloatTimeDomainData(jsArr);
      final sr = _ctx!.sampleRate.toDouble();
      final f = _pitch(dartArr, len, sr);
      if (f < 0) {
        setState(() => note = '--');
        return;
      }
      final s = 12 * (log(f / a4) / ln2);
      final cl = s.round();
      final tgt = a4 * pow(2, cl / 12);
      final c = 1200 * (log(f / tgt) / ln2);
      var ni = (9 + cl) % 12;
      if (ni < 0) ni += 12;
      final oc = ((cl + 9) / 12).floor() + 4;
      setState(() {
        note = nn[ni];
        oct = '$oc';
        hz = f.toStringAsFixed(1);
        cents = c;
      });
    } catch (_) {}
  }

  double _pitch(Float32List b, int sz, double sr) {
    var rms = 0.0;
    for (var i = 0; i < sz; i++) {
      final v = b[i];
      rms += v * v;
    }
    rms = sqrt(rms / sz);
    if (rms < 0.01) return -1;
    var r1 = 0, r2 = sz - 1;
    for (var i = 0; i < sz ~/ 2; i++) {
      if (b[i].abs() < 0.2) {
        r1 = i;
        break;
      }
    }
    for (var i = 1; i < sz ~/ 2; i++) {
      if (b[sz - i].abs() < 0.2) {
        r2 = sz - i;
        break;
      }
    }
    final tr = r2 - r1;
    if (tr <= 0) return -1;
    final cor = List<double>.filled(tr, 0);
    for (var lag = 0; lag < tr; lag++) {
      var s = 0.0;
      for (var i = 0; i < tr - lag; i++) {
        s += b[r1 + i] * b[r1 + i + lag];
      }
      cor[lag] = s;
    }
    var d = 0;
    while (d < cor.length - 1 && cor[d] > cor[d + 1]) d++;
    if (d >= cor.length - 1) return -1;
    var mv = -1.0, mp = d;
    for (var i = d; i < cor.length; i++) {
      if (cor[i] > mv) {
        mv = cor[i];
        mp = i;
      }
    }
    var t0 = mp.toDouble();
    if (mp > 0 && mp < cor.length - 1) {
      final x1 = cor[mp - 1], x2 = cor[mp], x3 = cor[mp + 1];
      final a = (x1 + x3 - 2 * x2) / 2, bb = (x3 - x1) / 2;
      if (a != 0) t0 -= bb / (2 * a);
    }
    return t0 > 0 ? sr / t0 : -1;
  }

  Color _clr() {
    if (note == '--') return Colors.grey;
    if (cents.abs() < 5) return Colors.green;
    return cents < 0 ? Colors.red : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(PhosphorIconsLight.musicNote),
          const SizedBox(width: 8),
          const Text('调音器'),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('A4: '),
                Expanded(
                  child: Slider(
                    value: a4,
                    min: 400,
                    max: 480,
                    divisions: 80,
                    label: '${a4.round()} Hz',
                    onChanged: (v) => setState(() => a4 = v),
                  ),
                ),
                Text('${a4.round()} Hz'),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: _clr(),
                    ),
                  ),
                  if (oct.isNotEmpty)
                    Text('八度 $oct', style: th.textTheme.bodyLarge),
                  if (hz.isNotEmpty)
                    Text('$hz Hz', style: th.textTheme.bodyMedium),
                ],
              ),
            ),
            if (note != '--') ...[
              SizedBox(
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: th.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Positioned(
                      left: (50 + cents.clamp(-48, 48)) * 2.5,
                      child: Container(
                        width: 6,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _clr(),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${cents > 0 ? '+' : ''}${cents.toStringAsFixed(1)} cents',
                style: TextStyle(color: _clr()),
              ),
            ],
            if (err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(err, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _stop();
            Navigator.pop(context);
          },
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: on ? _stop : _start,
          icon: Icon(
            on ? PhosphorIconsLight.stop : PhosphorIconsLight.microphone,
          ),
          label: Text(on ? '停止' : '开始'),
        ),
      ],
    );
  }
}

// ==================== METRONOME (持久化状态) ====================

class _MetronomeCore {
  static int bpm = 120;
  static String timeSignature = '4/4';
  static String sound = 'beep';
  static bool isPlaying = false;
  static int beatCount = 0;
  static Timer? timer;
  static web.AudioContext? audioContext;

  static web.AudioContext _getCtx() {
    audioContext ??= web.AudioContext();
    return audioContext!;
  }

  static void click(bool accent) {
    try {
      final c = _getCtx();
      final now = c.currentTime;
      final o = c.createOscillator();
      final g = c.createGain();
      g.connect(c.destination);
      String tp;
      int fr;
      double vl, dr;
      switch (sound) {
        case 'bell':
          tp = 'triangle';
          fr = accent ? 1500 : 1200;
          vl = 0.3;
          dr = 0.15;
          break;
        case 'click':
          tp = 'square';
          fr = accent ? 600 : 400;
          vl = 0.2;
          dr = 0.05;
          break;
        default:
          tp = 'sine';
          fr = accent ? 1000 : 800;
          vl = 0.3;
          dr = 0.1;
      }
      o.type = tp;
      o.frequency.value = fr;
      g.gain.setValueAtTime(vl, now);
      g.gain.exponentialRampToValueAtTime(0.001, now + dr);
      o.connect(g);
      o.start(now);
      o.stop(now + dr);
    } catch (_) {}
  }

  static void start() {
    if (isPlaying) return;
    final beats = int.parse(timeSignature.split('/')[0]);
    final ms = (60000 / bpm).round();
    beatCount = 0;
    click(true);
    isPlaying = true;
    beatCount = 1;
    timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      click(beatCount % beats == 0);
      beatCount++;
    });
  }

  static void stop() {
    timer?.cancel();
    timer = null;
    isPlaying = false;
    beatCount = 0;
  }

  static void setBpm(int v) {
    bpm = v.clamp(30, 300);
    if (isPlaying) {
      stop();
      start();
    }
  }

  static void setTimeSignature(String v) {
    timeSignature = v;
    if (isPlaying) {
      stop();
      start();
    }
  }

  static void setSound(String v) {
    sound = v;
  }
}

class MetronomeDialog extends StatefulWidget {
  const MetronomeDialog({super.key});
  @override
  State<MetronomeDialog> createState() => _MetronomeDialogState();
}

class _MetronomeDialogState extends State<MetronomeDialog> {
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _MetronomeCore.isPlaying) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beats = int.parse(_MetronomeCore.timeSignature.split('/')[0]);
    final cur = _MetronomeCore.isPlaying
        ? (_MetronomeCore.beatCount % beats) + 1
        : 0;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(PhosphorIconsLight.metronome),
          const SizedBox(width: 8),
          const Text('节拍器'),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _MetronomeCore.setBpm(_MetronomeCore.bpm - 1),
                  ),
                  icon: const Icon(PhosphorIconsLight.minus),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${_MetronomeCore.bpm}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _MetronomeCore.setBpm(_MetronomeCore.bpm + 1),
                  ),
                  icon: const Icon(PhosphorIconsLight.plus),
                ),
              ],
            ),
            const Text('BPM'),
            const SizedBox(height: 8),
            Slider(
              value: _MetronomeCore.bpm.toDouble(),
              min: 30,
              max: 300,
              onChanged: (v) =>
                  setState(() => _MetronomeCore.setBpm(v.round())),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _MetronomeCore.timeSignature,
                    isExpanded: true,
                    items: ['2/4', '3/4', '4/4', '6/8']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null)
                        setState(() => _MetronomeCore.setTimeSignature(v));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _MetronomeCore.sound,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'beep', child: Text('嘟声')),
                      DropdownMenuItem(value: 'bell', child: Text('铃声')),
                      DropdownMenuItem(value: 'click', child: Text('点击')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _MetronomeCore.setSound(v));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(beats, (i) {
                final active = _MetronomeCore.isPlaying && (i + 1) == cur;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? (i == 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: i == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: () => setState(
            () => _MetronomeCore.isPlaying
                ? _MetronomeCore.stop()
                : _MetronomeCore.start(),
          ),
          icon: Icon(
            _MetronomeCore.isPlaying
                ? PhosphorIconsLight.stop
                : PhosphorIconsLight.play,
          ),
          label: Text(_MetronomeCore.isPlaying ? '停止' : '开始'),
        ),
      ],
    );
  }
}

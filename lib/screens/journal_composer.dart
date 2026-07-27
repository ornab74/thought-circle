import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../app/theme.dart';
import '../models/reflection.dart';
import '../models/thought.dart';
import '../state/app_controller.dart';

Future<JournalEntry?> showJournalComposer(
  BuildContext context,
  AppController controller, {
  bool startWithVoice = false,
}) {
  return showModalBottomSheet<JournalEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _JournalComposer(
      controller: controller,
      startWithVoice: startWithVoice,
    ),
  );
}

class _JournalComposer extends StatefulWidget {
  const _JournalComposer({
    required this.controller,
    required this.startWithVoice,
  });

  final AppController controller;
  final bool startWithVoice;

  @override
  State<_JournalComposer> createState() => _JournalComposerState();
}

class _JournalComposerState extends State<_JournalComposer> {
  final _note = TextEditingController();
  final _recorder = AudioRecorder();
  Process? _pipeWireRecorder;
  String? _recordingPath;
  Timer? _timer;
  late bool _voiceMode;
  bool _recording = false;
  bool _paused = false;
  bool _saving = false;
  Duration _elapsed = Duration.zero;
  JournalMood _mood = JournalMood.steady;
  String? _thoughtId;

  @override
  void initState() {
    super.initState();
    _voiceMode = widget.startWithVoice;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_recording) {
      if (Platform.isLinux) {
        _pipeWireRecorder?.kill(ProcessSignal.sigint);
      } else {
        unawaited(_recorder.cancel());
      }
    }
    _recorder.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!widget.controller.gemma.isReady) {
      _show('Start Gemma first so it can shape your voice note.');
      return;
    }
    try {
      if (!Platform.isLinux && !await _recorder.hasPermission()) {
        _show('Microphone access is needed for a voice note.');
        return;
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/thought-circle-voice.wav';
      _recordingPath = path;
      if (Platform.isLinux) {
        final process = await Process.start('pw-record', <String>[
          '--media-category',
          'Capture',
          '--media-role',
          'Communication',
          '--rate',
          '16000',
          '--channels',
          '1',
          '--format',
          's16',
          path,
        ]);
        _pipeWireRecorder = process;
        unawaited(process.stdout.drain<void>());
        unawaited(process.stderr.drain<void>());
      } else {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 256000,
            autoGain: true,
            echoCancel: true,
            noiseSuppress: true,
          ),
          path: path,
        );
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _paused) return;
        setState(() => _elapsed += const Duration(seconds: 1));
        if (_elapsed >= const Duration(seconds: 90)) _finishVoice();
      });
      setState(() {
        _recording = true;
        _paused = false;
        _elapsed = Duration.zero;
      });
    } catch (exception) {
      _show('The microphone could not start: $exception');
    }
  }

  Future<void> _togglePause() async {
    if (!_recording) return;
    try {
      if (Platform.isLinux) {
        _pipeWireRecorder?.kill(
          _paused ? ProcessSignal.sigcont : ProcessSignal.sigstop,
        );
      } else if (_paused) {
        await _recorder.resume();
      } else {
        await _recorder.pause();
      }
      setState(() => _paused = !_paused);
    } catch (exception) {
      _show('Recording could not pause: $exception');
    }
  }

  Future<void> _finishVoice() async {
    if (!_recording || _saving) return;
    _timer?.cancel();
    setState(() {
      _recording = false;
      _paused = false;
      _saving = true;
    });
    String? path;
    try {
      if (Platform.isLinux) {
        final process = _pipeWireRecorder;
        process?.kill(ProcessSignal.sigint);
        if (process != null) {
          try {
            await process.exitCode.timeout(const Duration(seconds: 3));
          } on TimeoutException {
            process.kill();
          }
        }
        _pipeWireRecorder = null;
        path = _recordingPath;
      } else {
        path = await _recorder.stop();
      }
      if (path == null) throw StateError('No voice note was created.');
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (await file.exists()) await file.delete();
      final entry = await widget.controller.addVoiceJournal(
        audioBytes: bytes,
        mood: _mood,
        note: _note.text,
        linkedThoughtId: _thoughtId,
      );
      if (mounted) Navigator.pop(context, entry);
    } catch (exception) {
      _show(widget.controller.message ?? exception.toString());
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveText() async {
    if (_note.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final entry = await widget.controller.addJournalEntry(
        note: _note.text,
        mood: _mood,
        linkedThoughtId: _thoughtId,
      );
      if (mounted) Navigator.pop(context, entry);
    } catch (exception) {
      _show(widget.controller.message ?? exception.toString());
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final thoughts = widget.controller.activeThoughts;
    return Container(
      decoration: const BoxDecoration(
        color: ThoughtCircleColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: ThoughtCircleColors.line,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Capture this moment',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.edit_note_rounded),
                  label: Text('Write'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.mic_rounded),
                  label: Text('Speak'),
                ),
              ],
              selected: <bool>{_voiceMode},
              onSelectionChanged: _recording || _saving
                  ? null
                  : (value) => setState(() => _voiceMode = value.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 18),
            Text('Feel', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                for (final mood in JournalMood.values)
                  ChoiceChip(
                    selected: mood == _mood,
                    onSelected: (_) => setState(() => _mood = mood),
                    avatar: Text(_moodIcon(mood)),
                    label: Text(_moodLabel(mood)),
                  ),
              ],
            ),
            const SizedBox(height: 17),
            DropdownButtonFormField<String?>(
              initialValue: _thoughtId,
              decoration: const InputDecoration(
                labelText: 'Loop (optional)',
                prefixIcon: Icon(Icons.circle_outlined),
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No loop'),
                ),
                for (final Thought thought in thoughts)
                  DropdownMenuItem<String?>(
                    value: thought.id,
                    child: Text(thought.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _thoughtId = value),
            ),
            const SizedBox(height: 14),
            if (!_voiceMode)
              TextField(
                controller: _note,
                autofocus: true,
                minLines: 5,
                maxLines: 9,
                maxLength: 2400,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What happened? What stayed with you?',
                  alignLabelWithHint: true,
                ),
              )
            else ...<Widget>[
              _VoiceRecorder(
                recording: _recording,
                paused: _paused,
                saving: _saving,
                elapsed: _elapsed,
                onRecord: _startRecording,
                onPause: _togglePause,
                onDone: _finishVoice,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                enabled: !_saving,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Add a cue (optional)',
                  hintText: 'Connect this to…',
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (!_voiceMode)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveText,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    widget.controller.gemma.isReady
                        ? 'Shape & save'
                        : 'Save note',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _moodIcon(JournalMood mood) => switch (mood) {
    JournalMood.steady => '◌',
    JournalMood.hopeful => '✦',
    JournalMood.light => '☀',
    JournalMood.restless => '≈',
    JournalMood.heavy => '●',
  };

  String _moodLabel(JournalMood mood) => switch (mood) {
    JournalMood.steady => 'Steady',
    JournalMood.hopeful => 'Hopeful',
    JournalMood.light => 'Light',
    JournalMood.restless => 'Restless',
    JournalMood.heavy => 'Heavy',
  };
}

class _VoiceRecorder extends StatelessWidget {
  const _VoiceRecorder({
    required this.recording,
    required this.paused,
    required this.saving,
    required this.elapsed,
    required this.onRecord,
    required this.onPause,
    required this.onDone,
  });

  final bool recording;
  final bool paused;
  final bool saving;
  final Duration elapsed;
  final VoidCallback onRecord;
  final VoidCallback onPause;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF0ECFF), Color(0xFFFFF2EA)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ThoughtCircleColors.line),
      ),
      child: Column(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: recording ? 88 : 78,
            height: recording ? 88 : 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recording
                  ? ThoughtCircleColors.pink
                  : ThoughtCircleColors.purple,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color:
                      (recording
                              ? ThoughtCircleColors.pink
                              : ThoughtCircleColors.purple)
                          .withValues(alpha: 0.28),
                  blurRadius: recording ? 32 : 18,
                ),
              ],
            ),
            child: IconButton(
              onPressed: recording || saving ? null : onRecord,
              icon: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            saving
                ? 'Gemma is shaping your note…'
                : recording
                ? '${elapsed.inMinutes}:$seconds'
                : 'Tap to speak',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            recording
                ? (paused ? 'Paused' : 'Up to 90 seconds')
                : 'Audio is removed after saving.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (recording) ...<Widget>[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onPause,
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  label: Text(paused ? 'Resume' : 'Pause'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

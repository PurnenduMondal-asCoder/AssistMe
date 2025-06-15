import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceRecordingPage extends StatefulWidget {
  const VoiceRecordingPage({super.key});

  @override
  _VoiceRecordingPageState createState() => _VoiceRecordingPageState();
}

class _VoiceRecordingPageState extends State<VoiceRecordingPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  String? _filePath;
  String? _currentlyPlaying;
  final List<Map<String, String>> _recordings = [];

  final List<String> _emotions = ['😊', '😢', '😡', '😐', '😂'];
  final List<String> _emotionLabels = ['Happy', 'Sad', 'Angry', 'Neutral', 'Excited'];

  // List of pastel background colors
  final List<Color> _pastelColors = [
    Color(0xFFFFF9C4), // Light Yellow
    Color(0xFFC8E6C9), // Light Green
    Color(0xFFBBDEFB), // Light Blue
    Color(0xFFFFCDD2), // Light Red
    Color(0xFFD1C4E9), // Light Purple
    Color(0xFFFFF3E0), // Light Orange
  ];

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _loadRecordings();
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> _startRecording() async {
    final Directory tempDir = await getApplicationDocumentsDirectory();
    final String path =
        '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: path);
    setState(() {
      _isRecording = true;
      _filePath = path;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _showSaveDialog();
  }

  Future<void> _playRecording(String path) async {
    if (_currentlyPlaying == path) {
      await _player.stopPlayer();
      setState(() {
        _currentlyPlaying = null;
      });
    } else {
      if (_currentlyPlaying != null) {
        await _player.stopPlayer();
      }
      await _player.startPlayer(fromURI: path);
      setState(() {
        _currentlyPlaying = path;
      });
    }
  }

  void _showSaveDialog() {
    final TextEditingController labelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save Recording"),
          content: TextField(
            controller: labelController,
            decoration: const InputDecoration(hintText: "Enter label for recording"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (labelController.text.isNotEmpty) {
                  final random = Random();
                  final index = random.nextInt(_emotions.length);
                  final emoji = _emotions[index];
                  final label = _emotionLabels[index];

                  setState(() {
                    _recordings.insert(0, {
                      'label': labelController.text,
                      'path': _filePath!,
                      'starred': 'false',
                      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                      'emotion': emoji,
                      'emotion_label': label,
                    });
                  });
                  _saveRecordings();
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _toggleStar(int index) {
    setState(() {
      _recordings[index]['starred'] =
          _recordings[index]['starred'] == 'true' ? 'false' : 'true';
      _sortRecordings();
    });
    _saveRecordings();
  }

  void _sortRecordings() {
    _recordings.sort((a, b) {
      if (a['starred'] == b['starred']) {
        return int.parse(b['timestamp']!).compareTo(int.parse(a['timestamp']!));
      }
      return b['starred']!.compareTo(a['starred']!); // "true" first
    });
  }

  Future<void> _saveRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_recordings);
    await prefs.setString('saved_recordings', jsonString);
  }

  Future<void> _loadRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('saved_recordings');
    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      setState(() {
        _recordings.clear();
        _recordings.addAll(jsonData.map((e) => Map<String, String>.from(e)));
        _sortRecordings();
      });
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VOICE RECORDING',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
         shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            _isRecording ? Icons.mic : Icons.mic_none,
            size: 80,
            color: _isRecording ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isRecording ? Colors.red : const Color.fromARGB(255, 56, 148, 195),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: _isRecording
                  ? const BorderSide(color: Colors.black, width: 2)
                  : BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _isRecording ? 'Stop Recording' : 'Start Recording',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Saved Recordings",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _recordings.isNotEmpty
                ? ListView.builder(
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      final recording = _recordings[index];
                      bool isPlaying = _currentlyPlaying == recording['path'];
                      bool isStarred = recording['starred'] == 'true';
                      String emotionEmoji = recording['emotion'] ?? '';
                      String emotionLabel = recording['emotion_label'] ?? '';

                      return Card(
                        color: isPlaying
                            ? const Color(0xFFE3F2FD)
                            : _pastelColors[index % _pastelColors.length],
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 3,
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                            color: isPlaying ? Colors.blue : Colors.black87,
                            onPressed: () => _playRecording(recording['path']!),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  recording['label']!,
                                  style: TextStyle(
                                    color: isPlaying ? Colors.blue : Colors.black87,
                                    fontWeight:
                                        isStarred ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                emotionEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            isStarred
                                ? "⭐ $emotionLabel • Tap to play/stop"
                                : "$emotionLabel • Tap to play/stop",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isStarred ? Icons.star : Icons.star_border,
                                  color: isStarred ? Colors.orange : Colors.grey,
                                ),
                                onPressed: () => _toggleStar(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  String pathToDelete = recording['path']!;
                                  File file = File(pathToDelete);
                                  if (await file.exists()) {
                                    await file.delete();
                                  }
                                  setState(() {
                                    if (_currentlyPlaying == pathToDelete) {
                                      _currentlyPlaying = null;
                                    }
                                    _recordings.removeAt(index);
                                  });
                                  _saveRecordings();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      "No recordings available.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

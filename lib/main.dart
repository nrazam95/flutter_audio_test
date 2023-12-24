import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterSoundRecorder recorder = FlutterSoundRecorder();
  AudioPlayer player = AudioPlayer();
  bool isRecorderReady = false;
  bool isPlayerReady = false;
  String? _path;
  bool isRecording = false;
  bool isPlaying = false;

  Future<void> record() async {
    if (!isRecorderReady) {
      return;
    }
    await recorder.startRecorder(
      toFile: 'audio_example.mp4',
      codec: Codec.aacMP4,
    );
  }

  Future<void> stop() async {
    if (!recorder.isRecording) {
      return;
    }
    final path = await recorder.stopRecorder();
    print(path);
    final audioFile = File(path!);

    if (audioFile.existsSync()) {
      print('File exists');
      isPlayerReady = true;

      _path = audioFile.path;
    } else {
      print('File does not exist');
      isPlayerReady = false;
    }
  }

  Future<void> play() async {
    await player.play(UrlSource(_path!));
    setState(() {
      isPlaying = true;
    });
  }

  Future<void> stopPlayer() async {
    await player.stop();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void initState() {
    initRecorder();
    // initPlayer();
    super.initState();
  }

  Future<void> initRecorder() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await recorder.openRecorder();

    setState(() {
      isRecorderReady = true;
    });
    recorder.setSubscriptionDuration(const Duration(milliseconds: 1000));
  }

  // Future<void> initPlayer() async {
  //   await player.openPlayer();
  // }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Create a Recorder
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isPlayerReady
                ? ElevatedButton(
                    onPressed: () async {
                      if (isPlaying) {
                        await stopPlayer();
                      } else {
                        await play();
                      }
                    },
                    child: Icon(
                      // ignore: dead_code
                      isPlaying ? Icons.stop : Icons.mic,
                      size: 50,
                    ))
                : Container(),
            StreamBuilder<RecordingDisposition>(
                stream: recorder.onProgress,
                builder: (context, snapshot) {
                  final duration = snapshot.data?.duration ?? Duration.zero;

                  return Text('${duration.inSeconds} seconds');
                }),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () async {
                  if (recorder.isRecording) {
                    await stop();
                    isRecording = false;
                  } else {
                    await record();
                    isRecording = true;
                  }
                },
                child: Icon(
                  // ignore: dead_code
                  isRecording ? Icons.stop : Icons.mic,
                  size: 50,
                ))
          ],
        )),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

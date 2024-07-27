import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.firstOrNull == "multi_window") {
    final windowId = int.parse(args[1]);
    final arguments = args[2].isEmpty
        ? const {} as Map<String, dynamic>
        : jsonDecode(args[2]) as Map<String, dynamic>;
    //
    final controller = WindowController.fromWindowId(windowId);

    //

    if (arguments['type'] == "video_player") {
      fvp.registerWith();
      await windowManager.ensureInitialized();
      runApp(
        VideoPlayerWindow(
          windowController: controller,
          arguments: arguments,
        ),
      );
    }
  } else {
    runApp(const MainApp());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: TextButton(
            onPressed: () async {
              final result = await FilePicker.platform
                  .pickFiles(allowMultiple: false, type: FileType.video);

              if (result != null) {
                createNewWindow(
                  size: const Size(500, 500),
                  title: 'Test',
                  type: 'video_player',
                  args: {'inputPath': result.files.first.path},
                );
              }
            },
            child:
                const Center(child: Text("Pick file and create new window"))),
      ),
    );
  }

  Future<void> createNewWindow({
    required Size size,
    required String title,
    required String type,
    required Map<String, dynamic> args,
    int? minWidth,
    int? minHeight,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final window = await DesktopMultiWindow.createWindow(
      jsonEncode({
        "type": type,
        "width": size.width,
        "height": size.height,
        ...args,
      }),
    );
    await window.setFrame(const Offset(0, 0) & size);
    await window.center();
    await window.setTitle(title);
    await window.show();
  }
}

class VideoPlayerWindow extends StatelessWidget {
  final WindowController windowController;
  final Map<String, dynamic> arguments;
  const VideoPlayerWindow({
    super.key,
    required this.windowController,
    required this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: _VideoPlayer(
            inputPath: arguments['inputPath'],
          ),
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final String inputPath;
  const _VideoPlayer({
    super.key,
    required this.inputPath,
  });

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> with WindowListener {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(File(widget.inputPath));

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize().then((value) {
      setState(() {});
      _controller.play();
    });
    _controller.play();
    windowManager.addListener(this);
  }

  @override
  void onWindowClose() async {
    print("disposing it");

    await _controller.pause();
    await _controller.dispose();

    super.onWindowClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 500,
          height: 500,
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}

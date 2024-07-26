import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:video_player/video_player.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  fvp.registerWith(options: {"fastSeek": true});

  if (args.firstOrNull == "multi_window") {
    final windowId = int.parse(args[1]);
    final arguments = args[2].isEmpty
        ? const {} as Map<String, dynamic>
        : jsonDecode(args[2]) as Map<String, dynamic>;
    //
    final controller = WindowController.fromWindowId(windowId);

    //
    if (arguments['type'] == "video_player") {
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
              final result =
                  await FilePicker.platform.pickFiles(allowMultiple: false);

              if (result != null) {
                createNewWindow(
                  size: const Size(300, 300),
                  title: 'Test',
                  type: 'video_player',
                  args: {'inputPath': result.files.first.path},
                );
              }
            },
            child: const Text("Pick file and create new window")),
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
      jsonEncode(
          {"type": type, "width": size.width, "height": size.height, ...args}),
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
        body: _VideoPlayer(
          inputPath: arguments['inputPath'],
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

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.inputPath));

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FutureBuilder(
          future: _controller.initialize(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return SizedBox(
                width: 200,
                height: 200,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        VideoPlayer(_controller),
                        VideoProgressIndicator(_controller,
                            allowScrubbing: true),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const Center(child: CupertinoActivityIndicator());
          },
        )
      ],
    );
  }
}

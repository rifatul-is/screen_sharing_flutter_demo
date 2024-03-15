import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_sharing_demo/pages/signaling.dart';

class home_page extends StatefulWidget {
  const home_page({super.key});

  @override
  State<home_page> createState() => _home_pageState();
}

class _home_pageState extends State<home_page> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool isForegroundEnabled = false;
  bool isStreaming = false;
  static const MethodChannel _channel = MethodChannel('com.com.janatawifi.screen_sharing_demo.screen_sharing_demo/services');
  GlobalKey _globalKey = GlobalKey();
  Signaling signaling = Signaling();

  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');


  @override
  void initState() {
    initRenderer();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    if (Platform.isAndroid) {
      startScreenCaptureServiceAndroid();
      print("await screen capture services");
      //await startForegroundService();
    }

    super.initState();

  }

  //Check for screenshotting
  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.dispose();
    super.dispose();
  }

  Future<void> initRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      print("Storage Permission Granted");
      await Permission.storage.request();
    }
  }


  Future<void> startScreenCaptureServiceAndroid() async {
    try {
      print("Starting Services");
      await _channel.invokeMethod('startScreenCaptureService');
    } on PlatformException catch (e) {
      print("Failed to start screen capture service: '${e.message}'.");
    }
  }

  Future<void> captureAndSaveScreenshot() async {
    print("Inside Timer Function");
    RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData =
    await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      final result = await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
      print("Image Result : $result");
    }
  }

  Future<void> startScreenShare() async {
    final mediaStream = await navigator.mediaDevices.getDisplayMedia({
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': '640', // Provide required width for your application
          'minHeight': '480', // Provide required height for your application
          'minFrameRate': '30', // Provide required frame rate for your application
        },
        "deviceId": "broadcast", // Specify broadcast to use the extension
        'facingMode': 'user',
      },
    });

    setState(() {
      _localStream = mediaStream;
      _localRenderer.srcObject = _localStream;
    });
  }

  // void stopScreenSharing() {
  //   if (_localStream != null) {
  //     _localStream!.getTracks().forEach((track) {
  //       track.stop();
  //     });
  //     _localStream = null;
  //     _localRenderer.srcObject = null;
  //   }
  // }

  void stopScreenSharing(MediaStream mediaStream) {
    // Get all tracks from the media stream
    final tracks = mediaStream.getTracks();

    // Stop each track
    for (var track in tracks) {
      track.stop();
    }

    // Optionally, you might want to set the mediaStream to null or handle it accordingly
    // to clean up references in your application
  }

  void stopSharing() {
    if (_localStream != null) {
      stopScreenSharing(_localStream!);
      _localStream = null; // Clean up the reference
    }

    setState(() {
      isStreaming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Screen Sharing with WebRTC'),
        ),
        body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
                      Expanded(child: RTCVideoView(_remoteRenderer)),
                    ],
                  ),
                ),
              ),
              // Row(
              //   children: [
              //     Expanded(
              //       child: RTCVideoView(_localRenderer),
              //     ),
              //     Expanded(
              //       child: RTCVideoView(_remoteRenderer),
              //     ),
                // ],
              // ),
              TextFormField(
                controller: textEditingController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a search term',
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        signaling.openUserMedia(_localRenderer, _remoteRenderer);
                      },
                      child: Text("Start"),
                    ),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     startScreenShare();
                    //   },
                    //   child: Text('Start'),
                    // ),
                    ElevatedButton(
                      onPressed: () {
                        stopSharing();
                      },
                      child: Text('Stop'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        roomId = await signaling.createRoom(_remoteRenderer);
                        textEditingController.text = roomId!;
                        setState(() {});
                      },
                      child: Text("Call"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Add roomId
                        signaling.joinRoom(
                          textEditingController.text.trim(),
                          _remoteRenderer,
                        );
                      },
                      child: Text("Join"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        signaling.hangUp(_localRenderer);
                      },
                      child: Text("Hang"),
                    )
                  ],
                ),
              )
            ],
          ),
    );
  }
}

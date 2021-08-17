import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_image_view/flutter_image_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterImageView.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            // Container(
            //   height: 100,
            //   width: 178,
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.all(Radius.circular(5))),
            //   child: FlutterImageView.getPlatformImageView(
            //       imagePath:
            //           "https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/95bc2fa23409a6244d77b51af535fdd2.gif",
            //       radius: 5),
            // ),
            // Container(
            //   height: 100,
            //   width: 178,
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.all(Radius.circular(10))),
            //   child: FlutterImageView.getPlatformImageView(
            //       imagePath:
            //           "https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f2a62e2ce1743516a3d47b0d5b12bb02.gif",
            //       radius: 10),
            // ),
            // Container(
            //   height: 100,
            //   width: 178,
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.all(Radius.circular(15))),
            //   child: FlutterImageView.getPlatformImageView(
            //       imagePath:
            //           "https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f8232500106303e7c1767eb8286fc814.gif",
            //       radius: 20),
            // ),
            Container(
              height: 100,
              width: 178,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: FlutterImageView.getPlatformImageView(
                  radius: 10,
                  imagePath:
                      "https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/29fb2a3ef9246f95e4495876e9742d2a.gif"),
            )
          ],
        ),
      ),
    );
  }
}

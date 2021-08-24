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
  String _textureId1 = '';
  String _textureId2 = '';
  String _textureId3 = '';
  String _textureId4 = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    FlutterImageView.disposeTexture(_textureId1);
    FlutterImageView.disposeTexture(_textureId2);
    FlutterImageView.disposeTexture(_textureId3);
    FlutterImageView.disposeTexture(_textureId4);
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    Map platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      // final result1 = await FlutterImageView.loadTexture(
      //     'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/95bc2fa23409a6244d77b51af535fdd2.gif');
      // final result2 = await FlutterImageView.loadTexture(
      //     'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f2a62e2ce1743516a3d47b0d5b12bb02.gif');
      // final result3 = await FlutterImageView.loadTexture(
      //     'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f8232500106303e7c1767eb8286fc814.gif');
      // final result4 = await FlutterImageView.loadTexture(
      //     'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/29fb2a3ef9246f95e4495876e9742d2a.gif');

      // _textureId1 = result1['textureId'].toString();
      // _textureId2 = result2['textureId'].toString();
      // _textureId3 = result3['textureId'].toString();
      // _textureId4 = result4['textureId'].toString();
      if (mounted) setState(() {});
      // if (!mounted) return;
      // setState(() {
      //   _textureId1 = result[0]['textureId'].toString();
      //   _textureId2 = result[1]['textureId'].toString();
      //   _textureId3 = result[2]['textureId'].toString();
      //   _textureId4 = result[3]['textureId'].toString();
      // });
    } on PlatformException {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Container(
              //   height: 100,
              //   width: 178,
              //   decoration: BoxDecoration(
              //       borderRadius: BorderRadius.all(Radius.circular(15))),
              //   child: Image.network(
              //       'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/95bc2fa23409a6244d77b51af535fdd2.gif'),
              // ),
              if (_textureId1.isNotEmpty)
                Container(
                  height: 140,
                  width: 156.5,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: int.tryParse(_textureId1) != null
                      ? Texture(textureId: int.tryParse(_textureId1))
                      : SizedBox(),
                ),
              if (_textureId2.isNotEmpty)
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: int.tryParse(_textureId2) != null
                      ? Texture(textureId: int.tryParse(_textureId2))
                      : SizedBox(),
                ),
              if (_textureId3.isNotEmpty)
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: int.tryParse(_textureId3) != null
                      ? Texture(textureId: int.tryParse(_textureId3))
                      : SizedBox(),
                ),
              if (_textureId4.isNotEmpty)
                Container(
                  height: 100,
                  width: 178,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: int.tryParse(_textureId4) != null
                      ? Texture(textureId: int.tryParse(_textureId4))
                      : SizedBox(),
                )
            ],
          )
          //  Column(
          //   children: [
          //     Container(
          //       height: 100,
          //       width: 178,
          //       decoration: BoxDecoration(
          //           borderRadius: BorderRadius.all(Radius.circular(10))),
          //       child: FlutterImageView.getPlatformImageView(
          //           imagePath:
          //               "https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f2a62e2ce1743516a3d47b0d5b12bb02.gif",
          //           radius: 10),
          //     ),
          //     Container(
          //       height: 100,
          //       width: 178,
          //       decoration: BoxDecoration(
          //           borderRadius: BorderRadius.all(Radius.circular(15))),
          //       child: FlutterImageView.getPlatformImageView(
          //           imagePath:
          //               "https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f8232500106303e7c1767eb8286fc814.gif",
          //           radius: 20),
          //     ),
          //     Container(
          //       height: 100,
          //       width: 178,
          //       decoration: BoxDecoration(
          //           borderRadius: BorderRadius.all(Radius.circular(20))),
          //       child: FlutterImageView.getPlatformImageView(
          //           imagePath:
          //               "https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/29fb2a3ef9246f95e4495876e9742d2a.gif"),
          //     )
          //   ],
          // ),
          ),
    );
  }
}

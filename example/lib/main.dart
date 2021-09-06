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

  String _requestId1 = '';
  String _requestId2 = '';
  String _requestId3 = '';
  String _requestId4 = '';

  @override
  void initState() {
    super.initState();
    FlutterImageView.init();
    initPlatformState();
  }

  @override
  void dispose() {
    FlutterImageView.disposeTexture(_textureId1, _requestId1);
    FlutterImageView.disposeTexture(_textureId2, _requestId2);
    FlutterImageView.disposeTexture(_textureId3, _requestId3);
    FlutterImageView.disposeTexture(_textureId4, _requestId4);
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      // final result1 = await FlutterImageView.loadTexture(
      //     'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/95bc2fa23409a6244d77b51af535fdd2.gif',
      //     width: 178,
      //     height: 178,
      //     radius: 8, progressCallBack: (progress) {
      //   print(progress);
      // }, errorCallBack: (error) {
      //   print(error);
      // }, doneCallBack: () {
      //   print('done');
      // });
      // final result2 = await FlutterImageView.loadTexture(
      //     'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f2a62e2ce1743516a3d47b0d5b12bb02.gif',
      //     width: 178,
      //     height: 178,
      //     radius: 8);
      // final result3 = await FlutterImageView.loadTexture(
      //     'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f8232500106303e7c1767eb8286fc814.gif',
      //     width: 178,
      //     height: 178,
      //     radius: 8);
      // final result4 = await FlutterImageView.loadTexture(
      //     'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/29fb2a3ef9246f95e4495876e9742d2a.gif',
      //     width: 178,
      //     height: 178,
      //     radius: 8);

      // _textureId1 = result1['textureId'].toString();
      // _requestId1 = result1['requestId'].toString();

      // _textureId2 = result2['textureId'].toString();
      // _requestId2 = result2['requestId'].toString();

      // _textureId3 = result3['textureId'].toString();
      // _requestId3 = result3['requestId'].toString();

      // _textureId4 = result4['textureId'].toString();
      // _requestId4 = result4['requestId'].toString();
      // if (mounted) setState(() {});
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
          backgroundColor: Colors.green,
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: Image.network(
                    'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/95bc2fa23409a6244d77b51af535fdd2.gif',
                    width: 150,
                    height: 150,
                    fit: BoxFit.fill,
                    cacheWidth: 150),
              ),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: Image.network(
                    'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f2a62e2ce1743516a3d47b0d5b12bb02.gif',
                    width: 150,
                    height: 150,
                    fit: BoxFit.fill,
                    cacheWidth: 150),
              ),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: Image.network(
                    'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f8232500106303e7c1767eb8286fc814.gif',
                    width: 150,
                    height: 150,
                    fit: BoxFit.fill,
                    cacheWidth: 150),
              ),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: Image.network(
                    'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/29fb2a3ef9246f95e4495876e9742d2a.gif',
                    width: 150,
                    height: 150,
                    fit: BoxFit.fill,
                    cacheWidth: 150),
              ),
              // Container(
              //   height: 225,
              //   width: 225,
              //   decoration: BoxDecoration(
              //       borderRadius: BorderRadius.all(Radius.circular(15))),
              //   child: Image.network(
              //       'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f2a62e2ce1743516a3d47b0d5b12bb02.gif'),
              // ),
              // Container(
              //   height: 225,
              //   width: 225,
              //   decoration: BoxDecoration(
              //       borderRadius: BorderRadius.all(Radius.circular(15))),
              //   child: Image.network(
              //       'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/f8232500106303e7c1767eb8286fc814.gif'),
              // ),
              // Container(
              //   height: 225,
              //   width: 225,
              //   decoration: BoxDecoration(
              //       borderRadius: BorderRadius.all(Radius.circular(15))),
              //   child: Image.network(
              //       'https://fb-cdn.fanbook.mobi/fanbook/app/files/chatroom/image/29fb2a3ef9246f95e4495876e9742d2a.gif'),
              // ),
              if (_textureId1.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      FlutterImageView.disposeTexture(_textureId2, _requestId2);
                      FlutterImageView.disposeTexture(_textureId3, _requestId3);
                      FlutterImageView.disposeTexture(_textureId4, _requestId4);
                      _textureId2 = '';
                      _textureId3 = '';
                      _textureId4 = '';
                    });
                  },
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    child: int.tryParse(_textureId1) != null
                        ? Texture(textureId: int.tryParse(_textureId1))
                        : SizedBox(),
                  ),
                ),
              if (_textureId2.isNotEmpty)
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: int.tryParse(_textureId2) != null
                      ? Texture(textureId: int.tryParse(_textureId2))
                      : SizedBox(),
                ),
              if (_textureId3.isNotEmpty)
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: int.tryParse(_textureId3) != null
                      ? Texture(textureId: int.tryParse(_textureId3))
                      : SizedBox(),
                ),
              if (_textureId4.isNotEmpty)
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
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

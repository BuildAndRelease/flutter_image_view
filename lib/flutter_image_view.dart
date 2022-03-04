import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

typedef ImageViewProgressCallBack = void Function(double? progress);
typedef ImageViewErrorCallBack = void Function(String error);
typedef ImageViewDoneCallBack = void Function();

enum FlutterImageViewStatus { loading, progress, error, done }

class FlutterImageView {
  static const MethodChannel _channel =
      const MethodChannel('flutter_image_view');
  static Map<String, ImageViewProgressCallBack> progressCallBackMap = {};
  static Map<String, ImageViewErrorCallBack> errorCallBackMap = {};
  static Map<String, ImageViewDoneCallBack> doneCallBackMap = {};
  static final uuid = Uuid();

  static void init() {
    _channel.setMethodCallHandler((call) async {
      final requestId = call.arguments['requestId'].toString();
      if (requestId.isEmpty) return true;
      switch (call.method) {
        case "onProgress":
          final progress =
              double.tryParse(call.arguments["progress"].toString());
          final progressFunction = progressCallBackMap[requestId];
          if (progressFunction != null) progressFunction(progress);
          break;
        case "onError":
          final error = call.arguments["error"].toString();
          final errorFunction = errorCallBackMap[requestId];
          if (errorFunction != null) errorFunction(error);
          break;
        case "onDone":
          final doneFunction = doneCallBackMap[requestId];
          if (doneFunction != null) doneFunction();
          break;
        default:
          break;
      }
      return true;
    });
  }

  static Future<Map?> loadTexture(
    String url, {
    int width = 0,
    int height = 0,
    int radius = 0,
    ImageViewProgressCallBack? progressCallBack,
    ImageViewErrorCallBack? errorCallBack,
    ImageViewDoneCallBack? doneCallBack,
  }) async {
    final requestId = uuid.v4();
    final args = {
      "url": url,
      "width": width.toString(),
      "height": height.toString(),
      "radius": radius.toString(),
      "requestId": requestId,
    };
    if (progressCallBack != null)
      progressCallBackMap[requestId] = progressCallBack;
    if (errorCallBack != null) errorCallBackMap[requestId] = errorCallBack;
    if (doneCallBack != null) doneCallBackMap[requestId] = doneCallBack;
    final Map? textureInfo = await _channel.invokeMethod('loadTexture', args);
    return textureInfo;
  }

  static Future<bool?> disposeTexture(
      String textureId, String reqeustId) async {
    progressCallBackMap.remove(reqeustId);
    errorCallBackMap.remove(reqeustId);
    doneCallBackMap.remove(reqeustId);
    final args = {"textureId": textureId};
    try {
      return await _channel.invokeMethod('dispose', args);
    } catch (e) {
      return false;
    }
  }

  static Future<bool?> cleanCache() async {
    try {
      return await _channel.invokeMethod('cleanCache', {});
    } catch (e) {
      return false;
    }
  }

  static Future<String?> cachedPath() async {
    try {
      return await _channel.invokeMethod('cachedPath', {});
    } catch (e) {
      return null;
    }
  }

  /// Creates a widget that displays an image with native view.
  ///
  /// IOS use SDWebImage Framework and return UIImageView.
  /// Android use Glide Framework and return ImageView.
  ///
  /// The [imagePath] or [imageData] arguments must not be null.
  /// [imagePath] can be url or local path.
  /// [imageData] can be image binary list.
  /// [placeHolderPath] or [placeHolderData] load before image display.
  /// [radius] imageview radius.
  /// [hitTestBehavior] How this widget should behave during hit testing.
  static Widget getPlatformImageView({
    String? imagePath,
    Uint8List? imageData,
    String? placeHolderPath,
    Uint8List? placeHolderData,
    double? width,
    double? height,
    num? radius,
    bool ignoreGesture = true,
    PlatformViewHitTestBehavior hitTestBehavior =
        PlatformViewHitTestBehavior.transparent,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    TextDirection? layoutDirection,
    PlatformViewCreatedCallback? onPlatformViewCreated,
    Key? key,
  }) {
    final Map<String, dynamic> params = {};
    if (imagePath?.isNotEmpty ?? false) params["imagePath"] = imagePath;
    if (imageData != null) params["imageData"] = imageData;
    if (placeHolderPath?.isNotEmpty ?? false)
      params["placeHolderPath"] = placeHolderPath;
    if (placeHolderData != null) params["placeHolderData"] = placeHolderData;
    if (radius != null) params["radius"] = radius;
    if (width != null) params["width"] = width;
    if (height != null) params["height"] = height;
    Widget widget;
    if (defaultTargetPlatform == TargetPlatform.android) {
      widget = AndroidView(
          key: key,
          viewType: "native_image_view",
          hitTestBehavior: hitTestBehavior,
          gestureRecognizers: gestureRecognizers,
          layoutDirection: layoutDirection,
          onPlatformViewCreated: onPlatformViewCreated,
          creationParams: params,
          creationParamsCodec: const StandardMessageCodec());
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      widget = UiKitView(
          key: key,
          viewType: "native_image_view",
          hitTestBehavior: hitTestBehavior,
          gestureRecognizers: gestureRecognizers,
          layoutDirection: layoutDirection,
          onPlatformViewCreated: onPlatformViewCreated,
          creationParams: params,
          creationParamsCodec: const StandardMessageCodec());
    } else {
      widget = const SizedBox();
    }
    widget = ignoreGesture ? AbsorbPointer(child: widget) : widget;
    return (width != null && height != null)
        ? SizedBox(width: width, height: height, child: widget)
        : widget;
  }
}

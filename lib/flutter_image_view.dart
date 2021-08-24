import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class FlutterImageView {
  static const MethodChannel _channel =
      const MethodChannel('flutter_image_view');

  static Future<Map> loadTexture(String url,
      {int width = 0, int height = 0, int radius = 0}) async {
    final args = {
      "url": url,
      "width": width.toString(),
      "height": height.toString(),
      "radius": radius.toString()
    };
    final Map textureInfo = await _channel.invokeMethod('loadTexture', args);
    return textureInfo;
  }

  static Future<bool> disposeTexture(String textureId) async {
    final args = {"textureId": textureId};
    final result = await _channel.invokeMethod('dispose', args);
    return result;
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
    String imagePath,
    Uint8List imageData,
    String placeHolderPath,
    Uint8List placeHolderData,
    double width,
    double height,
    num radius,
    bool ignoreGesture = true,
    PlatformViewHitTestBehavior hitTestBehavior =
        PlatformViewHitTestBehavior.transparent,
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
    TextDirection layoutDirection,
    PlatformViewCreatedCallback onPlatformViewCreated,
    Key key,
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

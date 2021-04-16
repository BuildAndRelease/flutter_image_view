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

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
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
    double heigth,
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
    return (width != null && heigth != null)
        ? SizedBox(width: width, height: heigth, child: widget)
        : widget;
  }
}

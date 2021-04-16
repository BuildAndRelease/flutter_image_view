import Flutter
import UIKit
import SDWebImage

public class SwiftFlutterImageViewPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_image_view", binaryMessenger: registrar.messenger())
    let factory = PlatformGifImageViewFactory()
    SDImageCache.shared.config.shouldCacheImagesInMemory = false
    registrar.register(factory, withId: "native_image_view")
    let instance = SwiftFlutterImageViewPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}

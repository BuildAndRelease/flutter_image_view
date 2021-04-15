import Flutter
import UIKit

public class SwiftFlutterImageViewPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_image_view", binaryMessenger: registrar.messenger())
    let factory = PlatformGifImageViewFactory()
    registrar.register(factory, withId: "gif_image_view")
    let instance = SwiftFlutterImageViewPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}

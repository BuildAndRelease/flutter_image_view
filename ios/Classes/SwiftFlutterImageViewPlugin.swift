import Flutter
import UIKit
import SDWebImage

public class SwiftFlutterImageViewPlugin: NSObject, FlutterPlugin {
    var textures : FlutterTextureRegistry?
    var renders = NSMutableDictionary()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: "flutter_image_view", binaryMessenger: registrar.messenger())
      let factory = PlatformImageViewFactory()
      SDImageCache.shared.config.shouldCacheImagesInMemory = false
      registrar.register(factory, withId: "native_image_view")
      
      let instance = SwiftFlutterImageViewPlugin()
      
      instance.textures = registrar.textures()
      registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      let arguments = call.arguments as? NSDictionary
      switch call.method {
      case "loadTexture":
        if let imageStr = arguments?.value(forKey: "url") as? String  {
            let width = (arguments?.value(forKey: "width") as? String ?? "0")
            let height = (arguments?.value(forKey: "height") as? String ?? "0")
            let radius = (arguments?.value(forKey: "radius") as? String ?? "0")
            weak var weakSelf = self;
            var textureId : Int64 = -1;
            let render = FlutterTexturePlugin(imageStr: imageStr, imageSize: CGSize(width: Int(width) ?? 0, height: Int(height) ?? 0), radius: Int32(radius) ?? 0) {
                weakSelf?.textures?.textureFrameAvailable(textureId);
            }
            textureId = weakSelf?.textures?.register(render!) ?? -1
            weakSelf?.renders.setValue(render, forKey: "\(textureId)")
            let dictionary = NSMutableDictionary()
            dictionary.setValue("\(textureId)", forKey: "textureId")
            result(dictionary)
            return
            }
          break;
      case "dispose":
          if let textureId = arguments?.value(forKey: "textureId") as? String, let render = renders.value(forKey: textureId) as? FlutterTexturePlugin {
              renders.removeObject(forKey: textureId)
              render.dispose()
              self.textures?.unregisterTexture(Int64(textureId) ?? -1)
              result(true)
              return
          }
      default:
          result(FlutterMethodNotImplemented)
          break;
      }
      result(FlutterError(code: "1", message: "参数错误", details: nil))
    }
}

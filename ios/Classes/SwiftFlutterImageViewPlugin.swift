import Flutter
import UIKit
import SDWebImage

public class SwiftFlutterImageViewPlugin: NSObject, FlutterPlugin {
    var textures : FlutterTextureRegistry?
    var renders = NSMutableDictionary()
    var channel : FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: "flutter_image_view", binaryMessenger: registrar.messenger())
      let factory = PlatformImageViewFactory()
      SDImageCache.shared.config.shouldCacheImagesInMemory = false
      registrar.register(factory, withId: "native_image_view")
      
      let instance = SwiftFlutterImageViewPlugin()
        instance.channel = channel
      instance.textures = registrar.textures()
      registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      let arguments = call.arguments as? NSDictionary
      switch call.method {
      case "loadTexture":
        if let imageStr = arguments?.value(forKey: "url") as? String  {
            let width = max(1, min(Int(arguments?.value(forKey: "width") as? String ?? "50") ?? 50, 250))
            let height = max(1, min(Int(arguments?.value(forKey: "height") as? String ?? "50") ?? 50, 250))
            let radius = Int32(arguments?.value(forKey: "radius") as? String ?? "0") ?? 0
            let requestId = (arguments?.value(forKey: "requestId") as? String ?? "")
            weak var weakSelf = self;
            var textureId : Int64 = -1;
            
            let render = FlutterTexturePlugin(imageStr: imageStr, imageSize: CGSize(width: width, height: height), radius: radius, requestId: requestId) { (type, param) in
                switch (type) {
                case UPDATETEXTURE:
                    weakSelf?.textures?.textureFrameAvailable(textureId);
                    break;
                case ONPROGRESS:
                    weakSelf?.channel?.invokeMethod("onProgress", arguments: param)
                    break;
                case ONERROR:
                    weakSelf?.channel?.invokeMethod("onError", arguments: param)
                    break;
                case ONDONE:
                    weakSelf?.channel?.invokeMethod("onDone", arguments: param)
                    break
                default:
                    break;
                }
            }
            textureId = weakSelf?.textures?.register(render!) ?? -1
            weakSelf?.renders.setValue(render, forKey: "\(textureId)")
            let dictionary = NSMutableDictionary()
            dictionary.setValue("\(textureId)", forKey: "textureId")
            dictionary.setValue("\(requestId)", forKey: "requestId")
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
      case "cleanCache":
        SDImageCache.shared.clearDisk(onCompletion: nil)
        result(true)
        return
      case "cachedPath":
        result(SDImageCache.shared.diskCachePath)
        return
      default:
          result(FlutterMethodNotImplemented)
          break;
      }
      result(FlutterError(code: "1", message: "参数错误", details: nil))
    }
}

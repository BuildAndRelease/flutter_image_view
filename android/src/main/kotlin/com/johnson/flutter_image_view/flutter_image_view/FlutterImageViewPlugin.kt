package com.johnson.flutter_image_view.flutter_image_view

import android.content.Context
import androidx.annotation.NonNull
import com.taoweiji.flutter.flutter_platform_view.AndroidImageViewFactory

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.view.TextureRegistry

/** FlutterImageViewPlugin */
class FlutterImageViewPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var texture : TextureRegistry
  private lateinit var context : Context
  private var renders = mutableMapOf<String, AndroidTextureView>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    flutterPluginBinding.platformViewRegistry.registerViewFactory("native_image_view", AndroidImageViewFactory())
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_image_view")
    channel.setMethodCallHandler(this)

    texture = flutterPluginBinding.textureRegistry
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "loadTexture") {
      val imageUrl = call.argument<String>("url") ?: ""
      val width = call.argument<String>("width") ?: ""
      val heigth = call.argument<String>("height") ?: ""
      val radius = call.argument<String>("radius") ?: ""
      val errorHolder = call.argument<String>("error") ?: ""
      val placeHolder = call.argument<String>("place") ?: ""
      val entry = texture.createSurfaceTexture()
      val render = AndroidTextureView(imageUrl, placeHolder, errorHolder, width, heigth, radius, context, entry)
      renders[entry.id().toString()] = render
      result.success(mapOf("textureId" to entry.id().toString()));
    } else if (call.method == "dispose") {
      val textureId = call.argument<String>("textureId") ?: ""
      val render = renders.remove(textureId)
      render?.dispose()
      result.success(true)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
